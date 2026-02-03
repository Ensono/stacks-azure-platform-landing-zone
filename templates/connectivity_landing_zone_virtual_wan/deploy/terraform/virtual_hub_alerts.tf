# Virtual Hub Metric Alerts
# Reference: https://learn.microsoft.com/en-us/azure/virtual-wan/monitor-virtual-wan

locals {
  virtual_hubs_with_alerts = {
    for region, hub in local.enabled_hubs : region => hub
    if local.log_analytics_workspace_id != null
  }
}

# Virtual Hub routing capacity alert (severity 2)
resource "azurerm_monitor_metric_alert" "virtual_hub_routing_capacity" {
  for_each = local.virtual_hubs_with_alerts

  name                = "alert-vhub-routing-${each.key}"
  resource_group_name = module.resource_groups["hub-${each.key}"].name
  scopes              = [module.virtual_wan.virtual_hub_resource_ids[each.key]]
  description         = "Alert when Virtual Hub routing infrastructure utilization exceeds 80% in ${each.key}"
  severity            = 2
  frequency           = "PT5M"
  window_size         = "PT15M"

  criteria {
    metric_namespace = "Microsoft.Network/virtualHubs"
    metric_name      = "VirtualHubDataProcessed"
    aggregation      = "Total"
    operator         = "GreaterThan"
    threshold        = 500000000000 # 500 GB - adjust based on expected traffic
  }

  tags = var.tags
}

# Virtual Hub BGP peer status alert (severity 1)
resource "azurerm_monitor_metric_alert" "virtual_hub_bgp_peer" {
  for_each = local.virtual_hubs_with_alerts

  name                = "alert-vhub-bgp-${each.key}"
  resource_group_name = module.resource_groups["hub-${each.key}"].name
  scopes              = [module.virtual_wan.virtual_hub_resource_ids[each.key]]
  description         = "Alert when Virtual Hub BGP peer count drops in ${each.key}"
  severity            = 1
  frequency           = "PT1M"
  window_size         = "PT5M"

  criteria {
    metric_namespace = "Microsoft.Network/virtualHubs"
    metric_name      = "BgpPeerStatus"
    aggregation      = "Average"
    operator         = "LessThan"
    threshold        = 1
  }

  tags = var.tags
}
