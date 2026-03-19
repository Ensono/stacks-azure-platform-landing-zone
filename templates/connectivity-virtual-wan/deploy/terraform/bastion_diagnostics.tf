# Bastion Host Diagnostic Settings
# Reference: https://learn.microsoft.com/en-us/azure/bastion/diagnostic-logs

locals {
  bastion_with_diagnostics = {
    for region, hub in local.enabled_hubs : region => hub
    if hub.features.bastion && local.log_analytics_workspace_id != null
  }
}

resource "azurerm_monitor_diagnostic_setting" "bastion" {
  for_each = local.bastion_with_diagnostics

  name                           = "diag-bastion-${each.key}"
  target_resource_id             = module.virtual_wan.bastion_host_resource_ids[each.key]
  log_analytics_workspace_id     = local.log_analytics_workspace_id
  log_analytics_destination_type = "Dedicated"

  enabled_log { category = "BastionAuditLogs" }

  enabled_metric { category = "AllMetrics" }

  depends_on = [module.virtual_wan]
}
