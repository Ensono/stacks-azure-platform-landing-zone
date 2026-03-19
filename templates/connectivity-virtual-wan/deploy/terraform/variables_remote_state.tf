variable "management_remote_state" {
  type = object({
    enabled              = optional(bool, true)
    backend              = optional(string, "azurerm")
    workspace            = optional(string)
    storage_account_name = optional(string)
    container_name       = optional(string, "tfstate")
    key                  = optional(string, "management.tfstate")
    use_azuread_auth     = optional(bool, true)
  })
  default     = {}
  description = <<-DESCRIPTION
    Configuration for reading management landing zone state to get Log Analytics workspace ID.

    - `enabled` - (Optional) Enable remote state lookup. Default: `true`.
    - `backend` - (Optional) Backend type. Default: `azurerm`.
    - `storage_account_name` - (Required when enabled) Storage account name for state.
    - `container_name` - (Optional) Blob container name. Default: `tfstate`.
    - `key` - (Optional) State file key. Default: `management.tfstate`.
    - `workspace` - (Optional) Terraform workspace. Default: current workspace.
    - `use_azuread_auth` - (Optional) Use Entra ID auth. Default: `true`.
  DESCRIPTION

  validation {
    condition = (
      !var.management_remote_state.enabled ||
      var.management_remote_state.storage_account_name != null
    )
    error_message = "storage_account_name is required when management_remote_state is enabled."
  }
}
