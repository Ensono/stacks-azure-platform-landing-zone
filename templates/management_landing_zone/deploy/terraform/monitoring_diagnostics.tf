# Log Analytics workspace self-monitoring diagnostic settings

resource "azurerm_monitor_diagnostic_setting" "log_analytics_workspace" {
  count = var.management_resources_enabled ? 1 : 0

  name                       = "law-self-diagnostics"
  target_resource_id         = module.management_resources[0].log_analytics_workspace.id
  log_analytics_workspace_id = module.management_resources[0].log_analytics_workspace.id

  enabled_log {
    category = "Audit"
  }

  enabled_log {
    category = "SummaryLogs"
  }

  enabled_metric {
    category = "AllMetrics"
  }
}
