locals {
  # Dynamic regional virtual hub selection based on current location
  regional_virtual_hub_resource_id = (
    can(module.remote_state.connectivity_remote_states[var.azure_location].virtual_hub_resource_id) ?
    module.remote_state.connectivity_remote_states[var.azure_location].virtual_hub_resource_id :
    null
  )

  # Determine the remote region based on current location
  remote_region = var.azure_location == "eastus2" ? "centralus" : "eastus2"

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

  # Get DNS servers from current region first, then remote region
  current_region_dns = (
    can(module.remote_state.identity_remote_states[var.azure_location].domain_controller_private_ips) ?
    module.remote_state.identity_remote_states[var.azure_location].domain_controller_private_ips :
    []
  )

  remote_region_dns = (
    can(module.remote_state.identity_remote_states[local.remote_region].domain_controller_private_ips) ?
    module.remote_state.identity_remote_states[local.remote_region].domain_controller_private_ips :
    []
  )

  # Combine DNS servers: current region first, then remote region
  combined_dns_servers = concat(
    module.vm_domain_controller.private_ip_addresses, # Current deployment DNS servers
    local.current_region_dns,                         # Current region existing DNS servers
    local.remote_region_dns                           # Remote region DNS servers
  )

  # Remove duplicates and filter out empty values
  dns_servers = distinct([
    for ip in local.combined_dns_servers : ip
    if ip != null && ip != ""
  ])
}
