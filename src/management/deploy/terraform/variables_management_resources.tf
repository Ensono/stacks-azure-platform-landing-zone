variable "management_resources_enabled" {
  type        = bool
  default     = true
  description = <<DESCRIPTION
Enable or disable the deployment of management resources.

When set to `true`, management resources such as Log Analytics workspace, Data Collection Rules, and Managed Identities will be deployed according to the `management_resource_settings` variable.
When set to `false`, no management resources will be deployed.

DESCRIPTION
}

variable "management_resource_settings" {
  type = object({
    resource_group_name          = optional(string)
    log_analytics_workspace_name = optional(string)
    data_collection_rules = optional(object({
      change_tracking = optional(object({
        enabled  = optional(bool, true)
        name     = optional(string, "dcr-change-tracking")
        location = optional(string)
        tags     = optional(map(string))
      }), {})
      vm_insights = optional(object({
        enabled  = optional(bool, true)
        name     = optional(string, "dcr-vm-insights")
        location = optional(string)
        tags     = optional(map(string))
      }), {})
      defender_sql = optional(object({
        enabled                                                = optional(bool, false)
        name                                                   = optional(string, "dcr-defender-sql")
        location                                               = optional(string)
        tags                                                   = optional(map(string))
        enable_collection_of_sql_queries_for_security_research = optional(bool, false)
      }), {})
    }), {})
    log_analytics_solution_plans = optional(list(object({
      product   = string
      publisher = optional(string)
    })))
    log_analytics_workspace_allow_resource_only_permissions    = optional(bool, true)
    log_analytics_workspace_cmk_for_query_forced               = optional(bool)
    log_analytics_workspace_daily_quota_gb                     = optional(number, 10)
    log_analytics_workspace_internet_ingestion_enabled         = optional(bool, false)
    log_analytics_workspace_internet_query_enabled             = optional(bool, false)
    log_analytics_workspace_local_authentication_enabled       = optional(bool, false)
    log_analytics_workspace_reservation_capacity_in_gb_per_day = optional(number)
    log_analytics_workspace_retention_in_days                  = optional(number)
    log_analytics_workspace_sku                                = optional(string)
    tags                                                       = optional(map(string))
    timeouts = optional(object({
      data_collection_rule = optional(object({
        create = optional(string)
        delete = optional(string)
        update = optional(string)
        read   = optional(string)
      }))
    }), {})
    user_assigned_managed_identities = optional(object({
      ama = optional(object({
        enabled  = optional(bool, true)
        name     = optional(string, "uai-ama")
        location = optional(string)
        tags     = optional(map(string))
      }), {})
    }), {})
  })
  default     = {}
  description = <<DESCRIPTION
Configuration for Azure Landing Zone management resources including Log Analytics and monitoring solutions.

All settings are optional with sensible defaults. Set to `{}` to deploy with defaults.

Properties:
- `resource_group_name` - (Optional) Override the resource group name. Defaults to naming convention.
- `log_analytics_workspace_name` - (Optional) Override the Log Analytics workspace name. Defaults to naming convention.
- `data_collection_rules` - (Optional) Data collection rule configurations:
  - `change_tracking` - Change tracking DCR. Defaults to enabled.
  - `vm_insights` - VM insights DCR. Defaults to enabled.
  - `defender_sql` - Defender for SQL DCR. Defaults to disabled.
- `log_analytics_solution_plans` - (Optional) Solution plans to deploy to the workspace.
- `log_analytics_workspace_allow_resource_only_permissions` - (Optional) Allow resource-only permissions. Defaults to true.
- `log_analytics_workspace_cmk_for_query_forced` - (Optional) Force CMK for queries.
- `log_analytics_workspace_daily_quota_gb` - (Optional) Daily ingestion quota in GB. Defaults to 10. Set to `-1` for unlimited.
- `log_analytics_workspace_internet_ingestion_enabled` - (Optional) Enable internet ingestion. Defaults to false.
- `log_analytics_workspace_internet_query_enabled` - (Optional) Enable internet queries. Defaults to false.
- `log_analytics_workspace_local_authentication_enabled` - (Optional) Enable local authentication. Defaults to false.
- `log_analytics_workspace_reservation_capacity_in_gb_per_day` - (Optional) Reservation capacity for CapacityReservation SKU.
- `log_analytics_workspace_retention_in_days` - (Optional) Data retention period in days.
- `log_analytics_workspace_sku` - (Optional) Workspace SKU (PerGB2018 or CapacityReservation).
- `tags` - (Optional) Tags for management resources. Merged with root tags.
- `timeouts` - (Optional) Timeout configurations for data collection rules.
- `user_assigned_managed_identities` - (Optional) Managed identity for Azure Monitor Agent. Defaults to enabled.

**Reliability:** Log Analytics provides zone-redundant data storage in supported regions.
**Cost:** Use CapacityReservation SKU for 15-25% savings on 100+ GB/day workloads.

Details of the settings can be found in the module documentation at https://registry.terraform.io/modules/Azure/avm-ptn-alz-management
DESCRIPTION
}
