# Management Groups (includes Management Resources)
# =================================================
# Deploys: Management Groups, Policies, Log Analytics, DCRs, Identity
#
# Policy default values are computed from management_resources outputs.
# Subscription placement is computed from subscription variables.

company_name = "ensono"
location     = "uksouth"

# Required Platform Subscriptions
management_subscription_id   = "00000000-0000-0000-0000-000000000000"
connectivity_subscription_id = "11111111-1111-1111-1111-111111111111"
identity_subscription_id     = "22222222-2222-2222-2222-222222222222"

# Enable Management Groups
management_groups_enabled = true

# Microsoft Defender for Cloud
microsoft_defender_settings = {
  email_security_contact = "user@example.invalid"
}
