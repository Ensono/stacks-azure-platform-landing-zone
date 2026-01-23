locals {
  # Naming instances
  # - static_suffix = true:  Use .name output (deterministic, for ALZ policy values)
  # - static_suffix = false: Use .name_unique output (globally unique, for storage)
  naming_instances = {
    asc_export = { component = "asc", static_suffix = true }
    flow_logs  = { component = "fl", static_suffix = false }
    management = { component = "man", static_suffix = true }
  }

  # Resource names from naming module
  # Note: flow_logs_storage uses .name_unique (NOT safe for ALZ policy values)
  resource_names = {
    asc_export_resource_group = module.naming["asc_export"].resource_group.name
    flow_logs_storage         = module.naming["flow_logs"].storage_account.name_unique
    log_analytics_workspace   = module.naming["management"].log_analytics_workspace.name
    resource_group            = module.naming["management"].resource_group.name
    user_assigned_identity    = module.naming["management"].user_assigned_identity.name
  }
}
