# Build an implicit dependency on the resource groups
locals {
  resource_groups = {
    resource_groups = module.resource_groups
  }
}

# Merge connectivity settings with config module outputs
locals {
  hub_and_spoke_networks_settings = merge(module.config.outputs.hub_and_spoke_networks_settings, local.resource_groups)
  hub_virtual_networks            = (merge({ vnets = module.config.outputs.hub_virtual_networks }, local.resource_groups)).vnets
}
