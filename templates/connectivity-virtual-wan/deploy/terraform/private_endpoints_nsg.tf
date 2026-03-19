# Network Security Group for Private Endpoints Subnet
# Provides: Centralized access control, logging via NSG flow logs, compliance visibility
# Recommendation: https://learn.microsoft.com/en-us/azure/architecture/networking/guide/private-link-virtual-wan-dns-guide

module "nsg_private_endpoints" {
  source  = "Azure/avm-res-network-networksecuritygroup/azurerm"
  version = "0.5.1"
  for_each = {
    for region, hub in local.enabled_hubs : region => hub
    if var.private_endpoints_nsg.enabled && hub.features.sidecar_virtual_network && var.azure_monitor_private_link.enabled
  }

  name                = module.naming["hub-${each.key}"].network_security_group.name
  location            = each.key
  resource_group_name = module.resource_groups["hub-${each.key}"].name
  enable_telemetry    = var.enable_avm_telemetry
  tags                = merge(var.tags, each.value.tags)

  security_rules = {
    allow_vnet_inbound = {
      name                       = "AllowVNetInbound"
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "VirtualNetwork"
      destination_address_prefix = "VirtualNetwork"
    }
    deny_internet_inbound = {
      name                       = "DenyInternetInbound"
      priority                   = 4096
      direction                  = "Inbound"
      access                     = "Deny"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "Internet"
      destination_address_prefix = "*"
    }
  }
}

# Associate NSG with private endpoints subnet
resource "azurerm_subnet_network_security_group_association" "private_endpoints" {
  for_each = {
    for region, hub in local.enabled_hubs : region => hub
    if var.private_endpoints_nsg.enabled && hub.features.sidecar_virtual_network && var.azure_monitor_private_link.enabled
  }

  subnet_id                 = "${module.virtual_wan.sidecar_virtual_network_resource_ids[each.key]}/subnets/snet-private-endpoints"
  network_security_group_id = module.nsg_private_endpoints[each.key].resource_id

  depends_on = [module.virtual_wan]
}
