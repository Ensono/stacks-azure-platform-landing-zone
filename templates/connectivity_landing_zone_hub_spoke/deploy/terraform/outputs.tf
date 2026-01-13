output "dns_server_ip_address" {
  description = "The DNS server IP addresses for each hub. Populated when private DNS resolver is enabled."
  value       = module.hub_and_spoke_vnet.dns_server_ip_addresses
}

output "virtual_network_resource_ids" {
  description = "The resource IDs of the hub virtual networks."
  value       = module.hub_and_spoke_vnet.virtual_network_resource_ids
}

output "virtual_network_resource_names" {
  description = "The names of the hub virtual networks."
  value       = module.hub_and_spoke_vnet.virtual_network_resource_names
}

output "bastion_host_public_ip_address" {
  description = "The public IP addresses of bastion hosts. Empty if bastion is disabled."
  value       = module.hub_and_spoke_vnet.bastion_host_public_ip_address
}

output "bastion_host_resource_ids" {
  description = "The resource IDs of bastion hosts. Empty if bastion is disabled."
  value       = module.hub_and_spoke_vnet.bastion_host_resource_ids
}

output "bastion_host_dns_names" {
  description = "The DNS names of bastion hosts. Empty if bastion is disabled."
  value       = module.hub_and_spoke_vnet.bastion_host_dns_names
}

output "firewall_resource_ids" {
  description = "The resource IDs of Azure Firewalls. Empty if firewall is disabled."
  value       = module.hub_and_spoke_vnet.firewall_resource_ids
}

output "firewall_resource_names" {
  description = "The names of Azure Firewalls. Empty if firewall is disabled."
  value       = module.hub_and_spoke_vnet.firewall_resource_names
}

output "firewall_private_ip_addresses" {
  description = "The private IP addresses of Azure Firewalls. Empty if firewall is disabled."
  value       = module.hub_and_spoke_vnet.firewall_private_ip_addresses
}

output "firewall_public_ip_addresses" {
  description = "The public IP addresses of Azure Firewalls. Empty if firewall is disabled."
  value       = module.hub_and_spoke_vnet.firewall_public_ip_addresses
}

output "firewall_policies" {
  description = "The Azure Firewall policy resources. Empty if firewall is disabled."
  value       = module.hub_and_spoke_vnet.firewall_policies
}

output "route_tables_firewall" {
  description = "The route tables for firewall subnets. Empty if firewall is disabled."
  value       = module.hub_and_spoke_vnet.route_tables_firewall
}

output "route_tables_user_subnets" {
  description = "The route tables for user subnets with routes to firewall."
  value       = module.hub_and_spoke_vnet.route_tables_user_subnets
}
