# =============================================================================
# Hub Configuration Locals
# =============================================================================
#
# This file transforms the user-friendly `var.hubs` input into the format
# required by the AVM hub-and-spoke module. It handles:
#
#   1. IP Address Calculation - Using cidrsubnet() for consistent allocation
#   2. Resource Naming - Incorporating region codes per CAF guidelines
#   3. Feature Flag Processing - Converting simple bools to module structure
#   4. Resource Group Configuration - One RG per hub plus shared DNS/DDoS
#
# Tags are managed in locals.tags.tf and accessed via local.tags.
#
# CUSTOMIZATION GUIDE:
# --------------------
# - To change subnet sizes: Modify the cidrsubnet() newbits parameter
# - To add new subnet types: Add entries to local.hub_subnet_config
# - To change naming: Modify local.hub_names
#
# =============================================================================

# -----------------------------------------------------------------------------
# Hub Index Mapping
# -----------------------------------------------------------------------------
# Create a stable index for each hub based on sorted region names.
# This ensures consistent IP allocation even if hubs are reordered in tfvars.
#
locals {
  # Sort hub keys for deterministic ordering
  hub_keys_sorted = sort(keys(var.hubs))

  # Map each hub to its index (used for IP address calculation)
  hub_indices = { for idx, key in local.hub_keys_sorted : key => idx }

  # Filter to only enabled hubs
  enabled_hubs = { for k, v in var.hubs : k => v if v.enabled }
}

# -----------------------------------------------------------------------------
# IP Address Calculation
# -----------------------------------------------------------------------------
# Uses cidrsubnet() to carve address spaces from the base prefix.
#
# Layout (default 10.0.0.0/8 base):
#   Hub 0 (e.g., uksouth): 10.0.0.0/16
#   Hub 1 (e.g., ukwest):  10.1.0.0/16
#
# Within each /16, a /22 is carved for the hub VNet, with subnets inside:
#   - Firewall:            /26 at offset 0
#   - Firewall Management: /26 at offset 3 (end of /22)
#   - Bastion:             /26 at offset 1
#   - Gateway:             /27 at offset 4
#   - DNS Resolver:        /28 at offset 10
#
# Visual layout of a /22 (1024 addresses):
# ┌─────────────────────────────────────────────────────────────────────────┐
# │ .0.0/26  │ .0.64/26 │ .0.128/27 │ .0.160/28 │ ... unused ... │ .0.192/26│
# │ Firewall │ Bastion  │ Gateway   │ DNS Resv  │                │ FW Mgmt  │
# └─────────────────────────────────────────────────────────────────────────┘
#
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

      # Subnet calculations (can be overridden per-hub)
      firewall = coalesce(
        hub.subnets.firewall_address_prefix,
        cidrsubnet(cidrsubnet(local.hub_addresses[region].hub_address_space, 6, 0), 4, 0) # /26
      )
      firewall_management = coalesce(
        hub.subnets.firewall_management_address_prefix,
        cidrsubnet(cidrsubnet(local.hub_addresses[region].hub_address_space, 6, 0), 4, 3) # /26 at end
      )
      bastion = coalesce(
        hub.subnets.bastion_address_prefix,
        cidrsubnet(cidrsubnet(local.hub_addresses[region].hub_address_space, 6, 0), 4, 1) # /26
      )
      gateway = coalesce(
        hub.subnets.gateway_address_prefix,
        cidrsubnet(cidrsubnet(local.hub_addresses[region].hub_address_space, 6, 0), 5, 4) # /27
      )
      dns_resolver = coalesce(
        hub.subnets.private_dns_resolver_address_prefix,
        cidrsubnet(cidrsubnet(local.hub_addresses[region].hub_address_space, 6, 0), 6, 10) # /28
      )
    }
  }
}

