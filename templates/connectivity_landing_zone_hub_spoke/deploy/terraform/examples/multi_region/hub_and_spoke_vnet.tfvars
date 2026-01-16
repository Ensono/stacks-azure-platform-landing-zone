# Multi-Region Deployment
# See ../../_header.md for more configuration examples.

company_name = "ensono"
# connectivity_subscription_id = "00000000-0000-0000-0000-000000000000"

hubs = {
  uksouth = {}
  ukwest  = {}
}

ddos_protection_plan = {
  enabled = false
}

# Azure Monitor Private Link Scope
# Enables private connectivity to Log Analytics workspace
# azure_monitor_private_link = {
#   enabled                    = true
#   log_analytics_workspace_id = "/subscriptions/<subscription-id>/resourceGroups/<rg-name>/providers/Microsoft.OperationalInsights/workspaces/<workspace-name>"
# }

# Or use remote state to fetch workspace ID from management module
# management_remote_state = {
#   enabled              = true
#   storage_account_name = "<storage-account-name>"
# }
# azure_monitor_private_link = {
#   enabled = true
# }
