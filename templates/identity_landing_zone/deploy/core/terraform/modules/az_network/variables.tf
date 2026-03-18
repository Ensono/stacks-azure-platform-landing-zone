variable "resource_group_name" {
  description = "The name of the resource group where resources will be created"
  type        = string
}

variable "resource_group_location" {
  description = "The location/region where resources will be created"
  type        = string
}

variable "vnet_name" {
  description = "The name of the VNet"
  type        = string
}

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
  route_names                                   = optional(list(string), [])
  default_outbound_access_enabled               = optional(bool, false)
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

variable "resource_tags" {
  description = "A map of tags to assign to the resources"
  type        = map(string)
  default     = {}
}

variable "regional_virtual_hub_resource_id" {
  description = "The Azure resource id for the regional virtual hub"
  type        = string
}
