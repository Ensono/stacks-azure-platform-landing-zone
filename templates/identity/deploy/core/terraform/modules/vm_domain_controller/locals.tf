locals {
  # Determine if the selected region has zones (3+ zones required)
  region_supports_zones = length(var.region.zones) >= 3
}
