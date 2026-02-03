locals {
  # Hub address space allocation
  hub_addresses = {
    for region, hub in local.enabled_hubs : region => {
      hub_address_space = coalesce(
        hub.address_space,
        cidrsubnet(var.hub_network_address_prefix, 8, local.hub_indices[region])
      )
      virtual_hub_prefix = cidrsubnet(
        coalesce(hub.address_space, cidrsubnet(var.hub_network_address_prefix, 8, local.hub_indices[region])),
        7,
        0
      )
    }
  }

  # Sidecar VNet subnet CIDR calculations
  # Note: Virtual WAN uses a sidecar VNet for Bastion, Gateway, DNS resolver, and private endpoints
  # The Virtual Hub itself is managed and doesn't need explicit subnet definitions
  sidecar_subnets = {
    for region, hub in local.enabled_hubs : region => {
      sidecar_address_space = cidrsubnet(local.hub_addresses[region].hub_address_space, 6, 1)

      bastion = coalesce(
        hub.sidecar_subnets.bastion_address_prefix,
        cidrsubnet(cidrsubnet(local.hub_addresses[region].hub_address_space, 6, 1), 4, 0)
      )

      gateway = coalesce(
        hub.sidecar_subnets.gateway_address_prefix,
        cidrsubnet(cidrsubnet(local.hub_addresses[region].hub_address_space, 6, 1), 5, 2)
      )

      private_dns_resolver = coalesce(
        hub.sidecar_subnets.private_dns_resolver_address_prefix,
        cidrsubnet(cidrsubnet(local.hub_addresses[region].hub_address_space, 6, 1), 6, 12)
      )

      private_endpoints = coalesce(
        hub.sidecar_subnets.private_endpoints_address_prefix,
        cidrsubnet(cidrsubnet(local.hub_addresses[region].hub_address_space, 6, 1), 6, 13)
      )
    }
  }
}
