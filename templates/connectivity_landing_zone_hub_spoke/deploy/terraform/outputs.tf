output "hub_regions" {
  description = "Regions where hubs are deployed."
  value       = keys(local.enabled_hubs)
}

output "hub_address_spaces" {
  description = "Address space per hub."
  value       = { for region, addr in local.hub_addresses : region => addr.hub_address_space }
}

output "virtual_network_resource_ids" {
  description = "Hub VNet resource IDs."
  value       = module.hub_and_spoke_vnet.virtual_network_resource_ids
}

output "virtual_network_resource_names" {
  description = "Hub VNet names, keyed by region."
  value       = module.hub_and_spoke_vnet.virtual_network_resource_names
}

output "firewall_resource_ids" {
  description = "Azure Firewall resource IDs, keyed by region."
  value       = module.hub_and_spoke_vnet.firewall_resource_ids
}

output "firewall_resource_names" {
  description = "Azure Firewall names, keyed by region."
  value       = module.hub_and_spoke_vnet.firewall_resource_names
}

output "firewall_private_ip_addresses" {
  description = "Firewall private IPs for UDR next-hop."
  value       = module.hub_and_spoke_vnet.firewall_private_ip_addresses
}

output "firewall_public_ip_addresses" {
  description = "Firewall public IPs, keyed by region."
  value       = module.hub_and_spoke_vnet.firewall_public_ip_addresses
}

output "firewall_policies" {
  description = "Firewall Policy resources."
  value       = module.hub_and_spoke_vnet.firewall_policies
}

output "firewall_diagnostic_setting_ids" {
  description = "Diagnostic setting IDs for firewall."
  value       = { for k, v in azurerm_monitor_diagnostic_setting.firewall : k => v.id }
}

output "route_tables_firewall" {
  description = "Route tables for firewall subnets."
  value       = module.hub_and_spoke_vnet.route_tables_firewall
}

output "route_tables_user_subnets" {
  description = "Route tables for spoke subnets."
  value       = module.hub_and_spoke_vnet.route_tables_user_subnets
}

output "dns_server_ip_addresses" {
  description = "Private DNS Resolver IPs."
  value       = module.hub_and_spoke_vnet.dns_server_ip_addresses
}

output "bastion_host_resource_ids" {
  description = "Bastion host resource IDs."
  value       = module.hub_and_spoke_vnet.bastion_host_resource_ids
}

output "bastion_host_public_ip_addresses" {
  description = "Bastion public IPs, keyed by region."
  value       = module.hub_and_spoke_vnet.bastion_host_public_ip_address
}

output "bastion_host_dns_names" {
  description = "Bastion DNS names, keyed by region."
  value       = module.hub_and_spoke_vnet.bastion_host_dns_names
}

output "resource_group_ids" {
  description = "Resource group IDs."
  value       = { for k, v in module.resource_groups : k => v.resource_id }
}

output "resource_group_names" {
  description = "Resource group names."
  value       = { for k, v in module.resource_groups : k => v.name }
}

output "ampls_id" {
  description = "AMPLS resource ID."
  value       = try(azurerm_monitor_private_link_scope.this[0].id, null)
}

output "ampls_name" {
  description = "AMPLS name."
  value       = try(azurerm_monitor_private_link_scope.this[0].name, null)
}

output "ampls_resource_group_name" {
  description = "Resource group containing AMPLS."
  value       = try(module.resource_groups["hub-${local.primary_hub_region}"].name, null)
}

output "ampls_private_endpoint_ids" {
  description = "AMPLS private endpoint IDs, keyed by region."
  value       = { for k, v in azurerm_private_endpoint.ampls : k => v.id }
}

output "ampls_private_ip_addresses" {
  description = "AMPLS private IPs, keyed by region."
  value = {
    for k, v in azurerm_private_endpoint.ampls : k => v.private_service_connection[0].private_ip_address
  }
}

output "network_watcher_ids" {
  description = "Network Watcher resource IDs, keyed by region."
  value       = { for k, v in azurerm_network_watcher.this : k => v.id }
}

output "flow_log_ids" {
  description = "VNet Flow Log resource IDs, keyed by region."
  value       = { for k, v in azurerm_network_watcher_flow_log.vnet : k => v.id }
}

output "flow_logs_storage_account_ids" {
  description = "Flow logs storage account IDs, keyed by region. Storage accounts are created per-region to meet Azure requirements."
  value       = { for k, v in module.flow_logs_storage : k => v.resource_id }
}

output "flow_logs_storage_account_names" {
  description = "Flow logs storage account names, keyed by region."
  value       = { for k, v in module.flow_logs_storage : k => v.name }
}

# -----------------------------------------------------------------------------
# Outputs for Spoke Integration
# -----------------------------------------------------------------------------

output "private_dns_zone_resource_ids" {
  description = "Private DNS zone resource IDs for spoke VNet linking. Keyed by region, then zone key."
  value       = module.hub_and_spoke_vnet.private_dns_zone_resource_ids
}

output "subnet_resource_ids" {
  description = "Hub subnet resource IDs for UDR association. Keyed by region."
  value = {
    for region in keys(local.enabled_hubs) : region => {
      private_endpoints = "${module.hub_and_spoke_vnet.virtual_network_resource_ids[region]}/subnets/snet-private-endpoints"
    }
  }
}

output "route_table_user_subnets_ids" {
  description = "Route table IDs for spoke subnet association (routes traffic through firewall)."
  value       = { for k, v in module.hub_and_spoke_vnet.route_tables_user_subnets : k => v.id }
}

output "private_endpoints_nsg_ids" {
  description = "NSG resource IDs for private endpoints subnets, keyed by region."
  value       = { for k, v in module.nsg_private_endpoints : k => v.resource_id }
}

output "private_endpoints_nsg_names" {
  description = "NSG names for private endpoints subnets, keyed by region."
  value       = { for k, v in module.nsg_private_endpoints : k => v.name }
}
