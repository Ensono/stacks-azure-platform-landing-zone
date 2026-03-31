data "terraform_remote_state" "management" {
  count = var.management_remote_state.enabled ? 1 : 0

  backend   = var.management_remote_state.backend
  workspace = coalesce(var.management_remote_state.workspace, terraform.workspace)

  config = {
    storage_account_name = var.management_remote_state.storage_account_name
    container_name       = var.management_remote_state.container_name
    key                  = var.management_remote_state.key
    use_azuread_auth     = var.management_remote_state.use_azuread_auth
  }
}

locals {
  # Outputs from management landing zone remote state
  management_outputs = var.management_remote_state.enabled ? data.terraform_remote_state.management[0].outputs : {}

  # Log Analytics workspace ID - sourced from variable or remote state (used by diagnostics, AMPLS, traffic analytics)
  # Uses nested try() to handle missing keys in management_outputs safely
  log_analytics_workspace_id = try(
    coalesce(
      var.azure_monitor_private_link.log_analytics_workspace_id,
      try(local.management_outputs.log_analytics_workspace_id, null)
    ),
    null
  )

  # Log Analytics workspace GUID - from remote state (for Traffic Analytics)
  log_analytics_workspace_guid = try(local.management_outputs.log_analytics_workspace_guid, null)

  # Flow logs can only be enabled if storage account is available (created locally or provided externally)
  flow_logs_enabled = var.flow_logs.enabled && var.network_watcher.enabled && (
    var.flow_logs.storage.create || var.flow_logs.storage.external_storage_account_id != null
  )
}

resource "terraform_data" "validate_ampls_requirements" {
  count = var.azure_monitor_private_link.enabled ? 1 : 0

  lifecycle {
    precondition {
      condition     = local.log_analytics_workspace_id != null
      error_message = "AMPLS requires log_analytics_workspace_id. Set it directly or enable management_remote_state."
    }
  }
}

resource "terraform_data" "validate_flow_logs_requirements" {
  count = var.flow_logs.enabled ? 1 : 0

  lifecycle {
    precondition {
      condition     = var.flow_logs.storage.create || var.flow_logs.storage.external_storage_account_id != null
      error_message = "Flow logs require storage. Either set storage.create=true (default) or provide storage.external_storage_account_id."
    }

    precondition {
      condition     = !var.flow_logs.traffic_analytics_enabled || (local.log_analytics_workspace_id != null && local.log_analytics_workspace_guid != null)
      error_message = "Traffic Analytics requires Log Analytics workspace. Enable management_remote_state or ensure management module exports log_analytics_workspace_id and log_analytics_workspace_guid."
    }
  }
}
