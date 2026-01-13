module "regions" {
  source          = "Azure/avm-utl-regions/azurerm"
  version         = "0.9.3"
  use_cached_data = false

  enable_telemetry = var.enable_telemetry
}

data "azurerm_client_config" "current" {}
