# Management Groups (includes Management Resources)
# =================================================
# Deploys: Management Groups, Policies, Log Analytics, DCRs, Identity
#
# Policy default values are computed from management_resources outputs.
# Subscription placement is computed from subscription variables.

company_name = "ensono"
location     = "uksouth"

# Required Platform Subscriptions (per CAF)
management_subscription_id   = "00000000-0000-0000-0000-000000000000"
connectivity_subscription_id = "11111111-1111-1111-1111-111111111111"
identity_subscription_id     = "22222222-2222-2222-2222-222222222222"

# Optional: Security subscription
# security_subscription_id = "33333333-3333-3333-3333-333333333333"

# Enable management groups
management_groups_enabled = true

# Management Group Settings
# - Omit parent_management_group_id to deploy under the tenant root group
# - Or provide just the management group name/ID (not the full resource ID)
management_group_settings = {
  # parent_management_group_id = "existing-mg-name"  # Optional: defaults to tenant root group
}
