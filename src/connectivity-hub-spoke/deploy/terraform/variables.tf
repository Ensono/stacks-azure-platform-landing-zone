variable "company" {
  type        = string
  description = "Company name used in resource naming. The first 3 characters are used as a prefix (e.g., 'ensono' becomes 'ens')."
}

variable "connectivity_subscription_id" {
  type        = string
  description = "Subscription ID for connectivity resources (hub networks, firewalls, DNS)."

  validation {
    condition     = can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.connectivity_subscription_id))
    error_message = "Subscription ID must be a valid GUID."
  }
}

variable "enable_avm_telemetry" {
  type        = bool
  description = "Enable telemetry collection for Azure Verified Modules. See https://aka.ms/avm/telemetryinfo."
  default     = false
}

variable "resource_group_lock_enabled" {
  type        = bool
  description = "Enable CanNotDelete locks on all resource groups. Set to false before running terraform destroy."
  default     = true
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags applied to all resources."
}
