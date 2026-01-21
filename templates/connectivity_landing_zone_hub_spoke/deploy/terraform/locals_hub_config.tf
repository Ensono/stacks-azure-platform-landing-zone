locals {
  # Hub and spoke module settings
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

  # Auto-detect availability zones per hub region
  # Uses explicit override if provided, otherwise detects from region support
  hub_availability_zones = {
    for region, hub in local.enabled_hubs : region =>
    hub.features.availability_zones != null ? hub.features.availability_zones : (
      module.azure_regions.regions_by_name[region].zones != null
      ? [for z in module.azure_regions.regions_by_name[region].zones : tostring(z)]
      : null
    )
  }

  # Resource group IDs for hub networks
  hub_resource_group_ids = {
    for region in keys(local.enabled_hubs) : region =>
    "/subscriptions/${var.connectivity_subscription_id}/resourceGroups/${local.hub_names[region].resource_group}"
  }

  dns_resource_group_id = "/subscriptions/${var.connectivity_subscription_id}/resourceGroups/${module.naming["hub-dns"].resource_group.name}"

  # Hub virtual network configuration
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
        sku_tier                         = hub.features.firewall_sku
        zones                            = local.hub_availability_zones[region]

        default_ip_configuration = {
          public_ip_config = {
            name  = local.hub_names[region].firewall_pip
            zones = local.hub_availability_zones[region]
          }
        }

        management_ip_configuration = hub.features.firewall_management_ip ? {
          public_ip_config = {
            name  = local.hub_names[region].firewall_mgmt_pip
            zones = local.hub_availability_zones[region]
          }
        } : null
      } : null

      firewall_policy = hub.features.firewall ? {
        name = local.hub_names[region].firewall_policy
      } : null

      bastion = hub.features.bastion ? {
        name                  = local.hub_names[region].bastion
        subnet_address_prefix = local.hub_subnets[region].bastion
        zones                 = local.hub_availability_zones[region]
        bastion_public_ip = {
          name  = local.hub_names[region].bastion_pip
          zones = local.hub_availability_zones[region]
        }
      } : null

      virtual_network_gateways = (hub.features.vpn_gateway || hub.features.expressroute_gateway) ? {
        subnet_address_prefix = local.hub_subnets[region].gateway

        vpn = hub.features.vpn_gateway ? {
          name = local.hub_names[region].vpn_gateway
          ip_configurations = {
            active_active_1 = { public_ip = { name = local.hub_names[region].vpn_gateway_pip_1 } }
            active_active_2 = { public_ip = { name = local.hub_names[region].vpn_gateway_pip_2 } }
          }
        } : null

        express_route = hub.features.expressroute_gateway ? {
          name = local.hub_names[region].expressroute_gateway
          ip_configurations = {
            default = { public_ip = { name = local.hub_names[region].expressroute_gateway_pip } }
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
        resource_group_name   = module.naming["hub-dns"].resource_group.name
        subnet_address_prefix = local.hub_subnets[region].dns_resolver
      } : null
    }
  }
}
