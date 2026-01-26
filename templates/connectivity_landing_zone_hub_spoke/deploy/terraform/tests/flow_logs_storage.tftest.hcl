# Test: Flow Logs Storage
# Validates flow logs storage account creation, naming, and configuration
#
# Key behaviors tested:
# - Storage not created when flow_logs disabled (default)
# - Storage created per hub region when flow_logs.storage.create = true
# - External storage account ID used when provided
# - Naming follows CAF conventions
# - Storage configuration options propagate correctly

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
          { name = "ukwest", displayName = "UK West", metadata = { regionType = "Physical", regionCategory = "Other", geography = "United Kingdom", geographyGroup = "Europe", physicalLocation = "Cardiff", pairedRegion = [{ name = "uksouth" }] } },
          { name = "eastus", displayName = "East US", metadata = { regionType = "Physical", regionCategory = "Recommended", geography = "United States", geographyGroup = "US", physicalLocation = "Virginia", pairedRegion = [{ name = "westus" }] } }
        ]
      }
    }
  }
}

mock_provider "random" {}

mock_provider "local" {}

mock_provider "modtm" {}

# Variables loaded from terraform.tfvars

test {
  parallel = true
}

# =============================================================================
# Default State - No Storage Created
# Flow logs disabled by default, so no storage should be created
# =============================================================================

run "flow_logs_disabled_by_default" {
  command   = plan
  state_key = "defaults"

  # Flow logs disabled by default
  assert {
    condition     = var.flow_logs.enabled == false
    error_message = "Flow logs should be disabled by default."
  }

  # Storage module should not be instantiated
  assert {
    condition     = length(local.flow_logs_storage_account_ids) == 0
    error_message = "No storage account IDs should exist when flow logs disabled."
  }
}

# =============================================================================
# Storage Created Per Region
# When flow_logs enabled with storage.create = true
# =============================================================================

run "flow_logs_storage_created_single_region" {
  command   = plan
  state_key = "single_region"

  variables {
    hubs = {
      uksouth = { enabled = true }
    }
    flow_logs = {
      enabled = true
      storage = {
        create = true
      }
    }
  }

  # Storage account ID should exist for uksouth
  assert {
    condition     = contains(keys(local.flow_logs_storage_account_ids), "uksouth")
    error_message = "Storage account ID should exist for uksouth when flow logs enabled."
  }

  # Only one storage account (one region)
  assert {
    condition     = length(local.flow_logs_storage_account_ids) == 1
    error_message = "Should have exactly one storage account for single region."
  }
}

run "flow_logs_storage_created_multi_region" {
  command   = plan
  state_key = "multi_region"

  variables {
    hubs = {
      uksouth = { enabled = true }
      ukwest  = { enabled = true }
      eastus  = { enabled = true }
    }
    flow_logs = {
      enabled = true
      storage = {
        create = true
      }
    }
  }

  # Storage account IDs should exist for all enabled regions
  assert {
    condition     = contains(keys(local.flow_logs_storage_account_ids), "uksouth") && contains(keys(local.flow_logs_storage_account_ids), "ukwest") && contains(keys(local.flow_logs_storage_account_ids), "eastus")
    error_message = "Storage account IDs should exist for all enabled hub regions."
  }

  # Three storage accounts (three regions)
  assert {
    condition     = length(local.flow_logs_storage_account_ids) == 3
    error_message = "Should have exactly three storage accounts for three regions."
  }
}

run "flow_logs_storage_only_enabled_hubs" {
  command   = plan
  state_key = "partial_hubs"

  variables {
    hubs = {
      uksouth = { enabled = true }
      ukwest  = { enabled = false }
    }
    flow_logs = {
      enabled = true
      storage = {
        create = true
      }
    }
  }

  # Only enabled hub should have storage
  assert {
    condition     = contains(keys(local.flow_logs_storage_account_ids), "uksouth") && !contains(keys(local.flow_logs_storage_account_ids), "ukwest")
    error_message = "Storage should only be created for enabled hubs."
  }

  assert {
    condition     = length(local.flow_logs_storage_account_ids) == 1
    error_message = "Should have exactly one storage account for one enabled hub."
  }
}

