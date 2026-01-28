module "virtual_wan" {
  source  = "Azure/avm-ptn-alz-connectivity-virtual-wan/azurerm"
  version = "0.13.5"

  virtual_wan_settings = local.virtual_wan_settings
  virtual_hubs         = local.virtual_hubs
  enable_telemetry     = var.enable_avm_telemetry
  tags                 = var.tags

  depends_on = [module.resource_groups]
}
