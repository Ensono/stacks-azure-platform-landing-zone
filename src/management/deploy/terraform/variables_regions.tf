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
