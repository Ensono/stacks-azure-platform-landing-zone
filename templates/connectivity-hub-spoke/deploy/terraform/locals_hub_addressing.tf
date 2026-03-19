locals {
  # Hub address space allocation
  hub_addresses = {
    for region, hub in local.enabled_hubs : region => {
      hub_address_space = coalesce(
        hub.address_space,
        cidrsubnet(var.hub_network_address_prefix, 8, local.hub_indices[region])
      )
    }
  }

  # Hub subnet CIDR calculations
  hub_subnets = {
    for region, hub in local.enabled_hubs : region => {
      vnet_address_space = cidrsubnet(local.hub_addresses[region].hub_address_space, 6, 0)

      firewall = coalesce(
        hub.subnets.firewall_address_prefix,
        cidrsubnet(cidrsubnet(local.hub_addresses[region].hub_address_space, 6, 0), 4, 0)
      )

      bastion = coalesce(
        hub.subnets.bastion_address_prefix,
        cidrsubnet(cidrsubnet(local.hub_addresses[region].hub_address_space, 6, 0), 4, 1)
      )

      private_endpoints = coalesce(
        hub.subnets.private_endpoints_address_prefix,
        cidrsubnet(cidrsubnet(local.hub_addresses[region].hub_address_space, 6, 0), 4, 2)
      )

      firewall_management = coalesce(
        hub.subnets.firewall_management_address_prefix,
        cidrsubnet(cidrsubnet(local.hub_addresses[region].hub_address_space, 6, 0), 4, 3)
      )

      gateway = coalesce(
        hub.subnets.gateway_address_prefix,
        cidrsubnet(cidrsubnet(local.hub_addresses[region].hub_address_space, 6, 0), 5, 8)
      )

      dns_resolver = coalesce(
        hub.subnets.private_dns_resolver_address_prefix,
        cidrsubnet(cidrsubnet(local.hub_addresses[region].hub_address_space, 6, 0), 6, 18)
      )
    }
  }
}
