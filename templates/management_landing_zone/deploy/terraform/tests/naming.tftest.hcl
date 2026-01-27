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

mock_provider "modtm" {}

mock_provider "time" {}

mock_provider "alz" {}

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
# Module Integration - Azure Regions
# =============================================================================

run "azure_regions_module_provides_geo_codes" {
  command   = plan
  state_key = "location"

  # Location short code derived correctly from azure_regions module
  assert {
    condition     = module.azure_regions.regions_by_name[var.location].geo_code == "uks"
    error_message = "Location short code for uksouth should be 'uks'."
  }
}
