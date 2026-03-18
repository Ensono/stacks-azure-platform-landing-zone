locals {
  # Virtual wan module settings
  virtual_wan_settings = {
    enabled_resources = {
      ddos_protection_plan = var.ddos_protection_plan.enabled
    }

    virtual_wan = {
      name                = local.virtual_wan_name
      location            = length(local.enabled_hubs) > 0 ? keys(local.enabled_hubs)[0] : null
      resource_group_name = length(local.enabled_hubs) > 0 ? local.all_resource_groups["vwan"].name : null
      type                = "Standard"
      tags                = var.tags
    }

    ddos_protection_plan = var.ddos_protection_plan.enabled ? {
      name                = coalesce(var.ddos_protection_plan.name, module.naming["hub-ddos"].network_ddos_protection_plan.name)
      location            = local.primary_hub_region
      resource_group_name = local.all_resource_groups["ddos"].name
      tags                = var.tags
    } : {}
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

  # Virtual hub configuration
  virtual_hubs = {
    for region, hub in local.enabled_hubs : region => {
      location = region

      enabled_resources = {
        firewall                              = hub.features.firewall
        firewall_policy                       = hub.features.firewall
        bastion                               = hub.features.bastion
        virtual_network_gateway_express_route = hub.features.expressroute_gateway
        virtual_network_gateway_vpn           = hub.features.vpn_gateway
        private_dns_zones                     = hub.features.private_dns_zones
        private_dns_resolver                  = hub.features.private_dns_resolver
        sidecar_virtual_network               = hub.features.sidecar_virtual_network
      }

      default_hub_address_space = local.hub_addresses[region].hub_address_space
      default_parent_id         = "/subscriptions/${var.connectivity_subscription_id}/resourceGroups/${local.hub_names[region].resource_group}"

      hub = {
        name                                   = local.hub_names[region].virtual_hub
        address_prefix                         = local.hub_addresses[region].virtual_hub_prefix
        sku                                    = hub.hub.sku
        hub_routing_preference                 = hub.hub.hub_routing_preference
        virtual_router_auto_scale_min_capacity = hub.hub.virtual_router_auto_scale_min_capacity
        tags                                   = merge(var.tags, hub.tags)
      }

      firewall = hub.features.firewall ? {
        name     = local.hub_names[region].firewall
        sku_name = "AZFW_Hub"
        sku_tier = hub.features.firewall_sku
        zones    = local.hub_availability_zones[region]
        tags     = merge(var.tags, hub.tags)
      } : null

      firewall_policy = hub.features.firewall ? {
        name = local.hub_names[region].firewall_policy
        sku  = hub.features.firewall_sku
        dns = hub.features.firewall_dns_proxy ? {
          proxy_enabled = true
          servers       = hub.dns.servers # Custom upstream DNS or null for Azure DNS
        } : null
        threat_intelligence_mode = hub.features.firewall_threat_intel_mode
        tags                     = merge(var.tags, hub.tags)
      } : null

      sidecar_virtual_network = hub.features.sidecar_virtual_network ? {
        name          = local.hub_names[region].sidecar_virtual_network
        address_space = [local.sidecar_subnets[region].sidecar_address_space]
        tags          = merge(var.tags, hub.tags)
        subnets = var.azure_monitor_private_link.enabled ? {
          private_endpoints = {
            name             = "snet-private-endpoints"
            address_prefixes = [local.sidecar_subnets[region].private_endpoints]
          }
        } : {}
      } : null

      bastion = hub.features.bastion ? {
        name                  = local.hub_names[region].bastion
        subnet_address_prefix = local.sidecar_subnets[region].bastion
        sku                   = "Standard"
        scale_units           = 2
        zones                 = local.hub_availability_zones[region] != null ? toset([for z in local.hub_availability_zones[region] : tostring(z)]) : null
        tags                  = merge(var.tags, hub.tags)
        bastion_public_ip = {
          name  = local.hub_names[region].bastion_pip
          zones = local.hub_availability_zones[region] != null ? toset([for z in local.hub_availability_zones[region] : tostring(z)]) : null
          tags  = merge(var.tags, hub.tags)
        }
      } : null

      virtual_network_gateways = (hub.features.vpn_gateway || hub.features.expressroute_gateway) ? {
        subnet_address_prefix = local.sidecar_subnets[region].gateway

        express_route = hub.features.expressroute_gateway ? {
          name        = local.hub_names[region].expressroute_gateway
          scale_units = 1
          tags        = merge(var.tags, hub.tags)
        } : null

        vpn = hub.features.vpn_gateway ? {
          name       = local.hub_names[region].vpn_gateway
          scale_unit = 1
          tags       = merge(var.tags, hub.tags)
        } : null
      } : null

      private_dns_zones = hub.features.private_dns_zones ? {
        auto_registration_zone_enabled = hub.dns.auto_registration_zone_name != null
        auto_registration_zone_name    = local.hub_names[region].auto_registration_zone
        tags                           = merge(var.tags, hub.tags)
      } : null

      private_dns_resolver = hub.features.private_dns_resolver ? {
        name                  = local.hub_names[region].dns_resolver
        resource_group_name   = module.naming["hub-dns"].resource_group.name
        subnet_address_prefix = local.sidecar_subnets[region].private_dns_resolver
        tags                  = merge(var.tags, hub.tags)
      } : null
    }
  }
}
