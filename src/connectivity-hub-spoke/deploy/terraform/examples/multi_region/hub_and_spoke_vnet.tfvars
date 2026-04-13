# Multi-Region Deployment
# See ../../README.md for more configuration examples.

company                      = "ensono"
connectivity_subscription_id = "00000000-0000-0000-0000-000000000000"

hubs = {
  uksouth = {}
  ukwest  = {}
}

# Azure Monitor Private Link Scope (enabled by default)
# Use remote state to fetch workspace ID from management module
management_remote_state = {
  storage_account_name = "<storage-account-name>"
}
