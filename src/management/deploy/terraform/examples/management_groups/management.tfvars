# Management Groups (includes Management Resources)
# =================================================
# Deploys: Management Groups, Policies, Log Analytics, DCRs, Identity
#
# Policy default values are computed from management_resources outputs.
# Subscription placement is computed from subscription variables.

# Enable Management Groups
management_groups_enabled = true

# Microsoft Defender for Cloud
microsoft_defender_settings = {
  email_security_contact = "user@example.invalid"
}
