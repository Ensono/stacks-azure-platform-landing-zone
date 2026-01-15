# =============================================================================
# Resource Groups
# =============================================================================
#
# Creates resource groups for hub networks and shared resources.
#
# Resource groups created:
#   - hub-{region}: One per hub (e.g., hub-uksouth, hub-ukwest)
#   - dns: Shared Private DNS zones (in primary region)
#   - ddos: DDoS Protection Plan (in primary region, if enabled)
#
# The resource group configuration is built in locals.hubs.tf from var.hubs.
#
# =============================================================================

module "resource_groups" {
  source  = "Azure/avm-res-resources-resourcegroup/azurerm"
  version = "0.2.1"

  for_each = local.all_resource_groups

  name             = each.value.name
  location         = each.value.location
  enable_telemetry = var.enable_avm_telemetry
  tags             = each.value.tags
}

# -----------------------------------------------------------------------------
# Resource Group Locks
# -----------------------------------------------------------------------------
# Prevents accidental deletion of resource groups containing critical
# infrastructure. Disable locks during planned destruction operations.
#
resource "azurerm_management_lock" "resource_groups" {
  for_each = var.resource_group_lock_enabled ? local.all_resource_groups : {}

  name       = "CanNotDelete"
  scope      = module.resource_groups[each.key].resource_id
  lock_level = "CanNotDelete"
  notes      = "Prevents accidental deletion of connectivity infrastructure. Set resource_group_lock_enabled = false before destroying."
}
