variable "flow_logs_storage" {
  description = "Storage account configuration for VNet flow logs. Used by connectivity module."
  type = object({
    enabled                   = optional(bool, true)
    name                      = optional(string)
    account_tier              = optional(string, "Standard")
    account_replication_type  = optional(string, "GZRS")
    account_kind              = optional(string, "StorageV2")
    access_tier               = optional(string, "Cool")
    min_tls_version           = optional(string, "TLS1_2")
    public_network_access     = optional(bool, false)
    retention_days            = optional(number, 30)
    shared_access_key_enabled = optional(bool, false)
    tags                      = optional(map(string), {})

    # Network rules - default to deny all when public_network_access is false
    network_rules = optional(object({
      default_action             = optional(string, "Deny")
      bypass                     = optional(list(string), ["AzureServices"])
      ip_rules                   = optional(list(string), [])
      virtual_network_subnet_ids = optional(list(string), [])
    }), {})
  })
  default = {
    enabled = true
  }

  validation {
    condition = (
      !var.flow_logs_storage.enabled ||
      contains(["Standard", "Premium"], var.flow_logs_storage.account_tier)
    )
    error_message = "account_tier must be 'Standard' or 'Premium'."
  }

  validation {
    condition = (
      !var.flow_logs_storage.enabled ||
      contains(["Hot", "Cool"], var.flow_logs_storage.access_tier)
    )
    error_message = "access_tier must be 'Hot' or 'Cool'."
  }

  validation {
    condition = (
      !var.flow_logs_storage.enabled ||
      contains(["LRS", "GRS", "RAGRS", "ZRS", "GZRS", "RAGZRS"], var.flow_logs_storage.account_replication_type)
    )
    error_message = "account_replication_type must be one of: LRS, GRS, RAGRS, ZRS, GZRS, RAGZRS."
  }

  validation {
    condition = (
      !var.flow_logs_storage.enabled ||
      var.flow_logs_storage.retention_days >= 1 && var.flow_logs_storage.retention_days <= 365
    )
    error_message = "retention_days must be between 1 and 365."
  }
}
