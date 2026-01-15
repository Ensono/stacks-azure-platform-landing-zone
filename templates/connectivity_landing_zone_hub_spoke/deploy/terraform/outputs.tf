# =============================================================================
# Module Outputs
# =============================================================================
#
# These outputs expose key resource information from the hub-spoke deployment.
# All outputs are keyed by region (e.g., "uksouth", "ukwest").
#
# USAGE:
# ------
# Access outputs in consuming modules:
#   module.connectivity.virtual_network_resource_ids["uksouth"]
#   module.connectivity.firewall_private_ip_addresses["uksouth"]
#
# =============================================================================

# -----------------------------------------------------------------------------
# Hub Configuration (for debugging/reference)
# -----------------------------------------------------------------------------

output "hub_regions" {
  description = "List of regions where hubs are deployed."
  value       = keys(local.enabled_hubs)
}

output "hub_address_spaces" {
  description = "Address space allocated to each hub, keyed by region."
  value       = { for region, addr in local.hub_addresses : region => addr.hub_address_space }
}

# -----------------------------------------------------------------------------
# Virtual Networks
# -----------------------------------------------------------------------------

output "virtual_network_resource_ids" {
  description = "Resource IDs of hub virtual networks, keyed by region."
  value       = module.hub_and_spoke_vnet.virtual_network_resource_ids
}

output "virtual_network_resource_names" {
  description = "Names of hub virtual networks, keyed by region."
  value       = module.hub_and_spoke_vnet.virtual_network_resource_names
}

# -----------------------------------------------------------------------------
# DNS
# -----------------------------------------------------------------------------

output "dns_server_ip_addresses" {
  description = "Private DNS Resolver IP addresses, keyed by region. Use for custom DNS configuration."
  value       = module.hub_and_spoke_vnet.dns_server_ip_addresses
}

# -----------------------------------------------------------------------------
# Azure Firewall
# -----------------------------------------------------------------------------

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

# -----------------------------------------------------------------------------
# Route Tables
# -----------------------------------------------------------------------------

output "route_tables_firewall" {
  description = "Route tables for firewall subnets, keyed by region."
  value       = module.hub_and_spoke_vnet.route_tables_firewall
}

output "route_tables_user_subnets" {
  description = "Route tables for user subnets (with default route to firewall), keyed by region."
  value       = module.hub_and_spoke_vnet.route_tables_user_subnets
}

# -----------------------------------------------------------------------------
# Azure Bastion
# -----------------------------------------------------------------------------

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

# -----------------------------------------------------------------------------
# Resource Groups
# -----------------------------------------------------------------------------

output "resource_group_ids" {
  description = "Resource IDs of all resource groups created by this module."
  value       = { for k, v in module.resource_groups : k => v.resource_id }
}

output "resource_group_names" {
  description = "Names of all resource groups created by this module."
  value       = { for k, v in module.resource_groups : k => v.name }
}
