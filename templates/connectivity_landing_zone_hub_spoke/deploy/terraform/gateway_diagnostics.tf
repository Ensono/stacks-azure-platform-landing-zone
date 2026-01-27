locals {
  vpn_gateways_with_diagnostics = {
    for region, hub in local.enabled_hubs : region => hub
    if hub.features.vpn_gateway && local.log_analytics_workspace_id != null
  }

  expressroute_gateways_with_diagnostics = {
    for region, hub in local.enabled_hubs : region => hub
    if hub.features.expressroute_gateway && local.log_analytics_workspace_id != null
  }

  vpn_gateway_resource_ids = {
    for region, hub in local.vpn_gateways_with_diagnostics : region =>
    "${local.hub_resource_group_ids[region]}/providers/Microsoft.Network/virtualNetworkGateways/${local.hub_names[region].vpn_gateway}"
  }

  expressroute_gateway_resource_ids = {
    for region, hub in local.expressroute_gateways_with_diagnostics : region =>
    "${local.hub_resource_group_ids[region]}/providers/Microsoft.Network/virtualNetworkGateways/${local.hub_names[region].expressroute_gateway}"
  }
}

resource "azurerm_monitor_diagnostic_setting" "vpn_gateway" {
  for_each = local.vpn_gateways_with_diagnostics

  name                           = "diag-vpn-gateway-${each.key}"
  target_resource_id             = local.vpn_gateway_resource_ids[each.key]
  log_analytics_workspace_id     = local.log_analytics_workspace_id
  log_analytics_destination_type = "Dedicated"

  enabled_log { category = "GatewayDiagnosticLog" }
  enabled_log { category = "TunnelDiagnosticLog" }
  enabled_log { category = "RouteDiagnosticLog" }
  enabled_log { category = "IKEDiagnosticLog" }
  enabled_log { category = "P2SDiagnosticLog" }
  enabled_metric { category = "AllMetrics" }

  depends_on = [module.hub_and_spoke_vnet]
}

resource "azurerm_monitor_diagnostic_setting" "expressroute_gateway" {
  for_each = local.expressroute_gateways_with_diagnostics

  name                           = "diag-er-gateway-${each.key}"
  target_resource_id             = local.expressroute_gateway_resource_ids[each.key]
  log_analytics_workspace_id     = local.log_analytics_workspace_id
  log_analytics_destination_type = "Dedicated"

  enabled_log { category = "GatewayDiagnosticLog" }
  enabled_log { category = "RouteDiagnosticLog" }
  enabled_metric { category = "AllMetrics" }

  depends_on = [module.hub_and_spoke_vnet]
}
