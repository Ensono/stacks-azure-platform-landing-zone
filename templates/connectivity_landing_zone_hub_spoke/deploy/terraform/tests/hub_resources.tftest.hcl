# Test: Hub Resources
# Validates hub configuration, feature toggles, gateways, DNS, DDoS, and AMPLS

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

mock_provider "local" {}

mock_provider "modtm" {}

# Variables loaded from terraform.tfvars

test {
  parallel = true
}

# =============================================================================
# Default Hub Configuration
# Tests default feature states, gateways disabled, DNS enabled, DDoS disabled
# =============================================================================

run "hub_defaults" {
  command   = plan
  state_key = "defaults"

  # Gateways disabled by default
  assert {
    condition     = local.hub_virtual_networks["uksouth"].enabled_resources.virtual_network_gateway_vpn == false && local.hub_virtual_networks["uksouth"].virtual_network_gateways == null
    error_message = "Gateways should be disabled by default."
  }

  # Private DNS zones enabled, resolver disabled by default
  assert {
    condition     = local.hub_virtual_networks["uksouth"].enabled_resources.private_dns_zones == true && local.hub_virtual_networks["uksouth"].enabled_resources.private_dns_resolver == false
    error_message = "Private DNS zones should be enabled and resolver disabled by default."
  }

  # DDoS disabled by default
  assert {
    condition     = var.ddos_protection_plan.enabled == false && !contains(keys(local.ddos_resource_group), "ddos")
    error_message = "DDoS should be disabled by default."
  }

  # Firewall diagnostics empty without workspace ID
  assert {
    condition     = length(local.firewalls_with_diagnostics) == 0
    error_message = "Firewall diagnostics should be empty without workspace ID."
  }
}

# =============================================================================
# Feature Flags Propagation
# =============================================================================

run "feature_flags_propagate" {
  command   = plan
  state_key = "feature_flags"

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

run "feature_toggles" {
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
          private_dns_resolver = true
          availability_zones   = ["1", "2", "3"]
        }
      }
    }
  }

  # Feature flags propagate
  assert {
    condition     = local.hub_virtual_networks["uksouth"].enabled_resources.firewall == true && local.hub_virtual_networks["uksouth"].enabled_resources.bastion == false && local.hub_virtual_networks["uksouth"].enabled_resources.virtual_network_gateway_vpn == true && local.hub_virtual_networks["uksouth"].enabled_resources.private_dns_resolver == true
    error_message = "Feature flags should propagate to hub config."
  }

  # VPN gateway config created
  assert {
    condition     = local.hub_virtual_networks["uksouth"].virtual_network_gateways.vpn != null && can(regex("^vgw-", local.hub_names["uksouth"].vpn_gateway))
    error_message = "VPN gateway config should exist with CAF naming."
  }

  # Explicit availability zones override propagate
  assert {
    condition     = local.hub_virtual_networks["uksouth"].firewall.zones == tolist(["1", "2", "3"])
    error_message = "Explicit availability zones override should propagate to firewall."
  }
}

# =============================================================================
# Availability Zones Auto-Detection
# =============================================================================

run "availability_zones_auto_detect" {
  command   = plan
  state_key = "az_auto"

  # Default config - zones should be auto-detected from region
  # uksouth supports zones [1, 2, 3], ukwest does not (null)
  assert {
    condition     = local.hub_availability_zones["uksouth"] == tolist(["1", "2", "3"])
    error_message = "Availability zones should be auto-detected for uksouth."
  }

  assert {
    condition     = local.hub_virtual_networks["uksouth"].firewall.zones == tolist(["1", "2", "3"])
    error_message = "Firewall should use auto-detected zones for uksouth."
  }
}

run "availability_zones_non_az_region" {
  command   = plan
  state_key = "az_ukwest"

  variables {
    hubs = {
      ukwest = { enabled = true }
    }
  }

  # ukwest doesn't support zones
  assert {
    condition     = local.hub_availability_zones["ukwest"] == null
    error_message = "Availability zones should be null for ukwest (no zone support)."
  }

  assert {
    condition     = local.hub_virtual_networks["ukwest"].firewall.zones == null
    error_message = "Firewall should have null zones for ukwest."
  }
}

# =============================================================================
# DNS Resource Group Conditional
# =============================================================================

run "dns_disabled" {
  command   = plan
  state_key = "dns_off"

  variables {
    hubs = {
      uksouth = {
        enabled = true
        features = {
          private_dns_zones = false
        }
      }
    }
  }

  assert {
    condition     = !contains(keys(local.dns_resource_group), "dns")
    error_message = "DNS resource group should not exist when private DNS zones disabled."
  }
}

