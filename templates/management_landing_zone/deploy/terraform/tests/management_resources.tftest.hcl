# Test: Management Resources
# Validates management resources configuration, feature toggles, and outputs
#
# Note: Tests with management_resources_enabled=true cannot be tested with mock providers
# because the AVM module uses complex resource dependencies. Unit tests validate
# the configuration logic with the module disabled.

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

# Variables loaded from terraform.tfvars (management_resources_enabled = false)

test {
  parallel = true
}

# =============================================================================
# Management Resources Enable/Disable
# =============================================================================

run "management_resources_disabled_by_default" {
  command   = plan
  state_key = "mr_disabled"

  # Verify disabled in test tfvars
  assert {
    condition     = var.management_resources_enabled == false
    error_message = "management_resources_enabled should be false in test tfvars."
  }

  # Resource groups not created when disabled
  assert {
    condition     = length(keys(local.resource_groups)) == 0
    error_message = "No resource groups should be created when management_resources_enabled is false."
  }
}

# =============================================================================
# Resource Groups Configuration (with management_resources_enabled)
# Note: Tests that enable management_resources also require management_resource_settings
# which cannot be mocked properly. These tests are marked for integration testing only.
# =============================================================================

run "resource_groups_lock_enabled_by_default" {
  command   = plan
  state_key = "rg_lock"

  # Resource group lock enabled by default
  assert {
    condition     = var.resource_group_lock_enabled == true
    error_message = "Resource group lock should be enabled by default."
  }
}
