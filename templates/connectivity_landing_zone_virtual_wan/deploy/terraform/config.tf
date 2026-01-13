module "config" {
  source = "./modules/config_templating"

  starter_locations            = var.starter_locations
  starter_locations_short      = var.starter_locations_short
  subscription_id_connectivity = var.subscription_ids["connectivity"]

  custom_replacements = var.custom_replacements

  inputs = {
    connectivity_resource_groups = var.connectivity_resource_groups
    virtual_wan_settings         = var.virtual_wan_settings
    virtual_hubs                 = var.virtual_hubs
    tags                         = var.tags
    connectivity_tags            = var.connectivity_tags
  }
}
