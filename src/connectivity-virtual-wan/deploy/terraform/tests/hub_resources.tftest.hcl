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

  # Firewall enabled by default
  assert {
    condition     = local.virtual_hubs["uksouth"].enabled_resources.firewall == true
    error_message = "Firewall should be enabled by default."
  }

  # Gateways disabled by default
  assert {
    condition     = local.virtual_hubs["uksouth"].enabled_resources.virtual_network_gateway_vpn == false
    error_message = "VPN gateway should be disabled by default."
  }

  assert {
    condition     = local.virtual_hubs["uksouth"].enabled_resources.virtual_network_gateway_express_route == false
    error_message = "ExpressRoute gateway should be disabled by default."
  }

  # Private DNS zones enabled by default
  assert {
    condition     = local.virtual_hubs["uksouth"].enabled_resources.private_dns_zones == true
    error_message = "Private DNS zones should be enabled by default."
  }

  # DDoS disabled by default
  assert {
    condition     = var.ddos_protection_plan.enabled == false
    error_message = "DDoS should be disabled by default."
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

  # DNS Proxy enabled by default
  assert {
    condition     = local.virtual_hubs["uksouth"].firewall_policy.dns.proxy_enabled == true
    error_message = "DNS Proxy should be enabled by default."
  }

  # Threat intelligence mode defaults to Alert
  assert {
    condition     = local.virtual_hubs["uksouth"].firewall_policy.threat_intelligence_mode == "Alert"
    error_message = "Threat intelligence mode should default to Alert."
  }

  # Availability zones auto-detected
  assert {
    condition     = local.hub_availability_zones["uksouth"] != null
    error_message = "Availability zones should be auto-detected for uksouth."
  }
}

# =============================================================================
# Feature Flags
# =============================================================================

run "enabled_hubs_filtering" {
  command   = plan
  state_key = "filtering"

  variables {
    hubs = {
      uksouth = { enabled = true }
      ukwest  = { enabled = false }
    }
  }

  assert {
    condition     = contains(keys(local.enabled_hubs), "uksouth") && !contains(keys(local.enabled_hubs), "ukwest")
    error_message = "Only enabled hubs should appear in enabled_hubs map."
  }
}

run "feature_toggles_propagate" {
  command   = plan
  state_key = "toggles"

  variables {
    hubs = {
      uksouth = {
        enabled = true
        features = {
          firewall = true
          bastion  = false
          # VPN/ExpressRoute disabled to avoid mock data issues in upstream module
          vpn_gateway          = false
          expressroute_gateway = false
          private_dns_resolver = true
        }
      }
    }
  }

  # All feature flags propagate to hub config
  assert {
    condition     = local.virtual_hubs["uksouth"].enabled_resources.firewall == true
    error_message = "Firewall feature should propagate."
  }

  assert {
    condition     = local.virtual_hubs["uksouth"].enabled_resources.bastion == false
    error_message = "Bastion feature should propagate."
  }

  assert {
    condition     = local.virtual_hubs["uksouth"].enabled_resources.virtual_network_gateway_vpn == false
    error_message = "VPN gateway feature should propagate."
  }

  assert {
    condition     = local.virtual_hubs["uksouth"].enabled_resources.virtual_network_gateway_express_route == false
    error_message = "ExpressRoute gateway feature should propagate."
  }

  assert {
    condition     = local.virtual_hubs["uksouth"].enabled_resources.private_dns_resolver == true
    error_message = "Private DNS resolver feature should propagate."
  }
}

# =============================================================================
# Firewall Configuration
# =============================================================================

run "firewall_sku_propagates" {
  command   = plan
  state_key = "fw_sku"

  variables {
    hubs = {
      uksouth = {
        enabled = true
        features = {
          firewall     = true
          firewall_sku = "Premium"
        }
      }
    }
  }

  assert {
    condition     = local.virtual_hubs["uksouth"].firewall.sku_tier == "Premium"
    error_message = "Firewall SKU should propagate to hub config."
  }

  assert {
    condition     = local.virtual_hubs["uksouth"].firewall_policy.sku == "Premium"
    error_message = "Firewall policy SKU should match firewall SKU."
  }
}

# =============================================================================
# Resource Groups
# =============================================================================

run "resource_groups_created" {
  command   = plan
  state_key = "rgs"

  # Hub resource group exists
  assert {
    condition     = contains(keys(local.all_resource_groups), "hub-uksouth")
    error_message = "Hub resource group should exist."
  }

  # VWAN resource group exists
  assert {
    condition     = contains(keys(local.all_resource_groups), "vwan")
    error_message = "VWAN resource group should exist."
  }
}

# =============================================================================
# Naming
# =============================================================================

run "naming_conventions" {
  command   = plan
  state_key = "naming"

  # Virtual WAN name follows pattern
  assert {
    condition     = can(regex("^vwan-", local.virtual_wan_name))
    error_message = "Virtual WAN name should start with 'vwan-'."
  }

  # Virtual Hub name follows pattern
  assert {
    condition     = can(regex("^vhub-", local.hub_names["uksouth"].virtual_hub))
    error_message = "Virtual Hub name should start with 'vhub-'."
  }

  # Firewall name follows pattern
  assert {
    condition     = can(regex("^afw-", local.hub_names["uksouth"].firewall))
    error_message = "Firewall name should start with 'afw-'."
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
    condition     = local.virtual_wan_settings.enabled_resources.ddos_protection_plan == true
    error_message = "DDoS should be enabled in virtual WAN settings."
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
