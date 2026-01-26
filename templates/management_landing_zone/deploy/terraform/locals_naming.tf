locals {
  # Naming instances
  # - static_suffix = true:  Use .name output (deterministic, for ALZ policy values)
  # - static_suffix = false: Use .name_unique output (globally unique, for storage)
  naming_instances = {
    asc_export = { component = "asc", static_suffix = true }
    management = { component = "man", static_suffix = true }
  }

  # Resource names from naming module
  resource_names = {
    asc_export_resource_group = module.naming["asc_export"].resource_group.name
    log_analytics_workspace   = module.naming["management"].log_analytics_workspace.name
    resource_group            = module.naming["management"].resource_group.name
    user_assigned_identity    = module.naming["management"].user_assigned_identity.name
  }
}
