locals {
  # Keys in the AVM module's private_dns_zone_resource_ids output for AMPLS
  ampls_required_dns_zone_keys = [
    "azure_monitor",            # privatelink.monitor.azure.com
    "azure_log_analytics",      # privatelink.oms.opinsights.azure.com
    "azure_log_analytics_data", # privatelink.ods.opinsights.azure.com
    "azure_monitor_agent",      # privatelink.agentsvc.azure-automation.net
    "azure_storage_blob",       # privatelink.blob.core.windows.net
  ]

  # Get DNS zone IDs from the hub_and_spoke_vnet module output (primary hub has all zones)
  ampls_dns_zone_ids = var.azure_monitor_private_link.enabled ? [
    for key in local.ampls_required_dns_zone_keys :
    module.hub_and_spoke_vnet.private_dns_zone_resource_ids[local.primary_hub_region][key]
  ] : []
}
