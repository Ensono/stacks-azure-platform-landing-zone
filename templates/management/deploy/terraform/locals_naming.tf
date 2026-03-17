locals {
  # Naming instances for module.naming
  naming_instances = {
    management = { component = "man" }
  }

  # Resource names from naming module
  resource_names = {
    log_analytics_workspace = module.naming["management"].log_analytics_workspace.name
    resource_group          = module.naming["management"].resource_group.name
    user_assigned_identity  = module.naming["management"].user_assigned_identity.name
  }
}
