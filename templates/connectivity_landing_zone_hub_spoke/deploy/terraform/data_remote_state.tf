data "terraform_remote_state" "management" {
  count = var.management_remote_state.enabled ? 1 : 0

  backend = var.management_remote_state.backend

  config = {
    storage_account_name = var.management_remote_state.storage_account_name
    container_name       = var.management_remote_state.container_name
    key                  = "${coalesce(var.management_remote_state.workspace, terraform.workspace)}/${var.management_remote_state.key}"
    use_azuread_auth     = var.management_remote_state.use_azuread_auth
  }
}

locals {
  # Outputs from management landing zone remote state
  management_outputs = var.management_remote_state.enabled ? data.terraform_remote_state.management[0].outputs : {}

  # Log Analytics workspace ID - sourced from variable or remote state
  log_analytics_workspace_id = var.azure_monitor_private_link.enabled ? coalesce(
    var.azure_monitor_private_link.log_analytics_workspace_id,
    try(local.management_outputs.log_analytics_workspace_id, null),
    ""
  ) : null

  # Log Analytics workspace GUID - extracted from workspace ID or remote state (for Traffic Analytics)
  log_analytics_workspace_guid = try(
    local.management_outputs.log_analytics_workspace_guid,
    null
  )

  # Flow logs storage account ID - sourced from variable or remote state
  # Storage account should be in management module for Azure Policy compatibility
  flow_logs_storage_account_id = (
    var.flow_logs.storage_account_id != null ? var.flow_logs.storage_account_id :
    try(local.management_outputs.flow_logs_storage_account_id, null)
  )

  # Flow logs can only be enabled if storage account is available
  flow_logs_enabled = var.flow_logs.enabled && var.network_watcher.enabled && local.flow_logs_storage_account_id != null
}

resource "terraform_data" "validate_ampls_requirements" {
  count = var.azure_monitor_private_link.enabled ? 1 : 0

  lifecycle {
    precondition {
      condition     = local.log_analytics_workspace_id != ""
      error_message = "AMPLS requires log_analytics_workspace_id. Set it directly or enable management_remote_state."
    }
  }
}

resource "terraform_data" "validate_flow_logs_requirements" {
  count = var.flow_logs.enabled ? 1 : 0

  lifecycle {
    precondition {
      condition     = local.flow_logs_storage_account_id != null
      error_message = "Flow logs require storage_account_id. Set it directly in flow_logs variable or enable management_remote_state (management module must export flow_logs_storage_account_id)."
    }
  }
}