# -----------------------------------------------------------------------------
# Resource Naming
# -----------------------------------------------------------------------------
# Names include the region short code (e.g., "uks") per CAF best practices.
# Format: {type}-{company}-{region}-{environment}-{component}-{instance}
#
# The naming module provides standard Azure resource names. We look up
# resources by region key and use the appropriate resource type name.
#
locals {
  # Build resource names for each hub
  # Users can override any name via hub.name_overrides
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
        module.naming["hub-fw-${region}"].firewall.name
      )

      firewall_policy = coalesce(
        hub.name_overrides.firewall_policy,
        module.naming["hub-fw-${region}"].firewall_policy.name
      )

      firewall_pip = module.naming["hub-fw-${region}"].public_ip.name

      firewall_mgmt_pip = module.naming["hub-fw-mgmt-${region}"].public_ip.name

      bastion = coalesce(
        hub.name_overrides.bastion,
        module.naming["hub-${region}"].bastion_host.name
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

# -----------------------------------------------------------------------------
# Resource Groups
# -----------------------------------------------------------------------------
# Each hub gets its own resource group. Shared resources (DNS, DDoS) go in
# the first hub's region.
#
locals {
  # Primary hub region (first in sorted order) - hosts shared resources
  primary_hub_region = local.hub_keys_sorted[0]

  # Resource groups for hub VNets
  hub_resource_groups = {
    for region, hub in local.enabled_hubs : "hub-${region}" => {
      name     = local.hub_names[region].resource_group
      location = region
      tags     = merge(local.tags, hub.tags)
    }
  }

  # Shared DNS resource group (in primary region)
  # Only created if any hub has private_dns_zones enabled
  dns_resource_group = anytrue([for h in local.enabled_hubs : h.features.private_dns_zones]) ? {
    dns = {
      name     = module.naming["hub-dns"].resource_group.name
      location = local.primary_hub_region
      tags     = local.tags
    }
  } : {}

  # Shared DDoS resource group (in primary region)
  # Only created if var.ddos_protection_plan is enabled
  ddos_resource_group = var.ddos_protection_plan.enabled ? {
    ddos = {
      name     = module.naming["hub-ddos"].resource_group.name
      location = local.primary_hub_region
      tags     = local.tags
    }
  } : {}

  # All resource groups combined
  all_resource_groups = merge(
    local.hub_resource_groups,
    local.dns_resource_group,
    local.ddos_resource_group
  )
}

# -----------------------------------------------------------------------------
# Hub and Spoke Settings (Global/Shared)
# -----------------------------------------------------------------------------
# Settings that apply across all hubs, like DDoS protection plan.
#
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

    # Reference to resource groups (creates implicit dependency)
    resource_groups = module.resource_groups
  }
}

# -----------------------------------------------------------------------------
# Hub Virtual Networks Configuration
# -----------------------------------------------------------------------------
# Builds the configuration object expected by the AVM module.
#
# NOTE: We construct resource group IDs from known values rather than using
# module outputs. This enables azapi preflight validation during plan, which
# requires actual resource IDs (not "known after apply" placeholders).
#
locals {
  # Construct resource group IDs for preflight validation
  hub_resource_group_ids = {
    for region in keys(local.enabled_hubs) : region =>
    "/subscriptions/${var.connectivity_subscription_id}/resourceGroups/${local.hub_names[region].resource_group}"
  }
  dns_resource_group_id  = "/subscriptions/${var.connectivity_subscription_id}/resourceGroups/${module.naming["hub-dns"].resource_group.name}"
  ddos_resource_group_id = "/subscriptions/${var.connectivity_subscription_id}/resourceGroups/${module.naming["hub-ddos"].resource_group.name}"

  hub_virtual_networks = {
    for region, hub in local.enabled_hubs : region => {
      # Location and parent resource group
      location          = region
      default_parent_id = local.hub_resource_group_ids[region]

      # Feature toggles for the AVM module
      enabled_resources = {
        firewall                              = hub.features.firewall
        bastion                               = hub.features.bastion
        virtual_network_gateway_express_route = hub.features.expressroute_gateway
        virtual_network_gateway_vpn           = hub.features.vpn_gateway
        private_dns_zones                     = hub.features.private_dns_zones
        private_dns_resolver                  = hub.features.private_dns_resolver
      }

      # Virtual network configuration
      hub_virtual_network = {
        name                          = local.hub_names[region].virtual_network
        address_space                 = [local.hub_subnets[region].vnet_address_space]
        routing_address_space         = [local.hub_addresses[region].hub_address_space]
        mesh_peering_enabled          = length(local.enabled_hubs) > 1
        route_table_name_firewall     = local.hub_names[region].route_table_firewall
        route_table_name_user_subnets = local.hub_names[region].route_table_user
        subnets                       = hub.custom_subnets
      }

      # Firewall configuration
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

      # Firewall policy
      firewall_policy = hub.features.firewall ? {
        name = local.hub_names[region].firewall_policy
      } : null

      # Bastion configuration
      bastion = hub.features.bastion ? {
        name                  = local.hub_names[region].bastion
        subnet_address_prefix = local.hub_subnets[region].bastion
        zones                 = hub.features.availability_zones
        bastion_public_ip = {
          name  = local.hub_names[region].bastion_pip
          zones = hub.features.availability_zones
        }
      } : null

      # VPN and ExpressRoute gateways
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

      # Private DNS Zones configuration
      private_dns_zones = hub.features.private_dns_zones ? {
        parent_id = local.dns_resource_group_id
        private_link_private_dns_zones_regex_filter = {
          enabled = region != local.primary_hub_region # Only primary hub creates DNS zones
        }
        auto_registration_zone_enabled = hub.features.auto_registration_zone
        auto_registration_zone_name    = local.hub_names[region].auto_registration_zone
      } : null

      # Private DNS Resolver
      private_dns_resolver = hub.features.private_dns_resolver ? {
        name                  = local.hub_names[region].dns_resolver
        subnet_address_prefix = local.hub_subnets[region].dns_resolver
      } : null
    }
  }
}
