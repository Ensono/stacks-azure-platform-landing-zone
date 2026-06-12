company_name    = "ensono"
component_names = ["networking", "adds"]

# VM Naming per HLD (A2PW000DC01)
vm_app_code = "000" # Active Directory
vm_role     = "DC"  # Domain Controller

# Remote state configurations
remote_state_configs = {
  management_eastus2 = {
    storage_account_name = "steus2manprdtfstatecig"
    container_name       = "tfstate"
    key                  = "management/core"
    use_azuread_auth     = true
  }
  management_centralus = {
    storage_account_name = "stcusmanprdtfstatejqp"
    container_name       = "tfstate"
    key                  = "management/core"
    use_azuread_auth     = true
  }
  connectivity_eastus2 = {
    storage_account_name = "steus2conprdtfstatewee"
    container_name       = "tfstate"
    key                  = "connectivity/core"
    use_azuread_auth     = true
  }
  connectivity_centralus = {
    storage_account_name = "stcusconprdtfstatensj"
    container_name       = "tfstate"
    key                  = "connectivity/core"
    use_azuread_auth     = true
  }
  identity_eastus2 = {
    storage_account_name = "steus2ideprdtfstatehe1"
    container_name       = "tfstate"
    key                  = "identity/core"
    use_azuread_auth     = true
  }
  identity_centralus = {
    storage_account_name = "stcusideprdtfstateaee"
    container_name       = "tfstate"
    key                  = "identity/core"
    use_azuread_auth     = true
  }
}

# Standard tags
tags = {
  environment = "prd"
  service     = "identity"
  workload    = "adds"
  managed_by  = "terraform"
}
