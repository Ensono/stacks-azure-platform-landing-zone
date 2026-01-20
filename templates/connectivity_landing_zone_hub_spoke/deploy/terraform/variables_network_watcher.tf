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
    storage_account_id        = optional(string, null)
  })
  default     = {}
  description = <<-EOT
    Flow logs configuration for network traffic analysis. Disabled by default.

    Requirements:
    - Storage account ID must be provided (via storage_account_id or management_remote_state)
    - Storage account should be in the management module for Azure Policy compatibility

    When enabled, creates:
    - VNet flow logs for each hub virtual network

    Optional:
    - Traffic Analytics (requires Log Analytics workspace via management_remote_state)

    Cost considerations:
    - Storage: ~£0.02/GB stored (~£15-50/month depending on traffic volume)
    - Traffic Analytics: Additional Log Analytics ingestion costs

    Note: Retention defaults to 90 days to meet security compliance requirements (CKV_AZURE_12).
  EOT

  validation {
    condition     = var.flow_logs.retention_days >= 90 && var.flow_logs.retention_days <= 365
    error_message = "retention_days must be between 90 and 365 (security compliance requirement)."
  }
}
