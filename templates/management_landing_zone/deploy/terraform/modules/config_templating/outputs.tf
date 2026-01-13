output "custom_replacements" {
  value = local.final_replacements
}

output "outputs" {
  value = local.outputs
}

output "starter_locations_short" {
  value       = local.starter_locations_short
  description = "Map of starter location short codes (e.g., starter_location_01_short => 'uks')"
}
