variable "company" {
  type        = string
  description = "Company name used in resource naming. The first 3 characters are used as a prefix (e.g., 'ensono' becomes 'ens')."
}

variable "enable_avm_telemetry" {
  type        = bool
  default     = false
  description = "Enable telemetry collection for Azure Verified Modules. See https://aka.ms/avm/telemetryinfo."
}

variable "region" {
  type        = string
  description = "Primary Azure region for management resources (e.g., 'uksouth')."

  validation {
    condition     = can(regex("^[a-z][a-z0-9]+$", var.region))
    error_message = "region must be a valid Azure region name (lowercase, no spaces)."
  }
}

variable "resource_group_lock_enabled" {
  type        = bool
  default     = true
  description = "Enable CanNotDelete lock on all resource groups. Set to false before running terraform destroy."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "(Optional) Tags applied to all resources."
}
