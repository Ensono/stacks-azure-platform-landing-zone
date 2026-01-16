output "hub_regions" {
  description = "List of regions where hubs are deployed."
  value       = keys(local.enabled_hubs)
}

output "hub_address_spaces" {
  description = "Address space allocated to each hub, keyed by region."
  value       = { for region, addr in local.hub_addresses : region => addr.hub_address_space }
}

output "virtual_network_resource_ids" {
  description = "Resource IDs of hub virtual networks, keyed by region."
  value       = module.hub_and_spoke_vnet.virtual_network_resource_ids
}

output "virtual_network_resource_names" {
  description = "Names of hub virtual networks, keyed by region."
  value       = module.hub_and_spoke_vnet.virtual_network_resource_names
}

output "dns_server_ip_addresses" {
  description = "Private DNS Resolver IP addresses, keyed by region. Use for custom DNS configuration."
  value       = module.hub_and_spoke_vnet.dns_server_ip_addresses
}

output "firewall_resource_ids" {
  description = "Resource IDs of Azure Firewalls, keyed by region."
  value       = module.hub_and_spoke_vnet.firewall_resource_ids
}

output "firewall_resource_names" {
  description = "Names of Azure Firewalls, keyed by region."
  value       = module.hub_and_spoke_vnet.firewall_resource_names
}

output "firewall_private_ip_addresses" {
  description = "Private IP addresses of Azure Firewalls, keyed by region. Use for UDR next-hop."
  value       = module.hub_and_spoke_vnet.firewall_private_ip_addresses
}

output "firewall_public_ip_addresses" {
  description = "Public IP addresses of Azure Firewalls, keyed by region."
  value       = module.hub_and_spoke_vnet.firewall_public_ip_addresses
}

output "firewall_policies" {
  description = "Azure Firewall Policy resources, keyed by region."
  value       = module.hub_and_spoke_vnet.firewall_policies
}

output "firewall_diagnostic_setting_ids" {
  description = "Diagnostic setting IDs for Azure Firewalls, keyed by region."
  value       = { for k, v in azurerm_monitor_diagnostic_setting.firewall : k => v.id }
}

output "route_tables_firewall" {
  description = "Route tables for firewall subnets, keyed by region."
  value       = module.hub_and_spoke_vnet.route_tables_firewall
}

output "route_tables_user_subnets" {
  description = "Route tables for user subnets (with default route to firewall), keyed by region."
  value       = module.hub_and_spoke_vnet.route_tables_user_subnets
}

output "bastion_host_resource_ids" {
  description = "Resource IDs of Bastion hosts, keyed by region. Null if bastion disabled."
  value       = module.hub_and_spoke_vnet.bastion_host_resource_ids
}

output "bastion_host_public_ip_addresses" {
  description = "Public IP addresses of Bastion hosts, keyed by region."
  value       = module.hub_and_spoke_vnet.bastion_host_public_ip_address
}

output "bastion_host_dns_names" {
  description = "DNS names of Bastion hosts, keyed by region."
  value       = module.hub_and_spoke_vnet.bastion_host_dns_names
}

output "resource_group_ids" {
  description = "Resource IDs of all resource groups created by this module."
  value       = { for k, v in module.resource_groups : k => v.resource_id }
}

output "resource_group_names" {
  description = "Names of all resource groups created by this module."
  value       = { for k, v in module.resource_groups : k => v.name }
}

output "ampls_id" {
  description = "Resource ID of the Azure Monitor Private Link Scope."
  value       = try(azurerm_monitor_private_link_scope.this[0].id, null)
}

output "ampls_name" {
  description = "Name of the Azure Monitor Private Link Scope. Use to add scoped services from app landing zones."
  value       = try(azurerm_monitor_private_link_scope.this[0].name, null)
}

output "ampls_resource_group_name" {
  description = "Resource group containing the Azure Monitor Private Link Scope."
  value       = try(module.resource_groups["hub-${local.primary_hub_region}"].name, null)
}

output "ampls_private_endpoint_ids" {
  description = "Resource IDs of AMPLS private endpoints, keyed by region."
  value       = { for k, v in azurerm_private_endpoint.ampls : k => v.id }
}

output "ampls_private_ip_addresses" {
  description = "Private IP addresses of AMPLS endpoints, keyed by region."
  value = {
    for k, v in azurerm_private_endpoint.ampls : k => v.private_service_connection[0].private_ip_address
  }
}
