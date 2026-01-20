# Single Region Deployment
# WARNING: Not recommended for production. Use multi-region for HA/DR.
# See ../../_header.md for more configuration examples.
#
# Required environment variable:
#   TF_VAR_connectivity_subscription_id=00000000-0000-0000-0000-000000000000

company_name = "ensono"

hubs = {
  uksouth = {}
}

# Azure Monitor Private Link Scope (enabled by default)
# Provide workspace ID directly, or use management_remote_state to fetch it
# azure_monitor_private_link = {
#   log_analytics_workspace_id = "/subscriptions/<subscription-id>/resourceGroups/<rg-name>/providers/Microsoft.OperationalInsights/workspaces/<workspace-name>"
# }

# Or use remote state to fetch workspace ID from management module (recommended)
# management_remote_state = {
#   enabled              = true
#   storage_account_name = "<storage-account-name>"
# }