# =============================================================================
# DDoS Protection Plan Enabled
# =============================================================================

run "ddos_enabled" {
  command   = plan
  state_key = "ddos"

  variables {
    ddos_protection_plan = { enabled = true }
  }

  assert {
    condition     = contains(keys(local.ddos_resource_group), "ddos") && local.hub_and_spoke_settings.enabled_resources.ddos_protection_plan == true && can(regex("^ddospp-", local.hub_and_spoke_settings.ddos_protection_plan.name))
    error_message = "DDoS should create resource group and config with CAF naming."
  }
}

# =============================================================================
# AMPLS Configuration
# =============================================================================

run "ampls_enabled" {
  command   = plan
  state_key = "ampls"

  variables {
    azure_monitor_private_link = {
      log_analytics_workspace_id = "/subscriptions/12345678-1234-1234-1234-123456789012/resourceGroups/rg-management/providers/Microsoft.OperationalInsights/workspaces/log-platform"
    }
  }

  assert {
    condition     = length(local.ampls_required_dns_zone_keys) == 5 && contains(local.ampls_required_dns_zone_keys, "azure_monitor")
    error_message = "AMPLS should have 5 required DNS zone keys including azure_monitor."
  }

  # Firewall diagnostics enabled with workspace ID
  assert {
    condition     = contains(keys(local.firewalls_with_diagnostics), "uksouth")
    error_message = "Firewall diagnostics should be enabled with workspace ID."
  }
}

# =============================================================================
# Edge Cases: Gateway Combinations
# =============================================================================

run "vpn_and_expressroute_gateways" {
  command   = plan
  state_key = "dual_gw"

  variables {
    hubs = {
      uksouth = {
        features = {
          vpn_gateway          = true
          expressroute_gateway = true
          availability_zones   = ["1", "2", "3"]
        }
      }
    }
  }

  assert {
    condition     = local.hub_virtual_networks["uksouth"].virtual_network_gateways.vpn != null && local.hub_virtual_networks["uksouth"].virtual_network_gateways.express_route != null
    error_message = "Both VPN and ExpressRoute gateways should be configured."
  }

  assert {
    condition     = local.hub_virtual_networks["uksouth"].virtual_network_gateways.subnet_address_prefix != null
    error_message = "Gateway subnet should be configured."
  }
}

# =============================================================================
# Edge Cases: Firewall Without Diagnostics
# =============================================================================

run "firewall_without_log_analytics" {
  command   = plan
  state_key = "fw_no_diag"

  # Default: no log_analytics_workspace_id
  assert {
    condition     = local.hub_virtual_networks["uksouth"].enabled_resources.firewall == true && length(local.firewalls_with_diagnostics) == 0
    error_message = "Firewall should deploy without diagnostics when Log Analytics unavailable."
  }
}

# =============================================================================
# Firewall SKU Configuration
# =============================================================================

run "firewall_sku_default" {
  command   = plan
  state_key = "fw_sku_default"

  assert {
    condition     = local.hub_virtual_networks["uksouth"].firewall.sku_tier == "Standard"
    error_message = "Firewall SKU should default to Standard."
  }
}

run "firewall_sku_basic" {
  command   = plan
  state_key = "fw_sku_basic"

  variables {
    hubs = {
      uksouth = {
        enabled = true
        features = {
          firewall     = true
          firewall_sku = "Basic"
        }
      }
    }
  }

  assert {
    condition     = local.hub_virtual_networks["uksouth"].firewall.sku_tier == "Basic"
    error_message = "Firewall SKU should be Basic when configured."
  }
}

run "firewall_sku_premium" {
  command   = plan
  state_key = "fw_sku_premium"

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
    condition     = local.hub_virtual_networks["uksouth"].firewall.sku_tier == "Premium"
    error_message = "Firewall SKU should be Premium when configured."
  }
}

# =============================================================================
# Network Watcher Configuration
# =============================================================================

run "network_watcher_enabled_by_default" {
  command   = plan
  state_key = "nw_default"

  assert {
    condition     = var.network_watcher.enabled == true
    error_message = "Network Watcher should be enabled by default."
  }

  assert {
    condition     = contains(keys(azurerm_network_watcher.this), "uksouth")
    error_message = "Network Watcher should be created for each enabled hub."
  }
}

run "network_watcher_disabled" {
  command   = plan
  state_key = "nw_disabled"

  variables {
    network_watcher = { enabled = false }
  }

  assert {
    condition     = length(azurerm_network_watcher.this) == 0
    error_message = "Network Watcher should not be created when disabled."
  }
}

