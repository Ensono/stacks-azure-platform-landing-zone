# Test: Hub Resources
# Validates hub configuration, feature toggles, computed locals, and conditional resources

mock_provider "azurerm" {
  mock_data "azurerm_client_config" {
    defaults = {
      client_id       = "00000000-0000-0000-0000-000000000000"
      tenant_id       = "00000000-0000-0000-0000-000000000000"
      subscription_id = "00000000-0000-0000-0000-000000000000"
      object_id       = "00000000-0000-0000-0000-000000000000"
    }
  }
}

mock_provider "azapi" {
  mock_data "azapi_resource_action" {
    defaults = {
      output = {
        value = [
          { name = "uksouth", displayName = "UK South", metadata = { regionType = "Physical", regionCategory = "Recommended", geography = "United Kingdom", geographyGroup = "Europe", physicalLocation = "London", pairedRegion = [{ name = "ukwest" }] } },
          { name = "ukwest", displayName = "UK West", metadata = { regionType = "Physical", regionCategory = "Other", geography = "United Kingdom", geographyGroup = "Europe", physicalLocation = "Cardiff", pairedRegion = [{ name = "uksouth" }] } }
        ]
      }
    }
  }
}

mock_provider "random" {}

override_module {
  target = module.azure_regions
  outputs = {
    regions_by_name = {
      uksouth = { geo_code = "uks", name = "uksouth", display_name = "UK South", zones = ["1", "2", "3"] }
      ukwest  = { geo_code = "ukw", name = "ukwest", display_name = "UK West", zones = ["1", "2", "3"] }
    }
  }
}

override_data {
  target = data.terraform_remote_state.management
  values = { outputs = {} }
}

test {
  parallel = true
}

# =============================================================================
# Default Configuration
# =============================================================================

run "hub_defaults" {
  command   = plan
  state_key = "defaults"

  # Gateways disabled, DNS enabled, DDoS disabled
  assert {
    condition     = local.hub_virtual_networks["uksouth"].enabled_resources.virtual_network_gateway_vpn == false
    error_message = "Gateways should be disabled by default."
  }

  assert {
    condition     = local.hub_virtual_networks["uksouth"].enabled_resources.private_dns_zones == true
    error_message = "Private DNS zones should be enabled by default."
  }

  assert {
    condition     = var.ddos_protection_plan.enabled == false
    error_message = "DDoS should be disabled by default."
  }

  # Availability zones auto-detected for uksouth
  assert {
    condition     = local.hub_availability_zones["uksouth"] == tolist(["1", "2", "3"])
    error_message = "Availability zones should be auto-detected for uksouth."
  }

  # No diagnostics without workspace ID
  assert {
    condition     = length(local.firewalls_with_diagnostics) == 0
    error_message = "Firewall diagnostics should be empty without workspace ID."
  }

  # Flow logs disabled by default
  assert {
    condition     = var.flow_logs.enabled == false
    error_message = "Flow logs should be disabled by default."
  }

  # Private Endpoints NSG rules
  assert {
    condition     = module.nsg_private_endpoints["uksouth"].security_rules["allow_vnet_inbound"].priority == 100
    error_message = "AllowVNetInbound rule should have priority 100."
  }

  assert {
    condition     = module.nsg_private_endpoints["uksouth"].security_rules["deny_internet_inbound"].priority == 4096
    error_message = "DenyInternetInbound rule should have priority 4096."
  }
}

# =============================================================================
# Feature Flags
# =============================================================================

run "feature_toggles_propagate" {
  command   = plan
  state_key = "toggles"

  variables {
    hubs = {
      uksouth = {
        enabled = true
        features = {
          firewall             = true
          bastion              = false
          vpn_gateway          = true
          expressroute_gateway = true
          private_dns_resolver = true
        }
      }
      ukwest = { enabled = false }
    }
  }

  # Hub filtering - only enabled hubs appear
  assert {
    condition     = contains(keys(local.enabled_hubs), "uksouth") && !contains(keys(local.enabled_hubs), "ukwest")
    error_message = "Only enabled hubs should appear in enabled_hubs map."
  }

  # All feature flags propagate to hub config
  assert {
    condition     = local.hub_virtual_networks["uksouth"].enabled_resources.firewall == true
    error_message = "Firewall feature should propagate."
  }

  assert {
    condition     = local.hub_virtual_networks["uksouth"].enabled_resources.bastion == false
    error_message = "Bastion feature should propagate."
  }

  assert {
    condition     = local.hub_virtual_networks["uksouth"].enabled_resources.virtual_network_gateway_vpn == true
    error_message = "VPN gateway feature should propagate."
  }

  assert {
    condition     = local.hub_virtual_networks["uksouth"].virtual_network_gateways.vpn != null
    error_message = "VPN gateway config should exist when enabled."
  }

  assert {
    condition     = local.hub_virtual_networks["uksouth"].virtual_network_gateways.express_route != null
    error_message = "ExpressRoute gateway config should exist when enabled."
  }
}

# =============================================================================
# DDoS and AMPLS Resource Groups
# =============================================================================

run "ddos_creates_resource_group" {
  command   = plan
  state_key = "ddos"

  variables {
    ddos_protection_plan = { enabled = true }
  }

  assert {
    condition     = contains(keys(local.ddos_resource_group), "ddos")
    error_message = "DDoS should create dedicated resource group."
  }

  assert {
    condition     = local.hub_and_spoke_settings.enabled_resources.ddos_protection_plan == true
    error_message = "DDoS should be enabled in hub settings."
  }
}

run "ampls_dns_zones_and_diagnostics" {
  command   = plan
  state_key = "ampls"

  variables {
    azure_monitor_private_link = {
      enabled                    = true
      log_analytics_workspace_id = "/subscriptions/12345678-1234-1234-1234-123456789012/resourceGroups/rg-management/providers/Microsoft.OperationalInsights/workspaces/log-platform"
    }
  }

  # AMPLS requires 5 DNS zones
  assert {
    condition     = length(local.ampls_required_dns_zone_keys) == 5
    error_message = "AMPLS should require 5 DNS zones."
  }

  # Firewall diagnostics enabled with workspace ID
  assert {
    condition     = contains(keys(local.firewalls_with_diagnostics), "uksouth")
    error_message = "Firewall diagnostics should be enabled with workspace ID."
  }
}

# =============================================================================
# Flow Logs
# =============================================================================

run "flow_logs_enabled_with_storage" {
  command   = plan
  state_key = "fl_enabled"

  variables {
    flow_logs = {
      enabled = true
      storage = { create = true }
    }
  }

  assert {
    condition     = local.flow_logs_enabled == true
    error_message = "flow_logs_enabled should be true with storage."
  }

  assert {
    condition     = length(local.flow_logs_storage_account_ids) == 1
    error_message = "Storage account ID should exist for enabled hub."
  }
}
