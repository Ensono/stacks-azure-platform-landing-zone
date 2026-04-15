module "resource_groups" {
  source  = "Azure/avm-res-resources-resourcegroup/azurerm"
  version = "0.2.1"

  count = var.management_resources_enabled ? 1 : 0

  enable_telemetry = var.enable_avm_telemetry
  location         = var.region
  lock = var.resource_group_lock_enabled ? {
    kind = "CanNotDelete"
    name = "CanNotDelete"
  } : null
  name = local.resource_names.resource_group
  tags = var.tags
}
