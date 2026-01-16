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
  management_outputs = var.management_remote_state.enabled ? data.terraform_remote_state.management[0].outputs : {}

  log_analytics_workspace_id = coalesce(
    var.azure_monitor_private_link.log_analytics_workspace_id,
    try(local.management_outputs.log_analytics_workspace_id, null)
  )
}
