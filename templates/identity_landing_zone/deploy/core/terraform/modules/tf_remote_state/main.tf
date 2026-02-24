data "terraform_remote_state" "remote_states" {
  for_each = var.remote_state_configs

  backend   = "azurerm"
  workspace = var.workspace_name
  config = {
    storage_account_name = each.value.storage_account_name
    container_name       = each.value.container_name
    key                  = each.value.key
    use_azuread_auth     = each.value.use_azuread_auth
  }
}
