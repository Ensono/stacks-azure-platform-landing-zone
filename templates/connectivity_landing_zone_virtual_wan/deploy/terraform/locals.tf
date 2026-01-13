# Build an implicit dependency on the resource groups
locals {
  resource_groups = {
    resource_groups = module.resource_groups
  }
}

# Merge connectivity settings with config module outputs
locals {
  virtual_wan_settings = merge(module.config.outputs.virtual_wan_settings, local.resource_groups)
  virtual_hubs         = (merge({ vhubs = module.config.outputs.virtual_hubs }, local.resource_groups)).vhubs
}
