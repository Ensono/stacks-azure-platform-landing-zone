resource "random_string" "suffix" {
  length  = 8
  upper   = false
  special = false
}

module "spoke" {
  source  = "Azure/avm-res-network-virtualnetwork/azurerm"
  version = "0.5.0"

  name                = var.vnet_name
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name
  address_space       = var.vnet_address_space
  subnets             = var.vnet_subnets
  tags                = var.resource_tags
}

# VWan Connection to Regional Hub

resource "azurerm_virtual_hub_connection" "hub_connection" {
  name                      = "${var.vnet_name}-connection-${random_string.suffix.result}"
  virtual_hub_id            = var.regional_virtual_hub_resource_id
  remote_virtual_network_id = module.spoke.resource_id
  internet_security_enabled = true
}
