# Gateway Metric Alerts for VPN and ExpressRoute
# Reference: https://learn.microsoft.com/en-us/azure/vpn-gateway/monitor-vpn-gateway

locals {
  vpn_gateways_with_alerts = {
    for region, hub in local.enabled_hubs : region => hub
    if hub.features.vpn_gateway && local.log_analytics_workspace_id != null
  }

  expressroute_gateways_with_alerts = {
    for region, hub in local.enabled_hubs : region => hub
    if hub.features.expressroute_gateway && local.log_analytics_workspace_id != null
  }
}

# VPN Gateway tunnel bandwidth alert (severity 2)
resource "azurerm_monitor_metric_alert" "vpn_tunnel_bandwidth" {
  for_each = local.vpn_gateways_with_alerts

  name                = "alert-vpn-tunnel-bandwidth-${each.key}"
  resource_group_name = module.resource_groups["hub-${each.key}"].name
  scopes              = [local.vpn_gateway_resource_ids[each.key]]
  description         = "Alert when VPN tunnel bandwidth drops in ${each.key}"
  severity            = 2
  frequency           = "PT5M"
  window_size         = "PT15M"

  criteria {
    metric_namespace = "Microsoft.Network/vpnGateways"
    metric_name      = "TunnelAverageBandwidth"
    aggregation      = "Average"
    operator         = "LessThan"
    threshold        = 1 # Alert when bandwidth drops to near zero
  }

  tags = var.tags
}

# VPN Gateway BGP peer status alert (severity 1)
resource "azurerm_monitor_metric_alert" "vpn_bgp_peer_status" {
  for_each = local.vpn_gateways_with_alerts

  name                = "alert-vpn-bgp-peer-${each.key}"
  resource_group_name = module.resource_groups["hub-${each.key}"].name
  scopes              = [local.vpn_gateway_resource_ids[each.key]]
  description         = "Alert when VPN BGP peer status degrades in ${each.key}"
  severity            = 1
  frequency           = "PT1M"
  window_size         = "PT5M"

  criteria {
    metric_namespace = "Microsoft.Network/vpnGateways"
    metric_name      = "BgpPeerStatus"
    aggregation      = "Average"
    operator         = "LessThan"
    threshold        = 1
  }

  tags = var.tags
}

# ExpressRoute Gateway bits received alert (severity 2)
resource "azurerm_monitor_metric_alert" "expressroute_bits_received" {
  for_each = local.expressroute_gateways_with_alerts

  name                = "alert-er-bits-received-${each.key}"
  resource_group_name = module.resource_groups["hub-${each.key}"].name
  scopes              = [module.virtual_wan.express_route_gateway_resource_ids[each.key]]
  description         = "Alert when ExpressRoute received traffic drops in ${each.key}"
  severity            = 2
  frequency           = "PT5M"
  window_size         = "PT15M"

  criteria {
    metric_namespace = "Microsoft.Network/expressRouteGateways"
    metric_name      = "ErGatewayConnectionBitsInPerSecond"
    aggregation      = "Average"
    operator         = "LessThan"
    threshold        = 1 # Alert when traffic drops to near zero
  }

  tags = var.tags
}

# ExpressRoute Gateway CPU utilization alert (severity 2)
resource "azurerm_monitor_metric_alert" "expressroute_cpu" {
  for_each = local.expressroute_gateways_with_alerts

  name                = "alert-er-cpu-${each.key}"
  resource_group_name = module.resource_groups["hub-${each.key}"].name
  scopes              = [module.virtual_wan.express_route_gateway_resource_ids[each.key]]
  description         = "Alert when ExpressRoute Gateway CPU exceeds 80% in ${each.key}"
  severity            = 2
  frequency           = "PT5M"
  window_size         = "PT15M"

  criteria {
    metric_namespace = "Microsoft.Network/expressRouteGateways"
    metric_name      = "ExpressRouteGatewayCpuUtilization"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 80
  }

  tags = var.tags
}
