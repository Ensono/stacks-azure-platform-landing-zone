locals {
  naming_instances = merge(
    { for region in keys(local.enabled_hubs) : "hub-${region}" => {
      component = "hub"
      region    = region
    } },
    { for region in keys(local.enabled_hubs) : "hub-fw-${region}" => {
      component = "hub-fw"
      region    = region
    } },
    { for region in keys(local.enabled_hubs) : "hub-fw-mgmt-${region}" => {
      component = "hub-fw-mgmt"
      region    = region
    } },
    { for region in keys(local.enabled_hubs) : "hub-bas-${region}" => {
      component = "hub-bas"
      region    = region
    } },
    { for region in keys(local.enabled_hubs) : "hub-vpn-${region}" => {
      component = "hub-vpn"
      region    = region
    } },
    { for region in keys(local.enabled_hubs) : "hub-er-${region}" => {
      component = "hub-er"
      region    = region
    } },
    { for region in keys(local.enabled_hubs) : "hub-std-${region}" => {
      component = "hub-std"
      region    = region
    } },
    { for region in keys(local.enabled_hubs) : "hub-ampls-${region}" => {
      component = "hub-ampls"
      region    = region
    } },
    { "hub-dns" = {
      component = "hub-dns"
      region    = local.primary_hub_region
    } },
    { "hub-ddos" = {
      component = "hub-ddos"
      region    = local.primary_hub_region
    } }
  )
}

module "naming" {
  source   = "Azure/naming/azurerm"
  version  = "0.4.3"
  for_each = local.naming_instances

  suffix = [
    substr(var.company_name, 0, 3),
    module.azure_regions.regions_by_name[each.value.region].geo_code,
    terraform.workspace,
    each.value.component,
    "001"
  ]
}
