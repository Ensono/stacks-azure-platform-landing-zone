#------------------------------------------------------------------------------
# Key Vault Module Outputs
#------------------------------------------------------------------------------

output "resource_id" {
  description = "The resource ID of the Key Vault"
  value       = module.key_vault.resource_id
}

output "name" {
  description = "The name of the Key Vault"
  value       = module.key_vault.name
}

output "uri" {
  description = "The URI of the Key Vault"
  value       = module.key_vault.uri
}

output "private_endpoint_id" {
  description = "The ID of the Key Vault private endpoint"
  value       = module.key_vault.private_endpoints["vault"].id
}

output "dns_wait_id" {
  description = "The ID of the DNS wait resource - use for depends_on"
  value       = time_sleep.wait_for_dns_policy.id
}
