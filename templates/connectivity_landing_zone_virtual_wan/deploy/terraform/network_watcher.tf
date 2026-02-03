# Network Watcher for network diagnostics
# Provides: Connection Monitor, IP Flow Verify, Next Hop, Packet Capture, NSG Diagnostics

resource "azurerm_network_watcher" "this" {
  for_each = var.network_watcher.enabled ? local.enabled_hubs : {}

  name                = module.naming["hub-${each.key}"].network_watcher.name
  location            = each.key
  resource_group_name = module.resource_groups["hub-${each.key}"].name
  tags                = merge(var.tags, each.value.tags)
}

# VNet Flow Logs for sidecar virtual network traffic analysis
# Note: Virtual WAN hub traffic is managed by Microsoft - flow logs capture sidecar VNet traffic
# Storage account is created in connectivity (same region as VNet) per Microsoft requirements
resource "azurerm_network_watcher_flow_log" "sidecar_vnet" {
  for_each = local.flow_logs_enabled ? {
    for region, hub in local.enabled_hubs : region => hub
    if hub.features.sidecar_virtual_network
  } : {}

  name                 = "fl-${local.hub_names[each.key].sidecar_virtual_network}"
  network_watcher_name = azurerm_network_watcher.this[each.key].name
  resource_group_name  = azurerm_network_watcher.this[each.key].resource_group_name
  target_resource_id   = module.virtual_wan.sidecar_virtual_network_resource_ids[each.key]
  storage_account_id   = local.flow_logs_storage_account_ids[each.key]
  enabled              = true
  version              = 2
  tags                 = merge(var.tags, each.value.tags)

  retention_policy {
    enabled = var.flow_logs.retention_days > 0
    days    = var.flow_logs.retention_days
  }

  dynamic "traffic_analytics" {
    for_each = var.flow_logs.traffic_analytics_enabled && local.log_analytics_workspace_id != null && local.log_analytics_workspace_guid != null ? [1] : []
    content {
      enabled               = true
      workspace_id          = local.log_analytics_workspace_guid
      workspace_region      = local.primary_hub_region
      workspace_resource_id = local.log_analytics_workspace_id
      interval_in_minutes   = 10
    }
  }
}
