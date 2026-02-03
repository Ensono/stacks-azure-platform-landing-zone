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

# Subscription activity logs routed to Log Analytics workspace for governance visibility
resource "azurerm_monitor_diagnostic_setting" "subscription_activity" {
  count = var.management_resources_enabled ? 1 : 0

  name                           = "management-subscription-activity"
  target_resource_id             = "/subscriptions/${var.management_subscription_id}"
  log_analytics_workspace_id     = module.management_resources[0].log_analytics_workspace.id
  log_analytics_destination_type = "Dedicated"

  enabled_log { category = "Administrative" }
  enabled_log { category = "Security" }
  enabled_log { category = "Policy" }
  enabled_log { category = "ServiceHealth" }
  enabled_log { category = "ResourceHealth" }
  enabled_log { category = "Alert" }
  enabled_log { category = "Recommendation" }

  enabled_metric {
    category = "AllMetrics"
  }
}
