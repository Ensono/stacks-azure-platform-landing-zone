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
