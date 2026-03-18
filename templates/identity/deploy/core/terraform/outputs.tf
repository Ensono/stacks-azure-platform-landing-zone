output "subscription_id" {
  description = "The subscription ID of the Identity subscription."
  value       = data.azurerm_client_config.this.subscription_id
  sensitive   = false
}

output "private_ip_addresses" {
  description = "Private IP addresses for each VM"
  value       = module.vm_domain_controller.private_ip_addresses
}
