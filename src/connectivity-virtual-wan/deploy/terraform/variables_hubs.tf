variable "hubs" {
  type = map(object({
    enabled       = optional(bool, true)
    address_space = optional(string)

    features = optional(object({
      firewall                   = optional(bool, true)
      firewall_sku               = optional(string, "Standard")
      firewall_dns_proxy         = optional(bool, true)
      firewall_threat_intel_mode = optional(string, "Alert")
      bastion                    = optional(bool, false)
      vpn_gateway                = optional(bool, false)
      expressroute_gateway       = optional(bool, false)
      private_dns_zones          = optional(bool, true)
      private_dns_resolver       = optional(bool, false)
      sidecar_virtual_network    = optional(bool, true)
      availability_zones         = optional(list(number))
    }), {})

    hub = optional(object({
      sku                                    = optional(string)
      hub_routing_preference                 = optional(string, "ExpressRoute")
      virtual_router_auto_scale_min_capacity = optional(number, 2)
    }), {})

    sidecar_subnets = optional(object({
      bastion_address_prefix              = optional(string)
      gateway_address_prefix              = optional(string)
      private_dns_resolver_address_prefix = optional(string)
      private_endpoints_address_prefix    = optional(string)
    }), {})

    dns = optional(object({
      auto_registration_zone_name = optional(string)
      servers                     = optional(list(string))
    }), {})

    name_overrides = optional(object({
      resource_group          = optional(string)
      virtual_hub             = optional(string)
      sidecar_virtual_network = optional(string)
      firewall                = optional(string)
      firewall_policy         = optional(string)
      bastion                 = optional(string)
      vpn_gateway             = optional(string)
      expressroute_gateway    = optional(string)
      private_dns_resolver    = optional(string)
    }), {})

    tags = optional(map(string), {})
  }))

  description = "Virtual hub configurations keyed by Azure region name."

  validation {
    condition     = length(var.hubs) > 0
    error_message = "At least one hub must be defined."
  }

  validation {
    condition     = length(var.hubs) <= 10
    error_message = "Maximum of 10 hubs supported."
  }

  validation {
    condition = alltrue([
      for key in keys(var.hubs) :
      key == lower(key)
    ])
    error_message = "Hub keys must be lowercase Azure region names."
  }

  validation {
    condition = alltrue([
      for key in keys(var.hubs) :
      can(regex("^[a-z][a-z0-9]*$", key))
    ])
    error_message = "Hub keys must be valid Azure region names."
  }

  validation {
    condition = alltrue([
      for key, hub in var.hubs :
      hub.address_space == null || can(cidrhost(hub.address_space, 0))
    ])
    error_message = "Hub address_space must be a valid CIDR block."
  }

  validation {
    condition = alltrue([
      for key, hub in var.hubs :
      hub.features == null || hub.features.firewall_sku == null ||
      contains(["Basic", "Standard", "Premium"], hub.features.firewall_sku)
    ])
    error_message = "Firewall SKU must be Basic, Standard, or Premium."
  }

  validation {
    condition = alltrue([
      for key, hub in var.hubs :
      hub.features == null || hub.features.firewall_threat_intel_mode == null ||
      contains(["Off", "Alert", "Deny"], hub.features.firewall_threat_intel_mode)
    ])
    error_message = "Firewall threat intelligence mode must be Off, Alert, or Deny."
  }
}

variable "ddos_protection_plan" {
  type = object({
    enabled = optional(bool, false)
  })
  default     = {}
  description = <<-DESCRIPTION
    DDoS Protection Plan configuration. Disabled by default due to significant cost (~£2,200/month).

    - `enabled` - (Optional) Enable DDoS Protection Plan. Default: `false`.
  DESCRIPTION
}

variable "hub_network_address_prefix" {
  type        = string
  default     = "10.0.0.0/8"
  description = "Base address space for hub networks. Each hub receives a /16."

  validation {
    condition     = can(cidrhost(var.hub_network_address_prefix, 0))
    error_message = "Must be a valid CIDR block."
  }

  validation {
    condition     = tonumber(split("/", var.hub_network_address_prefix)[1]) <= 16
    error_message = "Base address space must be /16 or larger."
  }

  validation {
    condition     = !can(regex("^0\\.", var.hub_network_address_prefix))
    error_message = "Cannot use 0.0.0.0/x address space."
  }
}
