# Virtual Hub Diagnostic Settings
# Reference: https://learn.microsoft.com/en-us/azure/virtual-wan/monitor-virtual-wan

locals {
  virtual_hubs_with_diagnostics = {
    for region, hub in local.enabled_hubs : region => hub
    if local.log_analytics_workspace_id != null
  }
}

resource "azurerm_monitor_diagnostic_setting" "virtual_hub" {
  for_each = local.virtual_hubs_with_diagnostics

  name                           = "diag-vhub-${each.key}"
  target_resource_id             = module.virtual_wan.virtual_hub_resource_ids[each.key]
  log_analytics_workspace_id     = local.log_analytics_workspace_id
  log_analytics_destination_type = "Dedicated"

  enabled_log {
    category = "RouteTableLogs"
  }

  enabled_metric {
    category = "AllMetrics"
  }
}
