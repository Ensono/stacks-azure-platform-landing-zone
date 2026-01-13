output "dns_server_ip_address" {
  description = "The DNS server IP addresses for each virtual hub. Populated when private DNS resolver is enabled."
  value       = module.virtual_wan.dns_server_ip_address
}

output "virtual_wan_resource_id" {
  description = "The resource ID of the virtual WAN."
  value       = module.virtual_wan.resource_id
}

output "virtual_wan_name" {
  description = "The name of the virtual WAN."
  value       = module.virtual_wan.name
}

output "virtual_hub_resource_ids" {
  description = "The resource IDs of the virtual hubs."
  value       = module.virtual_wan.virtual_hub_resource_ids
}

output "virtual_hub_resource_names" {
  description = "The names of the virtual hubs."
  value       = module.virtual_wan.virtual_hub_resource_names
}

output "firewall_resource_ids" {
  description = "The resource IDs of Azure Firewalls. Empty if firewall is disabled."
  value       = module.virtual_wan.firewall_resource_ids
}

output "firewall_resource_names" {
  description = "The names of Azure Firewalls. Empty if firewall is disabled."
  value       = module.virtual_wan.firewall_resource_names
}

output "firewall_private_ip_addresses" {
  description = "The private IP addresses of Azure Firewalls. Empty if firewall is disabled."
  value       = module.virtual_wan.firewall_private_ip_address
}

output "firewall_public_ip_addresses" {
  description = "The public IP addresses of Azure Firewalls. Empty if firewall is disabled."
  value       = module.virtual_wan.firewall_public_ip_addresses
}

output "firewall_policy_resource_ids" {
  description = "The resource IDs of Azure Firewall policies. Empty if firewall is disabled."
  value       = module.virtual_wan.firewall_policy_resource_ids
}

output "express_route_gateway_resource_ids" {
  description = "The resource IDs of ExpressRoute gateways. Empty if ExpressRoute is disabled."
  value       = module.virtual_wan.express_route_gateway_resource_ids
}

output "bastion_host_public_ip_addresses" {
  description = "The public IP addresses of bastion hosts. Empty if bastion is disabled."
  value       = module.virtual_wan.bastion_host_public_ip_address
}

output "bastion_host_resource_ids" {
  description = "The resource IDs of bastion hosts. Empty if bastion is disabled."
  value       = module.virtual_wan.bastion_host_resource_ids
}

output "bastion_host_dns_names" {
  description = "The DNS names of bastion hosts. Empty if bastion is disabled."
  value       = module.virtual_wan.bastion_host_dns_names
}

output "private_dns_resolver_resource_ids" {
  description = "The resource IDs of private DNS resolvers. Empty if DNS resolver is disabled."
  value       = module.virtual_wan.private_dns_resolver_resource_ids
}

output "private_dns_resolver_resources" {
  description = "The private DNS resolver resources. Empty if DNS resolver is disabled."
  value       = module.virtual_wan.private_dns_resolver_resources
}

output "sidecar_virtual_network_resource_ids" {
  description = "The resource IDs of sidecar virtual networks."
  value       = module.virtual_wan.sidecar_virtual_network_resource_ids
}

output "sidecar_virtual_network_resources" {
  description = "The sidecar virtual network resources."
  value       = module.virtual_wan.sidecar_virtual_network_resources
}