# =============================================================================
# Flow Logs Configuration
# =============================================================================

run "flow_logs_disabled_by_default" {
  command   = plan
  state_key = "fl_default"

  assert {
    condition     = var.flow_logs.enabled == false
    error_message = "Flow logs should be disabled by default."
  }

  assert {
    condition     = length(azurerm_network_watcher_flow_log.vnet) == 0
    error_message = "Flow logs should not be created when disabled."
  }
}

run "flow_logs_requires_storage_account" {
  command   = plan
  state_key = "fl_no_storage"

  variables {
    flow_logs = {
      enabled        = true
      retention_days = 90
    }
  }

  # Flow logs require storage_account_id - validation should fail with clear message
  expect_failures = [
    terraform_data.validate_flow_logs_requirements
  ]
}

run "flow_logs_enabled_with_storage" {
  command   = plan
  state_key = "fl_enabled"

  variables {
    flow_logs = {
      enabled            = true
      retention_days     = 90
      storage_account_id = "/subscriptions/12345678-1234-1234-1234-123456789012/resourceGroups/rg-management/providers/Microsoft.Storage/storageAccounts/stflowlogs"
    }
  }

  assert {
    condition     = contains(keys(azurerm_network_watcher_flow_log.vnet), "uksouth")
    error_message = "Flow log should be created when storage account provided."
  }
}

run "flow_logs_requires_network_watcher" {
  command   = plan
  state_key = "fl_requires_nw"

  variables {
    network_watcher = { enabled = false }
    flow_logs = {
      enabled            = true
      storage_account_id = "/subscriptions/12345678-1234-1234-1234-123456789012/resourceGroups/rg-management/providers/Microsoft.Storage/storageAccounts/stflowlogs"
    }
  }

  assert {
    condition     = length(azurerm_network_watcher_flow_log.vnet) == 0
    error_message = "Flow logs should not be created without Network Watcher."
  }
}

run "flow_logs_traffic_analytics_requires_guid" {
  command   = plan
  state_key = "fl_ta_no_guid"

  variables {
    flow_logs = {
      enabled                   = true
      retention_days            = 90
      traffic_analytics_enabled = true
      storage_account_id        = "/subscriptions/12345678-1234-1234-1234-123456789012/resourceGroups/rg-management/providers/Microsoft.Storage/storageAccounts/stflowlogs"
    }
    azure_monitor_private_link = {
      log_analytics_workspace_id = "/subscriptions/12345678-1234-1234-1234-123456789012/resourceGroups/rg-management/providers/Microsoft.OperationalInsights/workspaces/log-platform"
    }
  }

  # Traffic Analytics requires workspace GUID from remote state
  # When only workspace ID is provided directly, traffic_analytics block is skipped
  assert {
    condition     = length(azurerm_network_watcher_flow_log.vnet["uksouth"].traffic_analytics) == 0
    error_message = "Traffic Analytics should not be configured without workspace GUID (requires remote state)."
  }
}

# =============================================================================
# Private Endpoints NSG Tests
# Tests NSG creation, rules, and subnet association
# =============================================================================

run "private_endpoints_nsg_enabled_by_default" {
  command   = plan
  state_key = "nsg_default"

  variables {
    hubs = {
      uksouth = {}
      ukwest  = {}
    }
  }

  assert {
    condition     = length(module.nsg_private_endpoints) == 2
    error_message = "NSG should be created for each hub by default."
  }

  assert {
    condition     = length(azurerm_subnet_network_security_group_association.private_endpoints) == 2
    error_message = "NSG should be associated with private endpoints subnet in each hub."
  }
}

run "private_endpoints_nsg_disabled" {
  command   = plan
  state_key = "nsg_disabled"

  variables {
    private_endpoints_nsg = { enabled = false }
  }

  assert {
    condition     = length(module.nsg_private_endpoints) == 0
    error_message = "NSG should not be created when disabled."
  }

  assert {
    condition     = length(azurerm_subnet_network_security_group_association.private_endpoints) == 0
    error_message = "NSG association should not be created when disabled."
  }
}

run "private_endpoints_nsg_security_rules" {
  command   = plan
  state_key = "nsg_rules"

  assert {
    condition     = module.nsg_private_endpoints["uksouth"].security_rules["allow_vnet_inbound"].priority == 100
    error_message = "AllowVNetInbound rule should have priority 100."
  }

  assert {
    condition     = module.nsg_private_endpoints["uksouth"].security_rules["deny_internet_inbound"].priority == 4096
    error_message = "DenyInternetInbound rule should have priority 4096."
  }
}
