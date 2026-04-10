# Management Resources Only
# =========================
# Deploys: Log Analytics, Data Collection Rules, Managed Identity
# Does NOT deploy: Management Groups or Policies
#
# Use when management groups are deployed separately or already exist.
# Outputs are consumed by connectivity module via remote state.

company = "ensono"
region  = "uksouth"

management_subscription_id = "00000000-0000-0000-0000-000000000000"
