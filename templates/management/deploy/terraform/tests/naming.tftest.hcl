# Test: Naming and Tags
# Validates CAF naming conventions and tag generation for management resources

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
# Module Integration - CAF Naming Conventions
# =============================================================================

run "naming_module_produces_caf_prefixes" {
  command   = plan
  state_key = "naming"

  # Resource group naming
  assert {
    condition     = startswith(local.resource_names.resource_group, "rg-")
    error_message = "Resource group name should start with 'rg-' CAF prefix."
  }

  assert {
    condition     = can(regex("ens", local.resource_names.resource_group))
    error_message = "Resource group name should contain company prefix."
  }

  # Log Analytics naming
  assert {
    condition     = startswith(local.resource_names.log_analytics_workspace, "log-")
    error_message = "Log Analytics workspace name should start with 'log-' CAF prefix."
  }

  # User assigned identity naming (CAF uses 'uai-' prefix)
  assert {
    condition     = startswith(local.resource_names.user_assigned_identity, "uai-")
    error_message = "User assigned identity name should start with 'uai-' CAF prefix."
  }
}

# =============================================================================
# Module Integration - Azure Regions (override contract)
# =============================================================================

run "azure_regions_provides_geo_codes" {
  command   = plan
  state_key = "location"

  assert {
    condition     = module.azure_regions.regions_by_name["uksouth"].geo_code == "uks"
    error_message = "Overridden regions_by_name should provide geo_code 'uks' for uksouth."
  }
}
