# Hub Index Mapping - stable index for IP allocation
locals {
  # Sort hub keys for deterministic ordering
  hub_keys_sorted = sort(keys(var.hubs))

  # Map each hub to its index (used for IP address calculation)
  hub_indices = { for idx, key in local.hub_keys_sorted : key => idx }

  # Filter to only enabled hubs
  enabled_hubs = { for k, v in var.hubs : k => v if v.enabled }
}

# IP Address Calculation
locals {
  hub_addresses = {
    for region, hub in local.enabled_hubs : region => {
      # Hub's /16 address space (or user override)
      hub_address_space = coalesce(
        hub.address_space,
        cidrsubnet(var.hub_network_address_prefix, 8, local.hub_indices[region])
      )
    }
  }

  # Calculate subnet addresses for each hub
  hub_subnets = {
    for region, hub in local.enabled_hubs : region => {
      # VNet gets a /22 from the hub's /16
      vnet_address_space = cidrsubnet(local.hub_addresses[region].hub_address_space, 6, 0)

      # Subnet allocations from /22 VNet (16 x /26 slots available)
      # Slot 0: AzureFirewallSubnet /26
      # Slot 1: AzureBastionSubnet /26
      # Slot 2: snet-private-endpoints /26
      # Slot 3: AzureFirewallManagementSubnet /26
      # Slot 4: GatewaySubnet /27 + dns-resolver /28 (split)

      firewall = coalesce(
        hub.subnets.firewall_address_prefix,
        cidrsubnet(cidrsubnet(local.hub_addresses[region].hub_address_space, 6, 0), 4, 0) # Slot 0 /26
      )
      bastion = coalesce(
        hub.subnets.bastion_address_prefix,
        cidrsubnet(cidrsubnet(local.hub_addresses[region].hub_address_space, 6, 0), 4, 1) # Slot 1 /26
      )
      private_endpoints = coalesce(
        hub.subnets.private_endpoints_address_prefix,
        cidrsubnet(cidrsubnet(local.hub_addresses[region].hub_address_space, 6, 0), 4, 2) # Slot 2 /26
      )
      firewall_management = coalesce(
        hub.subnets.firewall_management_address_prefix,
        cidrsubnet(cidrsubnet(local.hub_addresses[region].hub_address_space, 6, 0), 4, 3) # Slot 3 /26
      )
      gateway = coalesce(
        hub.subnets.gateway_address_prefix,
        cidrsubnet(cidrsubnet(local.hub_addresses[region].hub_address_space, 6, 0), 5, 8) # Slot 4 first half /27
      )
      dns_resolver = coalesce(
        hub.subnets.private_dns_resolver_address_prefix,
        cidrsubnet(cidrsubnet(local.hub_addresses[region].hub_address_space, 6, 0), 6, 18) # Slot 4 second half /28
      )
    }
  }
}

# Extended Naming - adds missing/corrected resource types to naming module output
# See: https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/resource-abbreviations
locals {
  # CAF prefixes not supported or incorrect in the naming module
  caf_prefixes = {
    ampls   = "ampls" # not supported by naming module
    bastion = "bas"   # naming module incorrectly uses "snap"
  }

  # Extend each naming instance with missing resource types
  # Uses resource_group name as base, replacing prefix with correct CAF abbreviation
  naming_extended = {
    for key, instance in local.naming_instances : key => merge(
      module.naming[key],
      {
        azure_monitor_private_link_scope = {
          name = replace(
            module.naming[key].resource_group.name,
            "/^rg-/",
            "${local.caf_prefixes.ampls}-"
          )
        }
        bastion_host_fixed = {
          name = replace(
            module.naming[key].resource_group.name,
            "/^rg-/",
            "${local.caf_prefixes.bastion}-"
          )
        }
      }
    )
  }
}

