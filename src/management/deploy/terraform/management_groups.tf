# Validate required subscriptions when management groups are enabled (skip if skip_subscription_placement = true)
resource "terraform_data" "validate_subscriptions" {
  count = var.management_groups_enabled && !var.skip_subscription_placement ? 1 : 0

  lifecycle {
    precondition {
      condition     = var.connectivity_subscription_id != null
      error_message = "connectivity_subscription_id is required when management_groups_enabled = true. Set skip_subscription_placement = true to skip this check."
    }
  }
}

# Validate required settings when management groups are enabled
resource "terraform_data" "validate_defender_settings" {
  count = var.management_groups_enabled ? 1 : 0

  lifecycle {
    precondition {
      condition     = var.microsoft_defender_settings != null
      error_message = "microsoft_defender_settings is required when management_groups_enabled = true."
    }
  }
}

module "management_groups" {
  source  = "Azure/avm-ptn-alz/azurerm"
  version = "0.18.0"

  count = var.management_groups_enabled ? 1 : 0

  # Required attributes
  architecture_name  = try(var.management_group_settings.architecture_name, "alz_custom")
  location           = coalesce(try(var.management_group_settings.location, null), var.region)
  parent_resource_id = local.parent_management_group_id

  # Computed attributes
  enable_telemetry             = var.enable_avm_telemetry
  policy_assignments_to_modify = local.policy_assignments_to_modify
  policy_default_values        = local.policy_default_values
  subscription_placement       = local.subscription_placement
}
