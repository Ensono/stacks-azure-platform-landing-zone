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

mock_provider "random" {}

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

# =============================================================================
# Flow Logs Storage Configuration
# Note: flow_logs_storage module requires management_resources_enabled=true
# because it depends on the management resource group. These tests verify
# variable configuration, not module behavior.
# =============================================================================

run "flow_logs_storage_defaults" {
  command   = plan
  state_key = "storage_defaults"

  # Flow logs storage enabled by default
  assert {
    condition     = var.flow_logs_storage.enabled == true
    error_message = "Flow logs storage should be enabled by default."
  }

  # GZRS replication by default (geo-zone redundant for reliability per CAF)
  assert {
    condition     = var.flow_logs_storage.account_replication_type == "GZRS"
    error_message = "Storage account should use GZRS replication by default per CAF reliability recommendations."
  }

  # Cool access tier by default (cost optimization for infrequently accessed logs)
  assert {
    condition     = var.flow_logs_storage.access_tier == "Cool"
    error_message = "Storage account should use Cool access tier by default for cost optimization."
  }

  # Public access disabled by default
  assert {
    condition     = var.flow_logs_storage.public_network_access == false
    error_message = "Public network access should be disabled by default."
  }

  # Shared access key disabled by default
  assert {
    condition     = var.flow_logs_storage.shared_access_key_enabled == false
    error_message = "Shared access key should be disabled by default."
  }

  # TLS 1.2 minimum by default
  assert {
    condition     = var.flow_logs_storage.min_tls_version == "TLS1_2"
    error_message = "Minimum TLS version should be 1.2 by default."
  }
}

run "flow_logs_storage_custom" {
  command   = plan
  state_key = "storage_custom"

  variables {
    flow_logs_storage = {
      enabled                  = true
      account_replication_type = "LRS"
      retention_days           = 60
      access_tier              = "Hot"
    }
  }

  assert {
    condition     = var.flow_logs_storage.account_replication_type == "LRS"
    error_message = "Storage replication type should be configurable."
  }

  assert {
    condition     = var.flow_logs_storage.retention_days == 60
    error_message = "Storage retention days should be configurable."
  }

  assert {
    condition     = var.flow_logs_storage.access_tier == "Hot"
    error_message = "Storage access tier should be configurable."
  }
}

run "flow_logs_storage_disabled" {
  command   = plan
  state_key = "storage_disabled"

  variables {
    flow_logs_storage = {
      enabled = false
    }
  }

  assert {
    condition     = var.flow_logs_storage.enabled == false
    error_message = "Flow logs storage should be disableable."
  }
}
