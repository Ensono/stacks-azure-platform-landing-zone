variable "management_remote_state" {
  description = "Configuration for fetching management landing zone outputs via remote state."
  type = object({
    enabled              = optional(bool, false)
    backend              = optional(string, "azurerm")
    workspace            = optional(string, null)
    storage_account_name = optional(string, null)
    container_name       = optional(string, "tfstate")
    key                  = optional(string, "management.tfstate")
    use_azuread_auth     = optional(bool, true)
  })
  default = {
    enabled = false
  }

  validation {
    condition = (
      !var.management_remote_state.enabled ||
      var.management_remote_state.storage_account_name != null
    )
    error_message = "storage_account_name is required when management_remote_state is enabled."
  }
}
