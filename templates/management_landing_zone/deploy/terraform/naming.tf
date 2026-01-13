# Azure Naming
# https://registry.terraform.io/modules/Azure/naming/azurerm/latest?tab=outputs

# [resource type]-[company short]-[region geo-code]-[environment]-[component name]-[numeric (3)]

module "naming_caf" {
  count   = var.naming_convention == "caf_azure" ? 1 : 0
  source  = "Azure/naming/azurerm"
  version = "0.4.2"

  suffix = [
    substr(var.company_name, 0, 3),
    module.config.starter_locations_short["starter_location_01_short"],
    terraform.workspace,
    var.component_name,
    "001"
  ]
}

# Stacks Foundation Azure
# https://github.com/Ensono/stacks-foundation-azure

# [resource type]-[company short]-[project short]-[region geo-code]-[environment]-[random-seed]

module "naming_stacks_foundation" {
  count  = var.naming_convention == "stacks_foundation_azure" ? 1 : 0
  source = "https://github.com/Ensono/stacks-foundation-azure/releases/download/v0.0.8/stacks-foundation-azure-0.0.8.zip"

  # Required due to possible module bug - outputs cannot be null
  outputs = jsonencode({ (var.company_name) = {} })

  company_name      = var.company_name
  location          = module.config.starter_locations_short["starter_location_01_short"]
  project           = [var.component_name]
  stage_name        = var.component_name
  environment       = terraform.workspace
  short_name_length = 3
}
