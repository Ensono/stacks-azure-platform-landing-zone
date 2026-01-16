locals {
  ampls_required_dns_zones = [
    "privatelink.monitor.azure.com",
    "privatelink.oms.opinsights.azure.com",
    "privatelink.ods.opinsights.azure.com",
    "privatelink.agentsvc.azure-automation.net",
    "privatelink.blob.core.windows.net",
  ]

  ampls_dns_zone_ids = var.azure_monitor_private_link.enabled ? [
    for zone in local.ampls_required_dns_zones :
    "/subscriptions/${var.connectivity_subscription_id}/resourceGroups/${module.naming["hub-dns"].resource_group.name}/providers/Microsoft.Network/privateDnsZones/${zone}"
  ] : []
}
