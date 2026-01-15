# =============================================================================
# Azure Regions Module
# =============================================================================
#
# Provides region metadata including:
#   - geo_code: Short region code (e.g., "uks" for UK South)
#   - zones: Available availability zones
#   - paired_region_name: DR paired region
#
# IMPORTANT:
# ----------
# Hub keys in var.hubs must be valid Azure region names (e.g., "uksouth").
# Invalid names will cause a lookup error during terraform plan.
#
# The is_recommended filter defaults to true, returning only Microsoft-
# recommended regions. Set to null to allow all regions.
#
# USAGE:
# ------
#   module.azure_regions.regions_by_name["uksouth"].geo_code  → "uks"
#   module.azure_regions.regions_by_name["uksouth"].zones     → ["1", "2", "3"]
#
# =============================================================================

module "azure_regions" {
  source  = "Azure/avm-utl-regions/azurerm"
  version = "0.9.3"

  enable_telemetry = var.enable_avm_telemetry
  geography_filter = var.region_geography
  is_recommended   = var.region_recommended_filter
}