# Resource Naming
locals {
  hub_names = {
    for region, hub in local.enabled_hubs : region => {
      resource_group = coalesce(
        hub.name_overrides.resource_group,
        module.naming["hub-${region}"].resource_group.name
      )

      virtual_network = coalesce(
        hub.name_overrides.virtual_network,
        module.naming["hub-${region}"].virtual_network.name
      )

      firewall = coalesce(
        hub.name_overrides.firewall,
        module.naming["hub-${region}"].firewall.name
      )

      firewall_policy = coalesce(
        hub.name_overrides.firewall_policy,
        module.naming["hub-${region}"].firewall_policy.name
      )

      firewall_pip = module.naming["hub-fw-${region}"].public_ip.name

      firewall_mgmt_pip = module.naming["hub-fw-mgmt-${region}"].public_ip.name

      bastion = coalesce(
        hub.name_overrides.bastion,
        local.naming_extended["hub-${region}"].bastion_host_fixed.name
      )

      bastion_pip = module.naming["hub-bas-${region}"].public_ip.name

      vpn_gateway = coalesce(
        hub.name_overrides.vpn_gateway,
        module.naming["hub-vpn-${region}"].virtual_network_gateway.name
      )

      vpn_gateway_pip_1 = "${module.naming["hub-vpn-${region}"].public_ip.name}-001"

      vpn_gateway_pip_2 = "${module.naming["hub-vpn-${region}"].public_ip.name}-002"

      expressroute_gateway = coalesce(
        hub.name_overrides.expressroute_gateway,
        module.naming["hub-er-${region}"].virtual_network_gateway.name
      )

      expressroute_gateway_pip = module.naming["hub-er-${region}"].public_ip.name

      dns_resolver = coalesce(
        hub.name_overrides.private_dns_resolver,
        module.naming["hub-dns"].dns_private_resolver.name
      )

      route_table_firewall = coalesce(
        hub.name_overrides.route_table_firewall,
        module.naming["hub-fw-${region}"].route_table.name
      )

      route_table_user = coalesce(
        hub.name_overrides.route_table_user,
        module.naming["hub-std-${region}"].route_table.name
      )

      auto_registration_zone = coalesce(
        hub.dns.auto_registration_zone_name,
        "${region}.azure.local"
      )
    }
  }
}

# Resource Groups
locals {
  primary_hub_region = local.hub_keys_sorted[0]

  hub_resource_groups = {
    for region, hub in local.enabled_hubs : "hub-${region}" => {
      name     = local.hub_names[region].resource_group
      location = region
      tags     = merge(local.tags, hub.tags)
    }
  }

  dns_resource_group = anytrue([for h in local.enabled_hubs : h.features.private_dns_zones]) ? {
    dns = {
      name     = module.naming["hub-dns"].resource_group.name
      location = local.primary_hub_region
      tags     = local.tags
    }
  } : {}

  ddos_resource_group = var.ddos_protection_plan.enabled ? {
    ddos = {
      name     = module.naming["hub-ddos"].resource_group.name
      location = local.primary_hub_region
      tags     = local.tags
    }
  } : {}

  all_resource_groups = merge(
    local.hub_resource_groups,
    local.dns_resource_group,
    local.ddos_resource_group
  )
}

# Hub and Spoke Settings
locals {
  hub_and_spoke_settings = {
    enabled_resources = {
      ddos_protection_plan = var.ddos_protection_plan.enabled
    }

    ddos_protection_plan = var.ddos_protection_plan.enabled ? {
      name                = coalesce(var.ddos_protection_plan.name, module.naming["hub-ddos"].network_ddos_protection_plan.name)
      location            = local.primary_hub_region
      resource_group_name = local.all_resource_groups["ddos"].name
    } : {}

    resource_groups = module.resource_groups
  }
}

