output "hub_regions" {
  description = "Regions where virtual hubs are deployed."
  value       = keys(local.enabled_hubs)
}

output "primary_hub_region" {
  description = "Primary hub region (first alphabetically)."
  value       = local.primary_hub_region
}

output "hub_address_spaces" {
  description = "Address space per hub."
  value       = { for region, addr in local.hub_addresses : region => addr.hub_address_space }
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
  description = "The resource IDs of the virtual hubs, keyed by region."
  value       = module.virtual_wan.virtual_hub_resource_ids
}

output "virtual_hub_resource_names" {
  description = "The names of the virtual hubs, keyed by region."
  value       = module.virtual_wan.virtual_hub_resource_names
}

output "firewall_resource_ids" {
  description = "Azure Firewall resource IDs, keyed by region."
  value       = module.virtual_wan.firewall_resource_ids
}

output "firewall_resource_names" {
  description = "Azure Firewall names, keyed by region."
  value       = module.virtual_wan.firewall_resource_names
}

output "firewall_private_ip_addresses" {
  description = "Firewall private IPs for routing, keyed by region."
  value       = module.virtual_wan.firewall_private_ip_address
}

output "firewall_public_ip_addresses" {
  description = "Firewall public IPs, keyed by region."
  value       = module.virtual_wan.firewall_public_ip_addresses
}

output "firewall_policy_resource_ids" {
  description = "Azure Firewall Policy resource IDs, keyed by region."
  value       = module.virtual_wan.firewall_policy_resource_ids
}

output "firewall_diagnostic_setting_ids" {
  description = "Diagnostic setting IDs for firewall."
  value       = { for k, v in azurerm_monitor_diagnostic_setting.firewall : k => v.id }
}

output "gateway_diagnostic_setting_ids" {
  description = "Diagnostic setting IDs for VPN and ExpressRoute gateways, keyed by type and region."
  value = {
    vpn_gateway          = { for k, v in azurerm_monitor_diagnostic_setting.vpn_gateway : k => v.id }
    expressroute_gateway = { for k, v in azurerm_monitor_diagnostic_setting.expressroute_gateway : k => v.id }
  }
}

output "firewall_alert_ids" {
  description = "Firewall metric alert IDs, keyed by region and alert type."
  value = {
    health     = { for k, v in azurerm_monitor_metric_alert.firewall_health : k => v.id }
    snat       = { for k, v in azurerm_monitor_metric_alert.firewall_snat_exhaustion : k => v.id }
    throughput = { for k, v in azurerm_monitor_metric_alert.firewall_throughput : k => v.id }
    latency    = { for k, v in azurerm_monitor_metric_alert.firewall_latency : k => v.id }
  }
}

output "dns_server_ip_addresses" {
  description = "DNS server IPs (firewall private IP when DNS Proxy enabled, or DNS Resolver IPs)."
  value       = module.virtual_wan.dns_server_ip_address
}

output "express_route_gateway_resource_ids" {
  description = "ExpressRoute gateway resource IDs, keyed by region."
  value       = module.virtual_wan.express_route_gateway_resource_ids
}

output "bastion_host_resource_ids" {
  description = "Bastion host resource IDs, keyed by region."
  value       = module.virtual_wan.bastion_host_resource_ids
}

output "bastion_host_public_ip_addresses" {
  description = "Bastion public IPs, keyed by region."
  value       = module.virtual_wan.bastion_host_public_ip_address
}

output "bastion_host_dns_names" {
  description = "Bastion DNS names, keyed by region."
  value       = module.virtual_wan.bastion_host_dns_names
}

output "private_dns_resolver_resource_ids" {
  description = "Private DNS resolver resource IDs, keyed by region."
  value       = module.virtual_wan.private_dns_resolver_resource_ids
}

output "sidecar_virtual_network_resource_ids" {
  description = "Sidecar virtual network resource IDs, keyed by region."
  value       = module.virtual_wan.sidecar_virtual_network_resource_ids
}

output "virtual_hub_diagnostic_setting_ids" {
  description = "Diagnostic setting IDs for virtual hubs, keyed by region."
  value       = { for k, v in azurerm_monitor_diagnostic_setting.virtual_hub : k => v.id }
}

output "azure_monitor_private_link_scope_id" {
  description = "Azure Monitor Private Link Scope resource ID."
  value       = try(azurerm_monitor_private_link_scope.this[0].id, null)
}

output "azure_monitor_private_link_scope_name" {
  description = "Azure Monitor Private Link Scope name."
  value       = try(azurerm_monitor_private_link_scope.this[0].name, null)
}

output "ampls_private_endpoint_ids" {
  description = "AMPLS private endpoint IDs, keyed by region."
  value       = { for k, v in azurerm_private_endpoint.ampls : k => v.id }
}

output "resource_group_ids" {
  description = "Resource group IDs."
  value       = { for k, v in module.resource_groups : k => v.resource_id }
}

output "resource_group_names" {
  description = "Resource group names."
  value       = { for k, v in module.resource_groups : k => v.name }
}

output "bastion_diagnostic_setting_ids" {
  description = "Diagnostic setting IDs for Bastion hosts, keyed by region."
  value       = { for k, v in azurerm_monitor_diagnostic_setting.bastion : k => v.id }
}

output "virtual_hub_alert_ids" {
  description = "Virtual Hub metric alert IDs, keyed by region and alert type."
  value = {
    routing_capacity = { for k, v in azurerm_monitor_metric_alert.virtual_hub_routing_capacity : k => v.id }
    bgp_peer         = { for k, v in azurerm_monitor_metric_alert.virtual_hub_bgp_peer : k => v.id }
  }
}

output "private_endpoints_nsg_ids" {
  description = "Private endpoints NSG resource IDs, keyed by region."
  value       = { for k, v in module.nsg_private_endpoints : k => v.resource_id }
}

output "gateway_alert_ids" {
  description = "Gateway metric alert IDs, keyed by region and alert type."
  value = {
    vpn_tunnel_bandwidth = { for k, v in azurerm_monitor_metric_alert.vpn_tunnel_bandwidth : k => v.id }
    vpn_bgp_peer_status  = { for k, v in azurerm_monitor_metric_alert.vpn_bgp_peer_status : k => v.id }
    expressroute_bits    = { for k, v in azurerm_monitor_metric_alert.expressroute_bits_received : k => v.id }
    expressroute_cpu     = { for k, v in azurerm_monitor_metric_alert.expressroute_cpu : k => v.id }
  }
}

output "network_watcher_ids" {
  description = "Network Watcher resource IDs, keyed by region."
  value       = { for k, v in azurerm_network_watcher.this : k => v.id }
}

output "flow_log_ids" {
  description = "VNet flow log IDs for sidecar virtual networks, keyed by region."
  value       = { for k, v in azurerm_network_watcher_flow_log.sidecar_vnet : k => v.id }
}

output "flow_logs_storage_account_ids" {
  description = "Flow logs storage account IDs, keyed by region."
  value       = { for k, v in module.flow_logs_storage : k => v.resource_id }
}

output "flow_logs_storage_account_names" {
  description = "Flow logs storage account names, keyed by region."
  value       = { for k, v in module.flow_logs_storage : k => v.name }
}
