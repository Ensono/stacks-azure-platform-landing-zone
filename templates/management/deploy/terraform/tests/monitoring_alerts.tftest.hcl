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

# =============================================================================
# Computed Logic - GB to Bytes Conversion
# =============================================================================

run "ingest_threshold_gb_to_bytes_conversion" {
  command   = plan
  state_key = "gb_bytes"

  variables {
    monitoring_alerts = {
      action_group_id          = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Insights/actionGroups/test-ag"
      data_ingest_threshold_gb = 100
    }
  }

  # 100 GB = 100 * 1024^3 = 107374182400 bytes
  assert {
    condition     = local.monitoring_alerts_ingest_threshold_bytes == 107374182400
    error_message = "100 GB should convert to 107374182400 bytes."
  }
}

run "monitoring_alerts_explicit_disable_overrides_action_group" {
  command   = plan
  state_key = "explicit_disable"

  variables {
    monitoring_alerts = {
      enabled         = false
      action_group_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Insights/actionGroups/test-ag"
    }
  }

  assert {
    condition     = local.monitoring_alerts_enabled == false
    error_message = "Explicitly setting enabled=false should override auto-enable from action_group_id."
  }
}
