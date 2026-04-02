# Single Region Deployment
# WARNING: Not recommended for production. Use multi-region for HA/DR.
# See ../../README.md for more configuration examples.
#
# Required environment variable:
#   TF_VAR_connectivity_subscription_id=00000000-0000-0000-0000-000000000000

company = "ensono"

hubs = {
  uksouth = {}
}

# Azure Monitor Private Link Scope (enabled by default)
# Use remote state to fetch workspace ID from management module
# management_remote_state = {
#   storage_account_name = "<storage-account-name>"
# }
