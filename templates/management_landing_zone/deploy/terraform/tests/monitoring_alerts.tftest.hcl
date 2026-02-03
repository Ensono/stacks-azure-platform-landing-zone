# Test: Monitoring Alerts
# Validates monitoring alert configuration and defaults

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

mock_provider "modtm" {}

mock_provider "time" {}

mock_provider "alz" {}

# Variables loaded from terraform.tfvars

test {
  parallel = true
}

# =============================================================================
# Computed Logic - Auto-Enable Behavior
# =============================================================================

run "monitoring_alerts_auto_enabled_with_action_group" {
  command   = plan
  state_key = "alerts_auto_enabled"

  variables {
    monitoring_alerts = {
      action_group_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Insights/actionGroups/test-ag"
    }
  }

  assert {
    condition     = local.monitoring_alerts_enabled == true
    error_message = "Monitoring alerts should auto-enable when action_group_id is provided."
  }
}

run "monitoring_alerts_disabled_without_action_group" {
  command   = plan
  state_key = "alerts_disabled"

  assert {
    condition     = local.monitoring_alerts_enabled == false
    error_message = "Monitoring alerts should be disabled when no action_group_id is provided."
  }
}
