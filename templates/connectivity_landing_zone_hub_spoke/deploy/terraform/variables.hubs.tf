# =============================================================================
# Hub Configuration Variables
# =============================================================================
#
# This file defines the primary configuration for hub virtual networks.
# The module supports single-region and multi-region deployments out of the box.
#
# QUICK START:
# ------------
# Single region:  hubs = { uksouth = {} }
# Multi-region:   hubs = { uksouth = {}, ukwest = {} }
#
# Use any valid Azure region name as the map key. The module automatically
# validates region names and configures resources appropriately.
#
# IP ADDRESSING:
# --------------
# By default, each hub receives a /16 address space calculated automatically:
#   - First hub:  10.0.0.0/16
#   - Second hub: 10.1.0.0/16
#   - Third hub:  10.2.0.0/16
#   - etc.
#
# Subnets are calculated using cidrsubnet() from each hub's address space.
# Override individual values as needed.
#
# =============================================================================

variable "hubs" {
  type = map(object({
    # -------------------------------------------------------------------------
    # Core Settings
    # -------------------------------------------------------------------------
    enabled = optional(bool, true) # Set to false to skip this hub entirely

    # Override the auto-calculated address space (default: 10.{index}.0.0/16)
    address_space = optional(string)

    # -------------------------------------------------------------------------
    # Feature Toggles
    # -------------------------------------------------------------------------
    # Enable or disable optional hub components. Disabled features won't
    # create any resources, reducing cost and complexity.
    #
    features = optional(object({
      firewall               = optional(bool, true)   # Azure Firewall
      firewall_management_ip = optional(bool, true)   # Required for forced tunneling
      bastion                = optional(bool, false)  # Azure Bastion host
      vpn_gateway            = optional(bool, false)  # VPN Gateway (S2S/P2S)
      expressroute_gateway   = optional(bool, false)  # ExpressRoute Gateway
      private_dns_zones      = optional(bool, true)   # Private Link DNS zones
      private_dns_resolver   = optional(bool, true)   # Azure DNS Private Resolver
      auto_registration_zone = optional(bool, true)   # VM auto-registration DNS zone
      availability_zones     = optional(list(string)) # e.g., ["1", "2", "3"] - incurs cross-zone data transfer costs
    }), {})

    # -------------------------------------------------------------------------
    # Subnet Address Prefixes (Optional Overrides)
    # -------------------------------------------------------------------------
    # By default, subnets are calculated automatically using cidrsubnet().
    # Override specific subnets here if you need custom sizing or to avoid
    # conflicts with existing networks.
    #
    # Default subnet layout within a /22 carved from the hub's /16:
    #   AzureFirewallSubnet:           /26 (64 IPs)
    #   AzureFirewallManagementSubnet: /26 (64 IPs)
    #   AzureBastionSubnet:            /26 (64 IPs)
    #   GatewaySubnet:                 /27 (32 IPs)
    #   PrivateDnsResolverSubnet:      /28 (16 IPs)
    #
    subnets = optional(object({
      firewall_address_prefix             = optional(string)
      firewall_management_address_prefix  = optional(string)
      bastion_address_prefix              = optional(string)
      gateway_address_prefix              = optional(string)
      private_dns_resolver_address_prefix = optional(string)
    }), {})

    # -------------------------------------------------------------------------
    # Additional Custom Subnets
    # -------------------------------------------------------------------------
    # Add workload or management subnets to the hub VNet.
    # These are passed directly to the AVM module.
    #
    # Example:
    #   custom_subnets = {
    #     management = {
    #       name             = "snet-management"
    #       address_prefixes = ["10.0.4.0/24"]
    #     }
    #   }
    #
    custom_subnets = optional(map(object({
      name                                          = string
      address_prefixes                              = list(string)
      network_security_group_id                     = optional(string)
      route_table_id                                = optional(string)
      service_endpoints                             = optional(list(string))
      private_endpoint_network_policies             = optional(string, "Enabled")
      private_link_service_network_policies_enabled = optional(bool, true)
      delegation = optional(object({
        name         = string
        service_name = string
        actions      = optional(list(string))
      }))
    })), {})

    # -------------------------------------------------------------------------
    # Private DNS Configuration
    # -------------------------------------------------------------------------
    dns = optional(object({
      # Custom name for the auto-registration zone (default: {region}.azure.local)
      auto_registration_zone_name = optional(string)
    }), {})

    # -------------------------------------------------------------------------
    # Resource Naming Overrides
    # -------------------------------------------------------------------------
    # Override auto-generated resource names for specific resources.
    # Use this when you need to match existing naming conventions or
    # integrate with pre-existing resources.
    #
    # Example:
    #   name_overrides = {
    #     resource_group  = "rg-hub-legacy"
    #     virtual_network = "vnet-hub-existing"
    #   }
    #
    name_overrides = optional(object({
      resource_group       = optional(string)
      virtual_network      = optional(string)
      firewall             = optional(string)
      firewall_policy      = optional(string)
      bastion              = optional(string)
      vpn_gateway          = optional(string)
      expressroute_gateway = optional(string)
      private_dns_resolver = optional(string)
      route_table_firewall = optional(string)
      route_table_user     = optional(string)
    }), {})

    # -------------------------------------------------------------------------
    # Tags
    # -------------------------------------------------------------------------
    # Hub-specific tags merged with global tags
    tags = optional(map(string), {})
  }))

  # No default - users must explicitly specify their hub region(s)
  # Example: hubs = { uksouth = {} } or hubs = { eastus = {}, westus = {} }

  description = "Hub virtual network configurations keyed by Azure region name. Each hub can be independently configured with features, IP ranges, and settings."

  validation {
    condition     = length(var.hubs) > 0
    error_message = "At least one hub must be defined."
  }

  validation {
    condition     = length(var.hubs) <= 10
    error_message = "Maximum of 10 hubs supported (IP address space limitation)."
  }

  # Validate hub keys are lowercase (Azure region names are lowercase)
  validation {
    condition = alltrue([
      for key in keys(var.hubs) :
      key == lower(key)
    ])
    error_message = "Hub keys must be lowercase Azure region names (e.g., 'uksouth', not 'UKSouth')."
  }

  # Validate hub keys contain only valid characters
  validation {
    condition = alltrue([
      for key in keys(var.hubs) :
      can(regex("^[a-z][a-z0-9]*$", key))
    ])
    error_message = "Hub keys must be valid Azure region names (lowercase letters and numbers only, e.g., 'uksouth', 'northeurope')."
  }

  # Validate address_space is a valid CIDR if provided
  validation {
    condition = alltrue([
      for key, hub in var.hubs :
      hub.address_space == null || can(cidrhost(hub.address_space, 0))
    ])
    error_message = "Hub address_space must be a valid CIDR block (e.g., '10.0.0.0/16')."
  }

  # Validate subnet prefixes are valid CIDRs if provided
  validation {
    condition = alltrue([
      for key, hub in var.hubs :
      hub.subnets == null || alltrue([
        hub.subnets.firewall_address_prefix == null || can(cidrhost(hub.subnets.firewall_address_prefix, 0)),
        hub.subnets.firewall_management_address_prefix == null || can(cidrhost(hub.subnets.firewall_management_address_prefix, 0)),
        hub.subnets.bastion_address_prefix == null || can(cidrhost(hub.subnets.bastion_address_prefix, 0)),
        hub.subnets.gateway_address_prefix == null || can(cidrhost(hub.subnets.gateway_address_prefix, 0)),
        hub.subnets.private_dns_resolver_address_prefix == null || can(cidrhost(hub.subnets.private_dns_resolver_address_prefix, 0))
      ])
    ])
    error_message = "Subnet address prefixes must be valid CIDR blocks."
  }

  # Validate custom_subnets address_prefixes are valid CIDRs
  validation {
    condition = alltrue([
      for key, hub in var.hubs :
      hub.custom_subnets == null || alltrue([
        for subnet_key, subnet in hub.custom_subnets :
        alltrue([for prefix in subnet.address_prefixes : can(cidrhost(prefix, 0))])
      ])
    ])
    error_message = "Custom subnet address_prefixes must be valid CIDR blocks."
  }

  # Validate firewall_management_ip is only enabled when firewall is enabled
  validation {
    condition = alltrue([
      for key, hub in var.hubs :
      hub.features == null || (
        hub.features.firewall_management_ip == null ||
        hub.features.firewall_management_ip == false ||
        (hub.features.firewall == null || hub.features.firewall == true)
      )
    ])
    error_message = "firewall_management_ip requires firewall to be enabled."
  }

  # Note: Region name validation happens at plan time via the azure_regions module.
  # Invalid region names will cause a lookup error with a clear message.
  # To see valid region names, check: https://azure.microsoft.com/en-us/explore/global-infrastructure/geographies
}

# =============================================================================
# Global Hub Settings
# =============================================================================

variable "hub_network_address_prefix" {
  type        = string
  default     = "10.0.0.0/8"
  description = "Base address space from which hub networks are allocated. Each hub receives a /16 (e.g., 10.0.0.0/16, 10.1.0.0/16)."

  validation {
    condition     = can(cidrhost(var.hub_network_address_prefix, 0))
    error_message = "Must be a valid CIDR block."
  }

  validation {
    condition     = tonumber(split("/", var.hub_network_address_prefix)[1]) <= 16
    error_message = "Base address space must be /16 or larger to accommodate hub /16 allocations."
  }

  validation {
    condition     = !can(regex("^0\\.", var.hub_network_address_prefix))
    error_message = "Cannot use 0.0.0.0/x address space."
  }
}

variable "ddos_protection_plan" {
  type = object({
    enabled = optional(bool, false)
    name    = optional(string)
  })
  default     = {}
  description = "Azure DDoS Protection Plan configuration. When enabled, protects all hub VNets."
}
