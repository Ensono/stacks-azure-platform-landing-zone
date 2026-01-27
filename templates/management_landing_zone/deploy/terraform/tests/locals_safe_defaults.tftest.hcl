# Test: Management Groups
# Validates management groups configuration and validation rules
#
# Note: Tests with management_groups_enabled=true cannot be tested with mock providers
# because the ALZ module uses for_each with values that are only known after apply.
# These tests would require integration testing with a real Azure environment.
# Only default configuration tests (management_groups_enabled=false) are included here.

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
# Locals Safe When Disabled
# These tests ensure consumers don't hit errors when features are disabled
# =============================================================================

run "policy_defaults_computed_safely" {
  command   = plan
  state_key = "policy_defaults"

  # Policy defaults should be computed safely when resources disabled
  assert {
    condition     = local.policy_default_values != null
    error_message = "policy_default_values should not be null even when resources are disabled."
  }

  # Subscription placement should be computed safely
  assert {
    condition     = local.subscription_placement != null
    error_message = "subscription_placement local should not be null."
  }
}
