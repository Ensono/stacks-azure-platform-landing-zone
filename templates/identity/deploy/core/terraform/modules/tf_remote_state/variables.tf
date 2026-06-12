variable "remote_state_configs" {
  description = "Map of remote state configurations by region/environment"
  type = map(object({
    storage_account_name = string
    container_name       = string
    key                  = string
    use_azuread_auth     = bool
  }))
}

variable "workspace_name" {
  description = "The Terraform workspace name to use for remote state lookups"
  type        = string
}
