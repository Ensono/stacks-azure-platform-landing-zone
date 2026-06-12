locals {
  selected_region = {
    geo_code = module.azure_regions.regions_by_name[var.azure_location].geo_code
    zones    = module.azure_regions.regions_by_name[var.azure_location].zones
  }

  resource_tags = var.tags

  regional_virtual_hub_resource_id = coalesce(
    try(module.remote_state.connectivity_remote_states[var.azure_location].virtual_hub_resource_id, null),
    try(module.remote_state.connectivity_remote_states[var.azure_location].virtual_hub_id, null),
    null
  )

  connectivity_dns_proxy_ips = distinct(compact(flatten([
    try([module.remote_state.connectivity_remote_states[var.azure_location].dns_proxy_ip_address], []),
    try(module.remote_state.connectivity_remote_states[var.azure_location].dns_proxy_private_ip_addresses, []),
    try([module.remote_state.connectivity_remote_states[var.azure_location].firewall_private_ip_address], []),
    try(module.remote_state.connectivity_remote_states[var.azure_location].firewall_private_ip_addresses, [])
  ])))

  identity_vnet_dns_servers = length(var.identity_vnet_dns_servers) > 0 ? var.identity_vnet_dns_servers : local.connectivity_dns_proxy_ips

  adds_dns_forwarders = length(var.adds_dns_forwarders) > 0 ? var.adds_dns_forwarders : local.identity_vnet_dns_servers

  identity_admin_scopes = {
    adds       = module.resource_groups["adds"].resource_id
    key_vault  = module.key_vault.resource_id
    networking = module.resource_groups["networking"].resource_id
  }

  # =============================================================================
  # VM Naming per HLD: A{env}{os}{appcode}{role}{##}
  # Example: APW000DC01 (region number removed per Jon Walker's request)
  # =============================================================================

  # Region to number mapping - commented out as no longer used for VM naming
  # region_number_map = {
  #   "eastus"    = "1"
  #   "eastus2"   = "2"
  #   "centralus" = "3"
  # }

  # Environment to single letter mapping
  env_letter_map = {
    "prd" = "P"
    "uat" = "T"
    "dev" = "D"
  }

  # Generate VM names following HLD pattern: APW000DC01 (no region number)
  # Key in var.vms IS the global instance number (01, 02, 03, 04)
  vm_name_map = {
    for vm_key, vm_val in var.vms : vm_key => format(
      "A%sW%s%s%s",
      local.env_letter_map[var.environment], # P (for prd)
      var.vm_app_code,                       # 000 (for Active Directory)
      var.vm_role,                           # DC (for Domain Controller)
      vm_key                                 # 01, 02, 03, 04 (global instance)
    )
  }

  # Extended naming for VM-related resources (NIC, disks)
  vm_extend_name_map = {
    for vm_key, vm_val in var.vms : vm_key => {
      # NIC naming
      nic = {
        for nic_key, nic_val in vm_val.network_interfaces : nic_key => {
          name = "${local.vm_name_map[vm_key]}-nic"
        }
      }
      # OS Disk naming
      os_disk = {
        name = "${local.vm_name_map[vm_key]}-osdisk"
      }
      # Data Disk naming
      data_disks = {
        for disk_key, disk_val in try(vm_val.data_disks, {}) : disk_key => {
          name = "${local.vm_name_map[vm_key]}-${disk_key}"
        }
      }
      # Computer Name (same as VM name - fits Windows 15-char NetBIOS limit)
      computer_name = local.vm_name_map[vm_key]
    }
  }

  # Availability Set naming (no region number to match VM naming)
  vm_availability_set_name = format(
    "A%sW%s%s-avail",
    local.env_letter_map[var.environment],
    var.vm_app_code,
    var.vm_role
  )

  # =============================================================================
  # DNS Configuration
  # =============================================================================
}
