output "vnet_resource_group_name" {
  description = "The resource group name for the spoke virtual network."
  value       = module.spoke.resource_group_name
  sensitive   = false
}

output "vnet_name" {
  description = "The name of the virtual network."
  value       = module.spoke.vnet_name
  sensitive   = false
}

output "vnet_id" {
  description = "The ID of the hub virtual network."
  value       = module.spoke.vnet_resource_id
  sensitive   = false
}

output "subnets" {
  description = "The Subnets created by this module"
  value       = module.spoke.subnets
}
