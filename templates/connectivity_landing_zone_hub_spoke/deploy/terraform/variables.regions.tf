# =============================================================================
# Region Variables
# =============================================================================
#
# Configuration for the Azure regions module (avm-utl-regions). These settings
# filter which regions are available for hub deployment and provide region
# metadata like short names for resource naming.
#
# EXAMPLES:
# ---------
# All regions worldwide:      region_geography = null
# United Kingdom only:        region_geography = "United Kingdom"
# Europe (all):               region_geography = "Europe"
# Asia Pacific:               region_geography = "Asia Pacific"
#
# See: https://azure.microsoft.com/explore/global-infrastructure/geographies
#
# =============================================================================

variable "region_geography" {
  type        = string
  default     = null
  description = "Filter available regions by geography. Common values: 'United Kingdom', 'Europe', 'United States', 'Asia Pacific'. Set to null for all geographies."
}

variable "region_recommended_filter" {
  type        = bool
  default     = null
  description = "Filter by Microsoft-recommended regions. Set to true for recommended only, false for non-recommended only, or null (default) for all regions."
}
