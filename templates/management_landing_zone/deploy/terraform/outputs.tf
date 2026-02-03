output "log_analytics_workspace_guid" {
  description = "The workspace GUID of the log analytics workspace."
  value       = try(module.management_resources[0].log_analytics_workspace.workspace_id, null)
}

output "log_analytics_workspace_id" {
  description = "The resource ID of the log analytics workspace."
  value       = try(module.management_resources[0].log_analytics_workspace.id, null)
}

output "log_analytics_workspace_name" {
  description = "The name of the log analytics workspace."
  value       = try(module.management_resources[0].log_analytics_workspace.name, null)
}
