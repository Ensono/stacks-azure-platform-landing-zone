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

mock_provider "modtm" {}

mock_provider "time" {}

mock_provider "alz" {}

# Variables loaded from terraform.tfvars

test {
  parallel = true
}

# =============================================================================
# Monitoring Alerts Defaults
# =============================================================================

run "monitoring_alerts_disabled_by_default" {
  command   = plan
  state_key = "alerts_disabled"

  assert {
    condition     = var.monitoring_alerts.enabled == null
    error_message = "Monitoring alerts enabled should be null by default (auto-computed)."
  }

  assert {
    condition     = var.monitoring_alerts.action_group_id == null
    error_message = "Action group ID should be null by default."
  }

  assert {
    condition     = local.monitoring_alerts_enabled == false
    error_message = "Monitoring alerts should be disabled when no action_group_id is provided."
  }
}

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

run "monitoring_alerts_default_thresholds" {
  command   = plan
  state_key = "alerts_thresholds"

  assert {
    condition     = var.monitoring_alerts.ingestion_latency_threshold_seconds == 120
    error_message = "Ingestion latency threshold should default to 120 seconds."
  }

  assert {
    condition     = var.monitoring_alerts.storage_availability_threshold == 99.9
    error_message = "Storage availability threshold should default to 99.9%."
  }

  assert {
    condition     = var.monitoring_alerts.enable_query_failure_alerts == true
    error_message = "Query failure alerts should be enabled by default."
  }

  assert {
    condition     = var.monitoring_alerts.query_failure_threshold == 5
    error_message = "Query failure threshold should default to 5."
  }
}

# =============================================================================
# Monitoring Alerts Custom Configuration
# =============================================================================

run "monitoring_alerts_custom_thresholds" {
  command   = plan
  state_key = "alerts_custom"

  variables {
    monitoring_alerts = {
      enabled                             = true
      action_group_id                     = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Insights/actionGroups/test-ag"
      ingestion_latency_threshold_seconds = 60
      storage_availability_threshold      = 99.5
      enable_query_failure_alerts         = false
      query_failure_threshold             = 10
    }
  }

  assert {
    condition     = var.monitoring_alerts.enabled == true
    error_message = "Monitoring alerts should be enableable."
  }

  assert {
    condition     = var.monitoring_alerts.ingestion_latency_threshold_seconds == 60
    error_message = "Ingestion latency threshold should be configurable."
  }

  assert {
    condition     = var.monitoring_alerts.storage_availability_threshold == 99.5
    error_message = "Storage availability threshold should be configurable."
  }

  assert {
    condition     = var.monitoring_alerts.enable_query_failure_alerts == false
    error_message = "Query failure alerts should be configurable."
  }

  assert {
    condition     = var.monitoring_alerts.query_failure_threshold == 10
    error_message = "Query failure threshold should be configurable."
  }
}
