# Build policy dependencies
locals {
  management_group_dependencies = {
    policy_assignments = [
      module.management_resources
    ]
    policy_role_assignments = [
      module.management_resources
    ]
  }
}

# Merge management group and resource settings with config module outputs
locals {
  management_group_settings = merge(
    module.config.outputs.management_group_settings,
    {
      dependencies = local.management_group_dependencies
    }
  )
  management_resource_settings = merge(
    module.config.outputs.management_resource_settings,
    {
      resource_group_name          = local.naming_outputs.management_resource_group_name
      log_analytics_workspace_name = local.naming_outputs.log_analytics_workspace_name
      tags                         = coalesce(module.config.outputs.management_resource_settings.tags, module.config.outputs.tags)
    }
  )
}

# Naming module outputs
locals {
  naming_outputs = {
    # Resource group names
    management_resource_group_name = try(
      module.naming_caf[0].resource_group.name,
      module.naming_stacks_foundation[0].names[var.component_name].resource_group.name
    )
    # Resource names
    log_analytics_workspace_name = try(
      module.naming_caf[0].log_analytics_workspace.name,
      module.naming_stacks_foundation[0].names[var.component_name].log_analytics_workspace.name
    )
  }
}
