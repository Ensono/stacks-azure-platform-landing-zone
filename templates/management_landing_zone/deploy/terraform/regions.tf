module "azure_regions" {
  source  = "Azure/avm-utl-regions/azurerm"
  version = "0.9.3"

  enable_telemetry = var.enable_avm_telemetry
  geography_filter = var.region_geography
  is_recommended   = var.region_recommended_filter
}
