variable "vms" {
  type = map(object({
    zone     = optional(string)
    sku_size = string
    network_interfaces = map(object({
      ip_configurations = map(object({
        private_ip_address            = optional(string)
        private_ip_address_allocation = string
        private_ip_subnet_resource_id = optional(string)
      }))
    }))
    data_disks = optional(map(object({
      lun                  = number
      disk_size_gb         = number
      storage_account_type = string
      caching              = string
    })), {})
    tags = optional(map(string), {})
  }))
  description = "Map of VM configurations for domain controllers"
}

variable "vm_name_map" {
  type        = map(string)
  description = "Map of VM keys to HLD-compliant names (e.g., {'01' = 'A2PW000DC01'})"
}

variable "vm_extend_name_map" {
  type = map(object({
    nic = map(object({
      name = string
    }))
    os_disk = object({
      name = string
    })
    data_disks = map(object({
      name = string
    }))
    computer_name = string
  }))
  description = "Extended naming map for VM-related resources (NICs, disks)"
}

variable "availability_set_name" {
  type        = string
  description = "Name for the availability set (HLD-compliant)"
}

variable "region" {
  description = "The Azure region where resources will be created"
  type = object({
    geo_code = string
    zones    = list(string)
  })
}

variable "resource_group_name" {
  type        = string
  description = "The name of the resource group where domain controller resources will be created"
}

variable "resource_group_location" {
  description = "The location/region where resources will be created"
  type        = string
}

variable "subnet_resource_id" {
  type        = string
  description = "Default subnet ID for domain controllers when subnet is not specified in VM configuration"
}

variable "tags" {
  type        = map(string)
  description = "Common tags to apply to all resources"
  default     = {}
}

variable "enable_telemetry" {
  type        = bool
  description = "Enable telemetry for the VM module"
  default     = false
}

variable "os_image" {
  type = object({
    publisher = string
    offer     = string
    sku       = string
    version   = string
  })
  description = "Operating system image configuration"
  default = {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-datacenter-gensecond"
    version   = "latest"
  }
}

variable "os_disk_config" {
  type = object({
    caching              = string
    disk_size_gb         = number
    storage_account_type = string
  })
  description = "OS disk configuration"
  default = {
    caching              = "ReadWrite"
    disk_size_gb         = 128
    storage_account_type = "StandardSSD_LRS"
  }
}

variable "vm_settings" {
  type = object({
    encryption_at_host_enabled = optional(bool, true)
    allow_extension_operations = optional(bool, true)
    enable_automatic_updates   = optional(bool, true)
    patch_assessment_mode      = optional(string, "AutomaticByPlatform")
    patch_mode                 = optional(string, "AutomaticByPlatform")
    provision_vm_agent         = optional(bool, true)
    secure_boot_enabled        = optional(bool, true)
    vtpm_enabled               = optional(bool, true)
    boot_diagnostics           = optional(bool, true)
  })
  description = "VM security and management settings - Trusted Launch enabled by default for Gen 2 VMs"
  default = {
    encryption_at_host_enabled = true # Encrypts all disks at the Azure host level
    allow_extension_operations = true
    enable_automatic_updates   = true
    patch_assessment_mode      = "AutomaticByPlatform"
    patch_mode                 = "AutomaticByPlatform"
    provision_vm_agent         = true
    secure_boot_enabled        = true # Prevents boot-level malware (requires Gen 2 VM)
    vtpm_enabled               = true # Enables attestation and BitLocker support (requires Gen 2 VM)
    boot_diagnostics           = true
  }
}

variable "availability_set_config" {
  type = object({
    platform_update_domain_count = optional(number, 5)
    platform_fault_domain_count  = optional(number, 2)
    managed                      = optional(bool, true)
  })
  description = "Availability set configuration (used when zones are not available)"
  default = {
    platform_update_domain_count = 5
    platform_fault_domain_count  = 2
    managed                      = true
  }
}

variable "extensions" {
  type = map(object({
    name                       = string
    publisher                  = string
    type                       = string
    type_handler_version       = string
    auto_upgrade_minor_version = optional(bool, true)
    automatic_upgrade_enabled  = optional(bool, true)
    settings                   = optional(string, null)
    protected_settings         = optional(string, null)
  }))
  description = "VM extensions to install"
  default = {
    azure_monitor_agent = {
      name                       = "AzureMonitorWindowsAgent"
      publisher                  = "Microsoft.Azure.Monitor"
      type                       = "AzureMonitorWindowsAgent"
      type_handler_version       = "1.2"
      auto_upgrade_minor_version = true
      automatic_upgrade_enabled  = true
      settings                   = null
      protected_settings         = null
    }
  }
}

#------------------------------------------------------------------------------
# Admin Credentials (Ephemeral Password Pattern)
#------------------------------------------------------------------------------

variable "admin_username" {
  type        = string
  description = "Admin username for VMs"
  default     = "dcadmin"
}

variable "admin_temp_password" {
  type        = string
  description = "Temporary password for VM creation (replaced immediately after creation)"
  sensitive   = true
}
