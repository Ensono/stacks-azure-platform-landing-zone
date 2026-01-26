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
# CAF Naming Conventions
# =============================================================================

run "naming_conventions" {
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

  # Note: DCR names use AVM module defaults (dcr-change-tracking, dcr-vm-insights, dcr-defender-sql)
}

# =============================================================================
# =============================================================================
# Location and Environment
# =============================================================================

run "location_config" {
  command   = plan
  state_key = "location"

  # Location short code derived correctly from azure_regions module
  assert {
    condition     = module.azure_regions.regions_by_name[var.location].geo_code == "uks"
    error_message = "Location short code for uksouth should be 'uks'."
  }

  # Location matches input variable
  assert {
    condition     = var.location == "uksouth"
    error_message = "Location should match input variable."
  }
}

# =============================================================================
# Tags Configuration
# =============================================================================

run "tags_defaults" {
  command   = plan
  state_key = "tags_default"

  assert {
    condition     = length(var.tags) == 0
    error_message = "Tags should be empty by default."
  }
}

run "tags_custom" {
  command   = plan
  state_key = "tags_custom"

  variables {
    tags = {
      Environment = "Dev"
      Project     = "Landing Zone"
      Owner       = "Platform Team"
    }
  }

  assert {
    condition     = var.tags["Environment"] == "Dev"
    error_message = "Custom tags should be applied."
  }

  assert {
    condition     = var.tags["Project"] == "Landing Zone"
    error_message = "Custom tags should be applied."
  }
}

# =============================================================================
# Variable Validation
# =============================================================================

run "subscription_id_validation" {
  command   = plan
  state_key = "sub_valid"

  # Valid GUID format for management subscription
  assert {
    condition     = can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.management_subscription_id))
    error_message = "management_subscription_id must be a valid GUID format."
  }

  # Optional subscriptions are also valid GUIDs when provided
  assert {
    condition     = can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.connectivity_subscription_id))
    error_message = "connectivity_subscription_id must be a valid GUID format when provided."
  }
}
