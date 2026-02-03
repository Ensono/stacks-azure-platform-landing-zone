module "resource_groups" {
  source  = "Azure/avm-res-resources-resourcegroup/azurerm"
  version = "0.2.1"

  for_each = local.all_resource_groups

  enable_telemetry = var.enable_avm_telemetry
  location         = each.value.location
  lock = var.resource_group_lock_enabled ? {
    kind = "CanNotDelete"
    name = "CanNotDelete"
  } : null
  name = each.value.name
  tags = each.value.tags
}
