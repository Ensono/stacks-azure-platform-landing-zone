variable "hubs" {
  type = map(object({
    enabled       = optional(bool, true)
    address_space = optional(string)

    features = optional(object({
      firewall               = optional(bool, true)
      firewall_sku           = optional(string, "Standard")
      firewall_management_ip = optional(bool, true)
      bastion                = optional(bool, false)
      vpn_gateway            = optional(bool, false)
      expressroute_gateway   = optional(bool, false)
      private_dns_zones      = optional(bool, true)
      private_dns_resolver   = optional(bool, true)
      auto_registration_zone = optional(bool, true)
      availability_zones     = optional(list(string))
    }), {})

    subnets = optional(object({
      firewall_address_prefix             = optional(string)
      firewall_management_address_prefix  = optional(string)
      bastion_address_prefix              = optional(string)
      gateway_address_prefix              = optional(string)
      private_dns_resolver_address_prefix = optional(string)
      private_endpoints_address_prefix    = optional(string)
    }), {})

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

    dns = optional(object({
      auto_registration_zone_name = optional(string)
    }), {})

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

    tags = optional(map(string), {})
  }))

  description = "Hub virtual network configurations keyed by Azure region name."

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

  validation {
    condition = alltrue([
      for key, hub in var.hubs :
      hub.features == null ||
      hub.features.firewall_sku == null ||
      contains(["Basic", "Standard", "Premium"], hub.features.firewall_sku)
    ])
    error_message = "firewall_sku must be 'Basic', 'Standard', or 'Premium'."
  }
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

variable "ddos_protection_plan" {
  type = object({
    enabled = optional(bool, false)
    name    = optional(string)
  })
  default     = {}
  description = "DDoS Protection Plan configuration."
}
