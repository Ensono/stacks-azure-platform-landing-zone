module "hub_and_spoke_vnet" {
  source  = "Azure/avm-ptn-alz-connectivity-hub-and-spoke-vnet/azurerm"
  version = "0.16.8"

  hub_virtual_networks            = local.hub_virtual_networks
  hub_and_spoke_networks_settings = local.hub_and_spoke_settings
  enable_telemetry                = var.enable_avm_telemetry
  tags                            = var.tags
}
