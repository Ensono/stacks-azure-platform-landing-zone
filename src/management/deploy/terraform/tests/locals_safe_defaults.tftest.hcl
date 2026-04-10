# Test: Safe Defaults
# Validates locals compute safely when features are disabled, and resource groups toggle correctly.

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

mock_provider "alz" {}

# Override AVM modules that depend on azure/modtm provider
override_module {
  target = module.azure_regions
  outputs = {
    regions_by_name = {
      uksouth = {
        name         = "uksouth"
        display_name = "UK South"
        geo_code     = "uks"
      }
    }
    regions                             = {}
    regions_by_display_name             = {}
    regions_by_geography                = {}
    regions_by_geography_group          = {}
    regions_by_name_or_display_name     = {}
    valid_region_display_names          = []
    valid_region_names                  = ["uksouth"]
    valid_region_names_or_display_names = []
  }
}

override_module {
  target = module.resource_groups
}

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

  variables {
    management_groups_enabled    = false
    management_resources_enabled = false
  }

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
