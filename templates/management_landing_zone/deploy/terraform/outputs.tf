output "log_analytics_workspace_id" {
  description = "The resource ID of the log analytics workspace."
  value       = try(module.management_resources[0].log_analytics_workspace_id, null)
}