# =============================================================================
# External Storage Account
# When external_storage_account_id is provided instead of creating
# =============================================================================

run "flow_logs_external_storage" {
  command   = plan
  state_key = "external"

  variables {
    hubs = {
      uksouth = { enabled = true }
    }
    flow_logs = {
      enabled = true
      storage = {
        create                      = false
        external_storage_account_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-storage/providers/Microsoft.Storage/storageAccounts/existingstorage"
      }
    }
  }

  # External storage ID should be used
  assert {
    condition     = local.flow_logs_storage_account_ids["uksouth"] == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-storage/providers/Microsoft.Storage/storageAccounts/existingstorage"
    error_message = "External storage account ID should be used when provided."
  }
}

# =============================================================================
# Naming Conventions
# Storage accounts should follow CAF naming
# =============================================================================

run "flow_logs_storage_naming" {
  command   = plan
  state_key = "naming"

  variables {
    company_name = "ens"
    hubs = {
      uksouth = { enabled = true }
    }
    flow_logs = {
      enabled = true
      storage = {
        create = true
      }
    }
  }

  # Storage name should follow pattern: st{company}{workload}{env}{region}{instance}
  # Pattern: stensflowlogsproduksnnn (no hyphens, 3-24 chars)
  assert {
    condition     = can(regex("^st", local.hub_names["uksouth"].flow_logs_storage))
    error_message = "Storage account name should start with 'st' per CAF naming."
  }

  # Name should not contain hyphens (Azure storage account requirement)
  assert {
    condition     = !can(regex("-", local.hub_names["uksouth"].flow_logs_storage))
    error_message = "Storage account name should not contain hyphens."
  }

  # Name should be 24 characters or less
  assert {
    condition     = length(local.hub_names["uksouth"].flow_logs_storage) <= 24
    error_message = "Storage account name should be 24 characters or less."
  }

  # Name should be at least 3 characters
  assert {
    condition     = length(local.hub_names["uksouth"].flow_logs_storage) >= 3
    error_message = "Storage account name should be at least 3 characters."
  }
}

run "flow_logs_storage_naming_multi_region" {
  command   = plan
  state_key = "naming_multi"

  variables {
    company_name = "ens"
    hubs = {
      uksouth = { enabled = true }
      ukwest  = { enabled = true }
    }
    flow_logs = {
      enabled = true
      storage = {
        create = true
      }
    }
  }

  # Each region should have unique storage name
  assert {
    condition     = local.hub_names["uksouth"].flow_logs_storage != local.hub_names["ukwest"].flow_logs_storage
    error_message = "Each region should have a unique storage account name."
  }

  # Both should follow naming pattern
  assert {
    condition     = can(regex("^st", local.hub_names["uksouth"].flow_logs_storage)) && can(regex("^st", local.hub_names["ukwest"].flow_logs_storage))
    error_message = "All storage account names should follow CAF naming pattern."
  }
}

# =============================================================================
# Storage Configuration Options
# Test that configuration options propagate correctly
# =============================================================================

run "flow_logs_storage_config_defaults" {
  command   = plan
  state_key = "config_defaults"

  variables {
    hubs = {
      uksouth = { enabled = true }
    }
    flow_logs = {
      enabled = true
      storage = {
        create = true
      }
    }
  }

  # Default storage tier should be Standard
  assert {
    condition     = var.flow_logs.storage.account_tier == "Standard"
    error_message = "Default storage tier should be Standard."
  }

  # Default replication should be GRS
  assert {
    condition     = var.flow_logs.storage.account_replication == "GRS"
    error_message = "Default storage replication should be GRS."
  }

  # Default retention should be 30 days
  assert {
    condition     = var.flow_logs.storage.retention_days == 30
    error_message = "Default storage retention should be 30 days."
  }

  # Public network access should be disabled by default
  assert {
    condition     = var.flow_logs.storage.public_network_access == false
    error_message = "Public network access should be disabled by default."
  }
}