# Hub Virtual Networks Configuration
# Resource group IDs are constructed from known values for azapi preflight validation
locals {
  hub_resource_group_ids = {
    for region in keys(local.enabled_hubs) : region =>
    "/subscriptions/${var.connectivity_subscription_id}/resourceGroups/${local.hub_names[region].resource_group}"
  }
  dns_resource_group_id = "/subscriptions/${var.connectivity_subscription_id}/resourceGroups/${module.naming["hub-dns"].resource_group.name}"

  hub_virtual_networks = {
    for region, hub in local.enabled_hubs : region => {
      location          = region
      default_parent_id = local.hub_resource_group_ids[region]

      enabled_resources = {
        firewall                              = hub.features.firewall
        bastion                               = hub.features.bastion
        virtual_network_gateway_express_route = hub.features.expressroute_gateway
        virtual_network_gateway_vpn           = hub.features.vpn_gateway
        private_dns_zones                     = hub.features.private_dns_zones
        private_dns_resolver                  = hub.features.private_dns_resolver
      }

      hub_virtual_network = {
        name                          = local.hub_names[region].virtual_network
        address_space                 = [local.hub_subnets[region].vnet_address_space]
        routing_address_space         = [local.hub_addresses[region].hub_address_space]
        mesh_peering_enabled          = length(local.enabled_hubs) > 1
        route_table_name_firewall     = local.hub_names[region].route_table_firewall
        route_table_name_user_subnets = local.hub_names[region].route_table_user
        subnets = merge(
          hub.custom_subnets,
          {
            private_endpoints = {
              name                              = "snet-private-endpoints"
              address_prefixes                  = [local.hub_subnets[region].private_endpoints]
              private_endpoint_network_policies = "Enabled"
            }
          }
        )
      }

      firewall = hub.features.firewall ? {
        name                             = local.hub_names[region].firewall
        subnet_address_prefix            = local.hub_subnets[region].firewall
        management_subnet_address_prefix = local.hub_subnets[region].firewall_management
        management_ip_enabled            = hub.features.firewall_management_ip
        sku_tier                         = "Standard"
        zones                            = hub.features.availability_zones

        default_ip_configuration = {
          public_ip_config = {
            name  = local.hub_names[region].firewall_pip
            zones = hub.features.availability_zones
          }
        }

        management_ip_configuration = hub.features.firewall_management_ip ? {
          public_ip_config = {
            name  = local.hub_names[region].firewall_mgmt_pip
            zones = hub.features.availability_zones
          }
        } : null
      } : null

      firewall_policy = hub.features.firewall ? {
        name = local.hub_names[region].firewall_policy
      } : null

      bastion = hub.features.bastion ? {
        name                  = local.hub_names[region].bastion
        subnet_address_prefix = local.hub_subnets[region].bastion
        zones                 = hub.features.availability_zones
        bastion_public_ip = {
          name  = local.hub_names[region].bastion_pip
          zones = hub.features.availability_zones
        }
      } : null

      virtual_network_gateways = (hub.features.vpn_gateway || hub.features.expressroute_gateway) ? {
        subnet_address_prefix = local.hub_subnets[region].gateway

        vpn = hub.features.vpn_gateway ? {
          name = local.hub_names[region].vpn_gateway
          ip_configurations = {
            active_active_1 = {
              public_ip = {
                name = local.hub_names[region].vpn_gateway_pip_1
              }
            }
            active_active_2 = {
              public_ip = {
                name = local.hub_names[region].vpn_gateway_pip_2
              }
            }
          }
        } : null

        express_route = hub.features.expressroute_gateway ? {
          name = local.hub_names[region].expressroute_gateway
          ip_configurations = {
            default = {
              public_ip = {
                name = local.hub_names[region].expressroute_gateway_pip
              }
            }
          }
        } : null
      } : null

      private_dns_zones = hub.features.private_dns_zones ? {
        parent_id = local.dns_resource_group_id
        private_link_private_dns_zones_regex_filter = {
          enabled = region != local.primary_hub_region
        }
        auto_registration_zone_enabled = hub.features.auto_registration_zone
        auto_registration_zone_name    = local.hub_names[region].auto_registration_zone
      } : null

      private_dns_resolver = hub.features.private_dns_resolver ? {
        name                  = local.hub_names[region].dns_resolver
        subnet_address_prefix = local.hub_subnets[region].dns_resolver
      } : null
    }
  }
}
