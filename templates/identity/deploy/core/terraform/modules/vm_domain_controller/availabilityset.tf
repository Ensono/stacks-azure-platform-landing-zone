resource "azurerm_availability_set" "domain_controller_aset" {
  # Dynamically create exactly one availability set only if the region has no zones
  count = length(var.region.zones) == 0 ? 1 : 0

  name                         = var.availability_set_name
  location                     = var.resource_group_location
  resource_group_name          = var.resource_group_name
  platform_update_domain_count = var.availability_set_config.platform_update_domain_count
  platform_fault_domain_count  = var.availability_set_config.platform_fault_domain_count
  managed                      = var.availability_set_config.managed
  tags                         = var.tags
}