run "flow_logs_storage_config_custom" {
  command   = plan
  state_key = "config_custom"

  variables {
    hubs = {
      uksouth = { enabled = true }
    }
    flow_logs = {
      enabled = true
      storage = {
        create              = true
        account_tier        = "Premium"
        account_replication = "LRS"
        retention_days      = 90
        public_network_access = true
      }
    }
  }

  # Custom values should be used
  assert {
    condition     = var.flow_logs.storage.account_tier == "Premium"
    error_message = "Custom storage tier should be Premium."
  }

  assert {
    condition     = var.flow_logs.storage.account_replication == "LRS"
    error_message = "Custom storage replication should be LRS."
  }

  assert {
    condition     = var.flow_logs.storage.retention_days == 90
    error_message = "Custom retention should be 90 days."
  }

  assert {
    condition     = var.flow_logs.storage.public_network_access == true
    error_message = "Custom public network access should be true."
  }
}

# =============================================================================
# Flow Logs Enabled State
# Validates flow_logs_enabled local depends on storage configuration
# =============================================================================

run "flow_logs_enabled_with_create" {
  command   = plan
  state_key = "enabled_create"

  variables {
    hubs = {
      uksouth = { enabled = true }
    }
    flow_logs = {
      enabled = true
      storage = {
        create = true
      }
    }
  }

  # flow_logs_enabled should be true
  assert {
    condition     = local.flow_logs_enabled == true
    error_message = "flow_logs_enabled should be true when storage.create is true."
  }
}

run "flow_logs_enabled_with_external" {
  command   = plan
  state_key = "enabled_external"

  variables {
    hubs = {
      uksouth = { enabled = true }
    }
    flow_logs = {
      enabled = true
      storage = {
        create                      = false
        external_storage_account_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-storage/providers/Microsoft.Storage/storageAccounts/existingstorage"
      }
    }
  }

  # flow_logs_enabled should be true with external storage
  assert {
    condition     = local.flow_logs_enabled == true
    error_message = "flow_logs_enabled should be true when external storage ID provided."
  }
}

run "flow_logs_disabled_no_storage" {
  command   = plan
  state_key = "disabled_no_storage"

  variables {
    hubs = {
      uksouth = { enabled = true }
    }
    flow_logs = {
      enabled = true
      storage = {
        create                      = false
        external_storage_account_id = null
      }
    }
  }

  # flow_logs_enabled should be false without storage
  assert {
    condition     = local.flow_logs_enabled == false
    error_message = "flow_logs_enabled should be false when no storage configured."
  }
}

# =============================================================================
# Integration with Network Watcher
# Storage account IDs should be available for VNet flow logs
# =============================================================================

run "flow_logs_storage_for_network_watcher" {
  command   = plan
  state_key = "network_watcher"

  variables {
    hubs = {
      uksouth = { enabled = true }
      ukwest  = { enabled = true }
    }
    flow_logs = {
      enabled        = true
      retention_days = 7
      storage = {
        create = true
      }
      traffic_analytics_enabled = false
    }
  }

  # Storage IDs should be available for each hub region
  assert {
    condition     = length(local.flow_logs_storage_account_ids) == length(local.enabled_hubs)
    error_message = "Storage account IDs should match number of enabled hubs."
  }

  # Each region's flow log should use its regional storage
  assert {
    condition     = alltrue([for region in keys(local.enabled_hubs) : contains(keys(local.flow_logs_storage_account_ids), region)])
    error_message = "Each enabled hub region should have a corresponding storage account ID."
  }
}
