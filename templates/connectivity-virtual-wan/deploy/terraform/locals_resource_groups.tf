locals {
  hub_resource_groups = {
    for region, hub in local.enabled_hubs : "hub-${region}" => {
      name     = local.hub_names[region].resource_group
      location = region
      tags     = merge(var.tags, hub.tags)
    }
  }

  vwan_resource_group = length(local.enabled_hubs) > 0 ? {
    "vwan" = {
      name     = module.naming["vwan"].resource_group.name
      location = keys(local.enabled_hubs)[0]
      tags     = var.tags
    }
  } : {}

  dns_resource_group = anytrue([for h in local.enabled_hubs : h.features.private_dns_zones]) ? {
    dns = {
      name     = module.naming["hub-dns"].resource_group.name
      location = local.primary_hub_region
      tags     = var.tags
    }
  } : {}

  ddos_resource_group = var.ddos_protection_plan.enabled ? {
    ddos = {
      name     = module.naming["hub-ddos"].resource_group.name
      location = local.primary_hub_region
      tags     = var.tags
    }
  } : {}

  all_resource_groups = merge(
    local.hub_resource_groups,
    local.vwan_resource_group,
    local.dns_resource_group,
    local.ddos_resource_group
  )
}
