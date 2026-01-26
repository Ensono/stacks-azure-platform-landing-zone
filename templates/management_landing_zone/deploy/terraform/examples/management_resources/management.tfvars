# Management Resources Only
# =========================
# Deploys: Log Analytics, Data Collection Rules, Managed Identity
# Does NOT deploy: Management Groups or Policies
#
# Use when management groups are deployed separately or already exist.
# Outputs are consumed by connectivity module via remote state.

company_name = "ensono"
location     = "uksouth"
