module "config" {
  source = "./modules/config_templating"

  starter_locations               = var.starter_locations
  starter_locations_short         = var.starter_locations_short
  subscription_id_connectivity    = try(var.subscription_ids["connectivity"], "")
  subscription_id_identity        = try(var.subscription_ids["identity"], "")
  subscription_id_management      = var.subscription_ids["management"]
  subscription_id_security        = try(var.subscription_ids["security"], "")
  root_parent_management_group_id = var.root_parent_management_group_id

  custom_replacements = var.custom_replacements

  # Pass naming module outputs to be merged with custom_replacements.names
  naming_outputs = local.naming_outputs

  inputs = {
    management_resource_settings = var.management_resource_settings
    management_group_settings    = var.management_group_settings
    tags                         = var.tags
  }
}
