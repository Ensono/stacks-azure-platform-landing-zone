variable "network_watcher" {
  type = object({
    enabled = optional(bool, true)
  })
  default     = {}
  description = "Network Watcher configuration. Network Watcher is free and provides network diagnostics capabilities."
}

variable "flow_logs" {
  type = object({
    enabled                   = optional(bool, false)
    retention_days            = optional(number, 90)
    traffic_analytics_enabled = optional(bool, false)
    storage = optional(object({
      create                        = optional(bool, true)
      external_storage_account_id   = optional(string, null)
      access_tier                   = optional(string, "Hot")
      account_kind                  = optional(string, "StorageV2")
      account_replication_type      = optional(string, "GRS")
      account_tier                  = optional(string, "Standard") # Premium not supported
      min_tls_version               = optional(string, "TLS1_2")
      public_network_access         = optional(bool, false)
      shared_access_key_enabled     = optional(bool, true)
      retention_days                = optional(number, 30) # Blob lifecycle
      network_rules = optional(object({
        ip_rules                   = optional(list(string), [])
        virtual_network_subnet_ids = optional(list(string), [])
      }), {})
    }), {})
  })
  default     = {}
  description = <<DESCRIPTION
    Flow logs configuration for network traffic analysis. Disabled by default.

    Per Microsoft documentation, the storage account MUST be in the same region as the VNet.
    This module creates a storage account per hub region to ensure compliance.

    When enabled, creates:
    - Storage account per hub region
    - VNet flow logs for each hub virtual network

    Storage options:
    - create: Set to true (default) to create storage accounts
    - external_storage_account_id: If create=false, provide an existing storage account ID
      (must be in same region as hub VNet)

    Optional:
    - Traffic Analytics (requires Log Analytics workspace via management_remote_state)

    Cost considerations:
    - Storage: ~£0.02/GB stored (~£15-50/month depending on traffic volume)
    - Traffic Analytics: Additional Log Analytics ingestion costs

    Note: Retention defaults to 90 days to meet security compliance requirements (CKV_AZURE_12).
  DESCRIPTION

  validation {
    condition     = var.flow_logs.retention_days >= 90 && var.flow_logs.retention_days <= 365
    error_message = "retention_days must be between 90 and 365 (security compliance requirement)."
  }

  validation {
    condition     = var.flow_logs.storage.create || var.flow_logs.storage.external_storage_account_id != null || !var.flow_logs.enabled
    error_message = "When flow_logs.enabled=true and storage.create=false, external_storage_account_id must be provided."
  }
}
