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
# Management Groups Defaults
# =============================================================================

run "management_groups_disabled_by_default" {
  command   = plan
  state_key = "mg_defaults"

  # Management groups disabled by default
  assert {
    condition     = var.management_groups_enabled == false
    error_message = "Management groups should be disabled by default."
  }

  # Settings variable is null when module is disabled (not required)
  assert {
    condition     = var.management_group_settings == null
    error_message = "management_group_settings should be null by default when disabled."
  }
}

# =============================================================================
# Variable Configuration Tests
# These tests verify variable defaults and validation without enabling the module
# =============================================================================

run "management_groups_variable_with_settings" {
  command   = plan
  state_key = "mg_var_settings"

  variables {
    management_group_settings = {
      architecture_name  = "alz_custom"
      location           = "uksouth"
      parent_resource_id = "/providers/Microsoft.Management/managementGroups/test-tenant-root"
    }
  }

  assert {
    condition     = var.management_group_settings.architecture_name == "alz_custom"
    error_message = "Architecture name should be configurable."
  }
}

# =============================================================================
# Policy Defaults Computation
# =============================================================================

run "policy_defaults_computed_safely" {
  command   = plan
  state_key = "policy_defaults"

  # Policy defaults should be computed safely when resources disabled
  assert {
    condition     = local.policy_default_values != null
    error_message = "policy_default_values should not be null even when resources are disabled."
  }
}

# =============================================================================
# Subscription Placement Defaults
# =============================================================================

run "subscription_placement_defaults" {
  command   = plan
  state_key = "sub_placement"

  # Subscription placement should be computed safely
  assert {
    condition     = local.subscription_placement != null
    error_message = "subscription_placement local should not be null."
  }
}
