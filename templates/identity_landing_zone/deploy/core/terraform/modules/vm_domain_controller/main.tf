module "domain_controller" {
  for_each = var.vms
  source   = "Azure/avm-res-compute-virtualmachine/azurerm"
  version  = "0.19.3"

  # Basic VM configuration - Using HLD-compliant naming from parent module
  name          = var.vm_name_map[each.key]
  computer_name = var.vm_extend_name_map[each.key].computer_name
  location      = var.resource_group_location
  sku_size      = each.value.sku_size
  os_type       = "Windows"

  # Admin credentials - uses temp password (replaced via Azure CLI after creation)
  account_credentials = {
    admin_credentials = {
      username                           = var.admin_username
      password                           = var.admin_temp_password
      generate_admin_password_or_ssh_key = false
    }
  }

  # Zone configuration - use zones if supported, otherwise availability set
  zone                         = local.region_supports_zones ? try(each.value.zone, null) : null
  availability_set_resource_id = local.region_supports_zones ? null : azurerm_availability_set.domain_controller_aset[0].id

  # Network interface configuration - Using HLD-compliant naming
  network_interfaces = {
    for nic_key, nic_val in each.value.network_interfaces : nic_key => {
      name = var.vm_extend_name_map[each.key].nic[nic_key].name
      ip_configurations = {
        for ip_key, ip_cfg in nic_val.ip_configurations : ip_key => {
          name                          = "${nic_key}-${ip_key}"
          private_ip_address            = ip_cfg.private_ip_address
          private_ip_address_allocation = ip_cfg.private_ip_address_allocation
          # Use the explicitly provided subnet ID if available; fallback to default subnet
          private_ip_subnet_resource_id = coalesce(ip_cfg.private_ip_subnet_resource_id, var.subnet_resource_id)
        }
      }
    }
  }

  # OS disk configuration - Using HLD-compliant naming
  os_disk = {
    name                 = var.vm_extend_name_map[each.key].os_disk.name
    caching              = var.os_disk_config.caching
    disk_size_gb         = var.os_disk_config.disk_size_gb
    storage_account_type = var.os_disk_config.storage_account_type
  }

  # Source image configuration
  source_image_reference = {
    publisher = var.os_image.publisher
    offer     = var.os_image.offer
    sku       = var.os_image.sku
    version   = var.os_image.version
  }

  # Data disk configuration - Using HLD-compliant naming
  data_disk_managed_disks = {
    for disk_key, disk_val in try(each.value.data_disks, {}) : disk_key => {
      name                       = var.vm_extend_name_map[each.key].data_disks[disk_key].name
      storage_account_type       = disk_val.storage_account_type
      lun                        = disk_val.lun
      caching                    = disk_val.caching
      disk_size_gb               = disk_val.disk_size_gb
      encryption_at_host_enabled = true
    }
  }

  # Resource group and tags
  resource_group_name = var.resource_group_name
  tags                = var.tags

  # Telemetry
  enable_telemetry = var.enable_telemetry

  # VM settings
  encryption_at_host_enabled = var.vm_settings.encryption_at_host_enabled
  allow_extension_operations = var.vm_settings.allow_extension_operations
  enable_automatic_updates   = var.vm_settings.enable_automatic_updates
  patch_assessment_mode      = var.vm_settings.patch_assessment_mode
  patch_mode                 = var.vm_settings.patch_mode
  provision_vm_agent         = var.vm_settings.provision_vm_agent
  secure_boot_enabled        = var.vm_settings.secure_boot_enabled
  vtpm_enabled               = var.vm_settings.vtpm_enabled
  boot_diagnostics           = var.vm_settings.boot_diagnostics

  # Extensions
  extensions = var.extensions

  # System-assigned managed identity required for Azure Monitor Agent
  # See: https://registry.terraform.io/modules/Azure/avm-res-compute-virtualmachine/azurerm/latest
  managed_identities = {
    system_assigned = true
  }
}
