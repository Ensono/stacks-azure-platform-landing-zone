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

# VPN Gateway tunnel egress bytes alert (severity 2)
resource "azurerm_monitor_metric_alert" "vpn_tunnel_egress" {
  for_each = local.vpn_gateways_with_alerts

  name                = "alert-vpn-tunnel-egress-${each.key}"
  resource_group_name = module.resource_groups["hub-${each.key}"].name
  scopes              = [local.vpn_gateway_resource_ids[each.key]]
  description         = "Alert when VPN tunnel egress drops in ${each.key}"
  severity            = 2
  frequency           = "PT5M"
  window_size         = "PT15M"

  criteria {
    metric_namespace = "Microsoft.Network/virtualNetworkGateways"
    metric_name      = "TunnelEgressBytes"
    aggregation      = "Total"
    operator         = "LessThan"
    threshold        = 1 # Alert when traffic drops to near zero
  }

  tags = var.tags

  depends_on = [module.hub_and_spoke_vnet]
}

# VPN Gateway P2S connection count alert (severity 2)
resource "azurerm_monitor_metric_alert" "vpn_p2s_connections" {
  for_each = local.vpn_gateways_with_alerts

  name                = "alert-vpn-p2s-${each.key}"
  resource_group_name = module.resource_groups["hub-${each.key}"].name
  scopes              = [local.vpn_gateway_resource_ids[each.key]]
  description         = "Alert when P2S connection count is high in ${each.key}"
  severity            = 2
  frequency           = "PT5M"
  window_size         = "PT15M"

  criteria {
    metric_namespace = "Microsoft.Network/virtualNetworkGateways"
    metric_name      = "P2SConnectionCount"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 100 # Adjust based on expected P2S usage
  }

  tags = var.tags

  depends_on = [module.hub_and_spoke_vnet]
}

# ExpressRoute Gateway bits received alert (severity 2)
resource "azurerm_monitor_metric_alert" "expressroute_bits_received" {
  for_each = local.expressroute_gateways_with_alerts

  name                = "alert-er-bits-received-${each.key}"
  resource_group_name = module.resource_groups["hub-${each.key}"].name
  scopes              = [local.expressroute_gateway_resource_ids[each.key]]
  description         = "Alert when ExpressRoute received traffic drops in ${each.key}"
  severity            = 2
  frequency           = "PT5M"
  window_size         = "PT15M"

  criteria {
    metric_namespace = "Microsoft.Network/virtualNetworkGateways"
    metric_name      = "ExpressRouteGatewayBitsPerSecond"
    aggregation      = "Average"
    operator         = "LessThan"
    threshold        = 1 # Alert when traffic drops to near zero
  }

  tags = var.tags

  depends_on = [module.hub_and_spoke_vnet]
}

# ExpressRoute Gateway CPU utilization alert (severity 2)
resource "azurerm_monitor_metric_alert" "expressroute_cpu" {
  for_each = local.expressroute_gateways_with_alerts

  name                = "alert-er-cpu-${each.key}"
  resource_group_name = module.resource_groups["hub-${each.key}"].name
  scopes              = [local.expressroute_gateway_resource_ids[each.key]]
  description         = "Alert when ExpressRoute Gateway CPU exceeds 80% in ${each.key}"
  severity            = 2
  frequency           = "PT5M"
  window_size         = "PT15M"

  criteria {
    metric_namespace = "Microsoft.Network/virtualNetworkGateways"
    metric_name      = "ExpressRouteGatewayCpuUtilization"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 80
  }

  tags = var.tags

  depends_on = [module.hub_and_spoke_vnet]
}
