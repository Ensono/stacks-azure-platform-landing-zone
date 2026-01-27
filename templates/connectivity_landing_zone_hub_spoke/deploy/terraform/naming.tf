# Create a random string that is used when generating names of the resources
resource "random_string" "random_seed" {
  length  = 3
  special = false
  upper   = false
  numeric = false
}

module "naming" {
  source   = "Azure/naming/azurerm"
  version  = "0.4.3"
  for_each = local.naming_instances

  unique-seed = random_string.random_seed.result

  suffix = [
    substr(var.company_name, 0, 3),
    module.azure_regions.regions_by_name[each.value.region].geo_code,
    terraform.workspace,
    each.value.component,
    "001"
  ]
}
