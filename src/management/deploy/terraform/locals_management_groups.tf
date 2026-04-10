locals {
  # Compute parent_management_group_id: use provided ID/name or default to tenant root group
  # The AVM module expects just the ID/name, not the full resource path
  # Note: We use azapi_client_config to ensure static/known values
  # at plan time, which is required for the AVM module's for_each expressions
  parent_management_group_id = coalesce(
    try(var.management_group_settings.parent_management_group_id, null),
    data.azapi_client_config.current.tenant_id
  )

  # When skip_subscription_placement = true, only place management subscription
  default_subscription_placement = var.skip_subscription_placement ? {
    management = {
      subscription_id       = var.management_subscription_id
      management_group_name = "management"
    }
    } : merge(
    var.connectivity_subscription_id != null ? {
      connectivity = {
        subscription_id       = var.connectivity_subscription_id
        management_group_name = "connectivity"
      }
    } : {},
    var.identity_subscription_id != null ? {
      identity = {
        subscription_id       = var.identity_subscription_id
        management_group_name = "identity"
      }
    } : {},
    {
      management = {
        subscription_id       = var.management_subscription_id
        management_group_name = "management"
      }
    },
    var.security_subscription_id != null ? {
      security = {
        subscription_id       = var.security_subscription_id
        management_group_name = "security"
      }
    } : {}
  )

  subscription_placement = try(coalesce(var.management_group_settings.subscription_placement, local.default_subscription_placement), local.default_subscription_placement)
}
