# Health monitoring alerts for management resources

locals {
  # Auto-enable alerts when action_group_id is provided, unless explicitly disabled
  monitoring_alerts_enabled = coalesce(var.monitoring_alerts.enabled, var.monitoring_alerts.action_group_id != null)
}

# Log Analytics ingestion latency alert
resource "azurerm_monitor_metric_alert" "law_ingestion_latency" {
  count = var.management_resources_enabled && local.monitoring_alerts_enabled ? 1 : 0

  name                = "law-ingestion-latency-${terraform.workspace}"
  resource_group_name = coalesce(var.management_resource_settings.resource_group_name, local.resource_names.resource_group)
  scopes              = [module.management_resources[0].log_analytics_workspace.id]
  description         = "Alert when Log Analytics ingestion latency exceeds ${var.monitoring_alerts.ingestion_latency_threshold_seconds} seconds, indicating potential data pipeline issues."
  severity            = 2
  frequency           = "PT5M"
  window_size         = "PT15M"
  enabled             = true
  tags                = var.tags

  criteria {
    metric_namespace = "Microsoft.OperationalInsights/workspaces"
    metric_name      = "IngestionLatencyInSeconds"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = var.monitoring_alerts.ingestion_latency_threshold_seconds
  }

  dynamic "action" {
    for_each = var.monitoring_alerts.action_group_id != null ? [1] : []
    content {
      action_group_id = var.monitoring_alerts.action_group_id
    }
  }
}

# Log Analytics query failure alert
resource "azurerm_monitor_scheduled_query_rules_alert_v2" "law_query_failures" {
  count = var.management_resources_enabled && local.monitoring_alerts_enabled && var.monitoring_alerts.enable_query_failure_alerts ? 1 : 0

  name                = "law-query-failures-${terraform.workspace}"
  resource_group_name = coalesce(var.management_resource_settings.resource_group_name, local.resource_names.resource_group)
  location            = var.location
  scopes              = [module.management_resources[0].log_analytics_workspace.id]
  description         = "Alert when Log Analytics queries fail, indicating potential workspace issues or query problems."
  severity            = 2
  enabled             = true
  tags                = var.tags

  evaluation_frequency = "PT10M"
  window_duration      = "PT30M"

  criteria {
    query = <<-QUERY
      LAQueryLogs
      | where ResponseCode != 200
      | summarize FailureCount = count() by bin(TimeGenerated, 10m)
      | where FailureCount > ${var.monitoring_alerts.query_failure_threshold}
    QUERY

    time_aggregation_method = "Count"
    threshold               = 0
    operator                = "GreaterThan"

    failing_periods {
      minimum_failing_periods_to_trigger_alert = 1
      number_of_evaluation_periods             = 1
    }
  }

  dynamic "action" {
    for_each = var.monitoring_alerts.action_group_id != null ? [1] : []
    content {
      action_groups = [var.monitoring_alerts.action_group_id]
    }
  }
}

# Storage account availability alert
resource "azurerm_monitor_metric_alert" "storage_availability" {
  count = var.management_resources_enabled && var.flow_logs_storage.enabled && local.monitoring_alerts_enabled ? 1 : 0

  name                = "storage-availability-${terraform.workspace}"
  resource_group_name = coalesce(var.management_resource_settings.resource_group_name, local.resource_names.resource_group)
  scopes              = [module.flow_logs_storage[0].resource_id]
  description         = "Alert when flow logs storage account availability drops below ${var.monitoring_alerts.storage_availability_threshold}%."
  severity            = 1
  frequency           = "PT5M"
  window_size         = "PT15M"
  enabled             = true
  tags                = var.tags

  criteria {
    metric_namespace = "Microsoft.Storage/storageAccounts"
    metric_name      = "Availability"
    aggregation      = "Average"
    operator         = "LessThan"
    threshold        = var.monitoring_alerts.storage_availability_threshold
  }

  dynamic "action" {
    for_each = var.monitoring_alerts.action_group_id != null ? [1] : []
    content {
      action_group_id = var.monitoring_alerts.action_group_id
    }
  }
}
