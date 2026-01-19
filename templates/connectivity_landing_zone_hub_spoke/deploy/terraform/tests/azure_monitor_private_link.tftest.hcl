# Test: Azure Monitor Private Link Scope (AMPLS) Configuration
# Validates AMPLS default behavior and configuration options

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

variables {
  company_name                 = "ens"
  connectivity_subscription_id = "00000000-0000-0000-0000-000000000000"
  hub_network_address_prefix   = "10.0.0.0/8"
  ensono_tags                  = { enabled = false }

  # Provide a valid workspace ID for AMPLS tests since it's enabled by default
  azure_monitor_private_link = {
    log_analytics_workspace_id = "/subscriptions/12345678-1234-1234-1234-123456789012/resourceGroups/rg-management/providers/Microsoft.OperationalInsights/workspaces/log-platform"
  }

  hubs = {
    uksouth = {
      enabled = true
    }
  }
}

run "ampls_enabled_by_default" {
  command = plan

  assert {
    condition     = var.azure_monitor_private_link.enabled == true
    error_message = "AMPLS should be enabled by default."
  }
}

run "ampls_dns_zones_configured_when_enabled" {
  command = plan

  assert {
    condition     = length(local.ampls_required_dns_zones) == 5
    error_message = "AMPLS should have 5 required DNS zones configured."
  }

  assert {
    condition     = contains(local.ampls_required_dns_zones, "privatelink.monitor.azure.com")
    error_message = "AMPLS DNS zones should include privatelink.monitor.azure.com."
  }

  assert {
    condition     = contains(local.ampls_required_dns_zones, "privatelink.oms.opinsights.azure.com")
    error_message = "AMPLS DNS zones should include privatelink.oms.opinsights.azure.com."
  }

  assert {
    condition     = contains(local.ampls_required_dns_zones, "privatelink.ods.opinsights.azure.com")
    error_message = "AMPLS DNS zones should include privatelink.ods.opinsights.azure.com."
  }
}

run "ampls_can_be_disabled" {
  command = plan

  variables {
    azure_monitor_private_link = {
      enabled = false
    }
  }

  assert {
    condition     = var.azure_monitor_private_link.enabled == false
    error_message = "AMPLS should be disabled when explicitly set to false."
  }

  assert {
    condition     = length(local.ampls_dns_zone_ids) == 0
    error_message = "AMPLS DNS zone IDs should be empty when disabled."
  }
}

run "ampls_access_modes_default_to_private_only" {
  command = plan

  assert {
    condition     = var.azure_monitor_private_link.ingestion_access_mode == "PrivateOnly"
    error_message = "AMPLS ingestion access mode should default to PrivateOnly."
  }

  assert {
    condition     = var.azure_monitor_private_link.query_access_mode == "PrivateOnly"
    error_message = "AMPLS query access mode should default to PrivateOnly."
  }
}

run "ampls_accepts_custom_workspace_id" {
  command = plan

  variables {
    azure_monitor_private_link = {
      log_analytics_workspace_id = "/subscriptions/12345678-1234-1234-1234-123456789012/resourceGroups/rg-management/providers/Microsoft.OperationalInsights/workspaces/log-platform"
    }
  }

  assert {
    condition     = var.azure_monitor_private_link.log_analytics_workspace_id == "/subscriptions/12345678-1234-1234-1234-123456789012/resourceGroups/rg-management/providers/Microsoft.OperationalInsights/workspaces/log-platform"
    error_message = "AMPLS should accept custom workspace ID."
  }
}
