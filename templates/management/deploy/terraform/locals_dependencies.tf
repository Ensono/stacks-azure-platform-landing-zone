locals {
  # Dependencies to ensure management resources are created before management group policies are assigned
  management_group_dependencies = var.management_resources_enabled ? [
    module.management_resources[0]
  ] : null
}
