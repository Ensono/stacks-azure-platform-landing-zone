locals {
  resource_groups = var.management_resources_enabled ? {
    management = {
      location = var.location
      name     = local.resource_names.resource_group
      tags     = var.tags
    }
  } : {}
}
