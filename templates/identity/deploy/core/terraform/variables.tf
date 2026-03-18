# Naming
variable "company_name" {
  description = "Company name used in naming. The first 3 characters are used for resource suffixes."
  type        = string
}

variable "component_names" {
  description = "A list of component names which can be used in naming of resources used with different module calls."
  type        = set(string)
  default     = ["networking", "adds"]

  validation {
    condition     = contains(var.component_names, "networking") && contains(var.component_names, "adds")
    error_message = "component_names must include at least 'networking' and 'adds'."
  }
}

variable "enable_avm_telemetry" {
  description = "Enable telemetry collection for Azure Verified Modules."
  type        = bool
  default     = false
}

# Azure
/*
Examples
https://datacenters.microsoft.com/globe/explore?info=geography_unitedkingdom
https://datacenters.microsoft.com/globe/explore?info=geography_europe
https://datacenters.microsoft.com/globe/explore?info=geography_unitedstates

https://learn.microsoft.com/en-us/azure/reliability/cross-region-replication-azure#azure-paired-regions
*/

variable "azure_location" {
  description = "The Azure location to target all resources."
  type        = string
}


variable "azure_resource_group_management_lock_level" {
  description = "Optional: The level of Management Lock apply to Resource Groups"
  type        = string
  default     = ""

  validation {
    condition = contains([
      "",
      "ReadOnly",
      "CanNotDelete"
    ], var.azure_resource_group_management_lock_level)
    error_message = "Possible values are 'ReadOnly' or 'CanNotDelete'."
  }
}

# Modules

variable "vnet_address_space" {
  description = "The address space applied to the virtual network. You can supply more than one address space."
  type        = list(string)
  nullable    = false
}

variable "vnet_subnets" {
  description = "A map of subnets to create."
  type = map(object({
    name                                          = string
    address_prefixes                              = list(string)
    nsg_rule_names                                = list(string)
    default_outbound_access_enabled               = optional(bool, false)
    route_names                                   = optional(list(string), [])
    private_endpoint_network_policies             = optional(string, "Disabled")
    private_link_service_network_policies_enabled = optional(bool, true)
  }))
}

variable "vnet_nsg_rules" {
  description = "A map of NSG rules to create."
  type = map(object({
    name                       = string
    priority                   = number
    direction                  = string
    access                     = string
    protocol                   = string
    source_port_range          = string
    destination_port_range     = string
    source_address_prefix      = string
    destination_address_prefix = string
  }))
  default = {}
}

variable "environment" {
  description = "The Azure environment to target all resources."
  type        = string

  validation {
    condition     = contains(["dev", "uat", "prd"], var.environment)
    error_message = "environment must be one of: dev, uat, prd."
  }
}

variable "tags" {
  description = "Tags applied to all identity landing zone resources."
  type        = map(string)
  default     = {}
}

variable "remote_state_configs" {
  description = "Map of remote state configurations by domain and region, for example management_eastus2, connectivity_eastus2, identity_eastus2."
  type = map(object({
    storage_account_name = string
    container_name       = string
    key                  = string
    use_azuread_auth     = bool
  }))
}

variable "identity_vnet_dns_servers" {
  description = "Optional explicit DNS servers for the identity VNet. When omitted, DNS proxy IPs are discovered from connectivity remote state outputs."
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for ip in var.identity_vnet_dns_servers : can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}$", ip)) && !can(regex("^(REPLACE_WITH_|TODO_)", ip))
    ])
    error_message = "identity_vnet_dns_servers must contain IPv4 addresses only and must not contain placeholder values (REPLACE_WITH_* or TODO_*)."
  }
}

variable "adds_dns_forwarders" {
  description = "Optional explicit ADDS DNS forwarders configured on domain controllers. Defaults to identity_vnet_dns_servers when not provided."
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for ip in var.adds_dns_forwarders : can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}$", ip)) && !can(regex("^(REPLACE_WITH_|TODO_)", ip))
    ])
    error_message = "adds_dns_forwarders must contain IPv4 addresses only and must not contain placeholder values (REPLACE_WITH_* or TODO_*)."
  }
}

variable "identity_admin_role_assignments" {
  description = "Least-privilege role assignments for identity administration. Keys are assignment names."
  type = map(object({
    principal_id         = string
    role_definition_name = string
    scope                = optional(string, "adds")
  }))
  default = {}

  validation {
    condition = alltrue([
      for assignment in values(var.identity_admin_role_assignments) : can(regex("^[0-9a-fA-F-]{36}$", assignment.principal_id))
    ])
    error_message = "Each identity_admin_role_assignments principal_id must be a valid GUID."
  }

  validation {
    condition = alltrue([
      for assignment in values(var.identity_admin_role_assignments) : contains([
        "Reader",
        "Virtual Machine Administrator Login",
        "Virtual Machine User Login",
        "Key Vault Secrets Officer",
        "Key Vault Secrets User"
      ], assignment.role_definition_name)
    ])
    error_message = "identity_admin_role_assignments.role_definition_name must be one of: Reader, Virtual Machine Administrator Login, Virtual Machine User Login, Key Vault Secrets Officer, Key Vault Secrets User."
  }

  validation {
    condition = alltrue([
      for assignment in values(var.identity_admin_role_assignments) : contains(["adds", "networking", "key_vault"], assignment.scope)
    ])
    error_message = "identity_admin_role_assignments.scope must be one of: adds, networking, key_vault."
  }
}

variable "enforce_identity_admin_role_assignments" {
  description = "When true, requires explicit least-privilege identity admin role assignments for production environments."
  type        = bool
  default     = true

  validation {
    condition     = var.enforce_identity_admin_role_assignments == false || var.environment != "prd" || length(var.identity_admin_role_assignments) > 0
    error_message = "At least one identity_admin_role_assignments entry is required for prd when enforce_identity_admin_role_assignments is true."
  }
}

# VM Naming Variables (HLD Compliance)
variable "vm_app_code" {
  description = "Application code for VM naming per HLD (e.g., 000 for Active Directory)"
  type        = string
  default     = "000"

  validation {
    condition     = can(regex("^[0-9]{3}$", var.vm_app_code))
    error_message = "vm_app_code must be a 3-digit string (e.g., '000', '038')."
  }
}

variable "vm_role" {
  description = "VM role abbreviation for naming per HLD (e.g., DC for Domain Controller, APP, DB)"
  type        = string
  default     = "DC"

  validation {
    condition     = can(regex("^[A-Z]{2,4}$", var.vm_role))
    error_message = "vm_role must be 2-4 uppercase letters (e.g., 'DC', 'APP', 'DB')."
  }
}

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

#------------------------------------------------------------------------------
# VM Admin Credentials (Ephemeral Password Pattern)
#------------------------------------------------------------------------------

variable "vm_admin_username" {
  type        = string
  description = "Admin username for domain controller VMs"
  default     = "azureuser"

  validation {
    condition     = !can(regex("^(administrator|admin|user|user1|test|guest|root)$", lower(var.vm_admin_username)))
    error_message = "Reserved usernames are not allowed."
  }
}

variable "vm_password_version" {
  type        = number
  description = "Increment this value to rotate the VM admin password. Uses value_wo_version for write-only Key Vault secret."
  default     = 1
}
