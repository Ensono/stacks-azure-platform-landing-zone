# Naming module configuration
# - Deterministic: Use .name output (instances with static_suffix = true)
# - Unique: Use .name_unique output (instances with static_suffix = false)

# Random seed for uniqueness (generated once, stored in state)
resource "random_string" "unique_seed" {
  length  = 3
  special = false
  upper   = false
  numeric = false
}

module "naming" {
  source   = "Azure/naming/azurerm"
  version  = "0.4.3"
  for_each = local.naming_instances

  suffix = concat(
    [
      substr(var.company_name, 0, 3),
      module.azure_regions.regions_by_name[var.location].geo_code,
      terraform.workspace,
      each.value.component
    ],
    each.value.static_suffix ? ["001"] : []
  )

  # Use random seed for name_unique outputs
  unique-seed = random_string.unique_seed.result
}
