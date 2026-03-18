resource "random_string" "suffix" {
  length  = 8
  upper   = false
  special = false
}

module "spoke" {
  source              = "git::https://github.com/Ensono/terraform-azurerm-evm-vnet?ref=0.2.3"
  resource_group_name = var.resource_group_name
  azure_location      = var.resource_group_location
  vnet_name           = var.vnet_name
  address_space       = var.vnet_address_space
  subnets             = var.vnet_subnets
  nsg_rules           = local.vnet_nsg_rules
  enable_route_tables = true # Empty route tables - routes will come from VWAN routing intent
  azure_resource_tags = var.resource_tags
}

# VWan Connection to Regional Hub

resource "azurerm_virtual_hub_connection" "hub_connection" {
  name                      = "${var.vnet_name}-connection-${random_string.suffix.result}"
  virtual_hub_id            = var.regional_virtual_hub_resource_id
  remote_virtual_network_id = module.spoke.vnet_resource_id
  internet_security_enabled = true

  depends_on = [
    module.spoke
  ]
}
