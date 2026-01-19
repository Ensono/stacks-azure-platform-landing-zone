variable "azure_monitor_private_link" {
  type = object({
    enabled                    = optional(bool, true)
    log_analytics_workspace_id = optional(string)
    ingestion_access_mode      = optional(string, "PrivateOnly")
    query_access_mode          = optional(string, "PrivateOnly")
    name                       = optional(string)
  })
  default     = {}
  description = "Azure Monitor Private Link Scope configuration for private connectivity to Log Analytics."

  # Note: log_analytics_workspace_id can also be sourced from management_remote_state

  validation {
    condition = (
      !var.azure_monitor_private_link.enabled ||
      can(regex("^/subscriptions/[^/]+/resourceGroups/[^/]+/providers/Microsoft.OperationalInsights/workspaces/[^/]+$",
        coalesce(var.azure_monitor_private_link.log_analytics_workspace_id, "/subscriptions/x/resourceGroups/x/providers/Microsoft.OperationalInsights/workspaces/x")
      ))
    )
    error_message = "log_analytics_workspace_id must be a valid Log Analytics workspace resource ID."
  }

  validation {
    condition = (
      !var.azure_monitor_private_link.enabled ||
      contains(["PrivateOnly", "Open"], var.azure_monitor_private_link.ingestion_access_mode)
    )
    error_message = "ingestion_access_mode must be 'PrivateOnly' or 'Open'."
  }

  validation {
    condition = (
      !var.azure_monitor_private_link.enabled ||
      contains(["PrivateOnly", "Open"], var.azure_monitor_private_link.query_access_mode)
    )
    error_message = "query_access_mode must be 'PrivateOnly' or 'Open'."
  }
}
