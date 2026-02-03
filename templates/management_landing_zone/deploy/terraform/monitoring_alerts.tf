# Health monitoring alerts for management resources

locals {
  # Auto-enable alerts when action_group_id is provided, unless explicitly disabled
  monitoring_alerts_enabled = coalesce(var.monitoring_alerts.enabled, var.monitoring_alerts.action_group_id != null)

  # Convert data ingestion threshold (GB) to bytes for metric alert comparisons
  monitoring_alerts_ingest_threshold_bytes = coalesce(var.monitoring_alerts.data_ingest_threshold_gb, 0) * pow(1024, 3)
}

# Ensure alerts have an action group target to keep notifications actionable
resource "terraform_data" "monitoring_alerts_require_action_group" {
  count = local.monitoring_alerts_enabled ? 1 : 0

  lifecycle {
    precondition {
      condition     = var.monitoring_alerts.action_group_id != null
      error_message = "monitoring_alerts.action_group_id must be provided when alerts are enabled."
    }
  }
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

  depends_on = [terraform_data.monitoring_alerts_require_action_group]
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

  depends_on = [terraform_data.monitoring_alerts_require_action_group]
}

# Log Analytics searchable results availability alert
resource "azurerm_monitor_metric_alert" "law_search_availability" {
  count = var.management_resources_enabled && local.monitoring_alerts_enabled ? 1 : 0

  name                = "law-search-availability-${terraform.workspace}"
  resource_group_name = coalesce(var.management_resource_settings.resource_group_name, local.resource_names.resource_group)
  scopes              = [module.management_resources[0].log_analytics_workspace.id]
  description         = "Alert when SearchableResultsAvailability drops below ${var.monitoring_alerts.search_availability_threshold_percent}%, indicating degraded query capacity."
  severity            = 2
  frequency           = "PT5M"
  window_size         = "PT15M"
  enabled             = true
  tags                = var.tags

  criteria {
    metric_namespace = "Microsoft.OperationalInsights/workspaces"
    metric_name      = "SearchableResultsAvailability"
    aggregation      = "Average"
    operator         = "LessThan"
    threshold        = var.monitoring_alerts.search_availability_threshold_percent
  }

  dynamic "action" {
    for_each = var.monitoring_alerts.action_group_id != null ? [1] : []
    content {
      action_group_id = var.monitoring_alerts.action_group_id
    }
  }

  depends_on = [terraform_data.monitoring_alerts_require_action_group]
}

# Log Analytics data ingestion guardrail alert
resource "azurerm_monitor_metric_alert" "law_data_ingest" {
  count = var.management_resources_enabled && local.monitoring_alerts_enabled ? 1 : 0

  name                = "law-data-ingest-${terraform.workspace}"
  resource_group_name = coalesce(var.management_resource_settings.resource_group_name, local.resource_names.resource_group)
  scopes              = [module.management_resources[0].log_analytics_workspace.id]
  description         = "Alert when Log Analytics daily ingestion exceeds ${var.monitoring_alerts.data_ingest_threshold_gb} GB to help control costs."
  severity            = 3
  frequency           = "PT15M"
  window_size         = "PT1H"
  enabled             = true
  tags                = var.tags

  criteria {
    metric_namespace = "Microsoft.OperationalInsights/workspaces"
    metric_name      = "DataIngested"
    aggregation      = "Total"
    operator         = "GreaterThan"
    threshold        = local.monitoring_alerts_ingest_threshold_bytes
  }

  dynamic "action" {
    for_each = var.monitoring_alerts.action_group_id != null ? [1] : []
    content {
      action_group_id = var.monitoring_alerts.action_group_id
    }
  }

  depends_on = [terraform_data.monitoring_alerts_require_action_group]
}

# Log Analytics query runtime alert
resource "azurerm_monitor_scheduled_query_rules_alert_v2" "law_query_runtime" {
  count = var.management_resources_enabled && local.monitoring_alerts_enabled ? 1 : 0

  name                = "law-query-runtime-${terraform.workspace}"
  resource_group_name = coalesce(var.management_resource_settings.resource_group_name, local.resource_names.resource_group)
  location            = var.location
  scopes              = [module.management_resources[0].log_analytics_workspace.id]
  description         = "Alert when Log Analytics queries exceed ${var.monitoring_alerts.query_duration_threshold_ms} ms, indicating inefficient or stuck workloads."
  severity            = 3
  enabled             = true
  tags                = var.tags

  evaluation_frequency = "PT15M"
  window_duration      = "PT15M"

  criteria {
    query = <<-QUERY
      QueryStoreRuntimeStatistics
      | where DurationMs > ${var.monitoring_alerts.query_duration_threshold_ms}
      | summarize SlowQueryCount = count() by bin(TimeGenerated, 15m)
      | where SlowQueryCount > 0
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

  depends_on = [terraform_data.monitoring_alerts_require_action_group]
}
