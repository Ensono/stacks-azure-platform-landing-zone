resource "azurerm_monitor_private_link_scope" "this" {
  count = var.azure_monitor_private_link.enabled ? 1 : 0

  name = coalesce(
    var.azure_monitor_private_link.name,
    local.naming_extended["hub-${local.primary_hub_region}"].azure_monitor_private_link_scope.name
  )
  resource_group_name   = module.resource_groups["hub-${local.primary_hub_region}"].name
  ingestion_access_mode = var.azure_monitor_private_link.ingestion_access_mode
  query_access_mode     = var.azure_monitor_private_link.query_access_mode
  tags                  = var.tags
}

resource "azurerm_monitor_private_link_scoped_service" "log_analytics" {
  count = var.azure_monitor_private_link.enabled ? 1 : 0

  name                = "log-analytics-platform"
  resource_group_name = module.resource_groups["hub-${local.primary_hub_region}"].name
  scope_name          = azurerm_monitor_private_link_scope.this[0].name
  linked_resource_id  = local.log_analytics_workspace_id
}

resource "azurerm_private_endpoint" "ampls" {
  for_each = var.azure_monitor_private_link.enabled ? {
    for region, hub in local.enabled_hubs : region => hub
    if hub.features.sidecar_virtual_network
  } : {}

  name                = module.naming["hub-ampls-${each.key}"].private_endpoint.name
  location            = each.key
  resource_group_name = module.resource_groups["hub-${each.key}"].name
  subnet_id           = "${module.virtual_wan.sidecar_virtual_network_resource_ids[each.key]}/subnets/snet-private-endpoints"

  private_service_connection {
    name                           = module.naming["hub-ampls-${each.key}"].private_service_connection.name
    private_connection_resource_id = azurerm_monitor_private_link_scope.this[0].id
    subresource_names              = ["azuremonitor"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = module.naming["hub-ampls-${each.key}"].private_dns_zone_group.name
    private_dns_zone_ids = local.ampls_dns_zone_ids
  }

  tags = merge(var.tags, each.value.tags)
}
