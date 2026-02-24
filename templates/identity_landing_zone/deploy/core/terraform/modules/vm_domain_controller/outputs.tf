output "vm_names" {
  description = "Resource names of every VM created"
  value       = { for k, m in module.domain_controller : k => m.name }
}

output "vm_resource_ids" {
  description = "Resource IDs of every VM created"
  value       = { for k, m in module.domain_controller : k => m.resource_id }
}

output "admin_password" {
  description = "Admin password for each VM"
  sensitive   = true
  value = {
    for vm_key in keys(var.vms) :
    vm_key => module.domain_controller[vm_key].admin_password
  }
}

output "admin_username" {
  description = "Admin username for each VM"
  value = {
    for vm_key in keys(var.vms) :
    vm_key => module.domain_controller[vm_key].admin_username
  }
}

output "network_interfaces" {
  description = "Network interface details for each VM"
  value = {
    for vm_key in keys(var.vms) :
    vm_key => module.domain_controller[vm_key].network_interfaces
  }
}

output "private_ip_addresses" {
  description = "Private IP addresses for each VM"
  value = flatten([
    for vm_key in keys(var.vms) : [
      for nic_key, nic in module.domain_controller[vm_key].network_interfaces : [
        for ip_config in nic.ip_configuration :
        ip_config.private_ip_address
      ]
    ]
  ])
}

output "availability_set_id" {
  description = "ID of the availability set (if created)"
  value       = local.region_supports_zones ? null : azurerm_availability_set.domain_controller_aset[0].id
}

output "availability_set_name" {
  description = "Name of the availability set (if created)"
  value       = local.region_supports_zones ? null : azurerm_availability_set.domain_controller_aset[0].name
}

output "vm_details" {
  description = "Comprehensive VM details"
  value = {
    for vm_key in keys(var.vms) :
    vm_key => {
      name           = module.domain_controller[vm_key].name
      resource_id    = module.domain_controller[vm_key].resource_id
      location       = var.region
      sku_size       = var.vms[vm_key].sku_size
      zone           = local.region_supports_zones ? try(var.vms[vm_key].zone, null) : null
      admin_username = module.domain_controller[vm_key].admin_username
    }
  }
}
