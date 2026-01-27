locals {
  # Naming instances for module.naming
  naming_instances = merge(
    { for region in keys(local.enabled_hubs) : "hub-${region}" => { component = "hub", region = region } },
    { for region in keys(local.enabled_hubs) : "hub-fw-${region}" => { component = "hub-fw", region = region } },
    { for region in keys(local.enabled_hubs) : "hub-fw-mgmt-${region}" => { component = "hub-fw-mgmt", region = region } },
    { for region in keys(local.enabled_hubs) : "hub-bas-${region}" => { component = "hub-bas", region = region } },
    { for region in keys(local.enabled_hubs) : "hub-vpn-${region}" => { component = "hub-vpn", region = region } },
    { for region in keys(local.enabled_hubs) : "hub-er-${region}" => { component = "hub-er", region = region } },
    { for region in keys(local.enabled_hubs) : "hub-std-${region}" => { component = "hub-std", region = region } },
    { for region in keys(local.enabled_hubs) : "hub-ampls-${region}" => { component = "hub-ampls", region = region } },
    { for region in keys(local.enabled_hubs) : "hub-dns-${region}" => { component = "hub-dns", region = region } },
    { for region in keys(local.enabled_hubs) : "hub-fl-${region}" => { component = "hub-fl", region = region } },
    { "hub-dns" = { component = "hub-dns", region = local.primary_hub_region } },
    { "hub-ddos" = { component = "hub-ddos", region = local.primary_hub_region } }
  )

  # CAF prefixes for resource types not in Azure/naming module
  caf_prefixes = {
    ampls    = "ampls"
    bastion  = "bas"
    firewall = "afw"
  }

  # Extended naming with CAF prefixes for resources not covered by naming module
  naming_extended = {
    for key, instance in local.naming_instances : key => merge(
      module.naming[key],
      {
        azure_monitor_private_link_scope = {
          name = replace(module.naming[key].resource_group.name, "/^rg-/", "${local.caf_prefixes.ampls}-")
        }
        bastion_host = {
          name = replace(module.naming[key].resource_group.name, "/^rg-/", "${local.caf_prefixes.bastion}-")
        }
        firewall = {
          name = replace(module.naming[key].resource_group.name, "/^rg-/", "${local.caf_prefixes.firewall}-")
        }
      }
    )
  }

  # Hub resource names with coalesce for name overrides
  hub_names = {
    for region, hub in local.enabled_hubs : region => {
      resource_group  = coalesce(hub.name_overrides.resource_group, module.naming["hub-${region}"].resource_group.name)
      virtual_network = coalesce(hub.name_overrides.virtual_network, module.naming["hub-${region}"].virtual_network.name)

      firewall          = coalesce(hub.name_overrides.firewall, local.naming_extended["hub-${region}"].firewall.name)
      firewall_policy   = coalesce(hub.name_overrides.firewall_policy, module.naming["hub-${region}"].firewall_policy.name)
      firewall_pip      = module.naming["hub-fw-${region}"].public_ip.name
      firewall_mgmt_pip = module.naming["hub-fw-mgmt-${region}"].public_ip.name

      bastion     = coalesce(hub.name_overrides.bastion, local.naming_extended["hub-${region}"].bastion_host.name)
      bastion_pip = module.naming["hub-bas-${region}"].public_ip.name

      vpn_gateway       = coalesce(hub.name_overrides.vpn_gateway, module.naming["hub-vpn-${region}"].virtual_network_gateway.name)
      vpn_gateway_pip_1 = "${module.naming["hub-vpn-${region}"].public_ip.name}-001"
      vpn_gateway_pip_2 = "${module.naming["hub-vpn-${region}"].public_ip.name}-002"

      expressroute_gateway     = coalesce(hub.name_overrides.expressroute_gateway, module.naming["hub-er-${region}"].virtual_network_gateway.name)
      expressroute_gateway_pip = module.naming["hub-er-${region}"].public_ip.name

      dns_resolver           = coalesce(hub.name_overrides.private_dns_resolver, module.naming["hub-dns-${region}"].dns_private_resolver.name)
      auto_registration_zone = coalesce(hub.dns.auto_registration_zone_name, "${region}.azure.local")

      route_table_firewall = coalesce(hub.name_overrides.route_table_firewall, module.naming["hub-fw-${region}"].route_table.name)
      route_table_user     = coalesce(hub.name_overrides.route_table_user, module.naming["hub-std-${region}"].route_table.name)

      # Flow logs storage account - uses name_unique for global uniqueness
      flow_logs_storage = module.naming["hub-fl-${region}"].storage_account.name_unique
    }
  }
}
