module "management_resources" {
  source  = "Azure/avm-ptn-alz-management/azurerm"
  version = "0.9.0"

  depends_on = [module.resource_groups]
  count      = var.management_resources_enabled ? 1 : 0

  # Required attributes
  location                     = var.location
  log_analytics_workspace_name = local.resource_names.log_analytics_workspace
  resource_group_name          = local.resource_names.resource_group

  # Computed attributes
  automation_account_name                              = null
  data_collection_rules                                = var.management_resource_settings.data_collection_rules
  enable_telemetry                                     = var.enable_avm_telemetry
  linked_automation_account_creation_enabled           = false
  log_analytics_workspace_internet_ingestion_enabled   = var.management_resource_settings.log_analytics_workspace_internet_ingestion_enabled
  log_analytics_workspace_internet_query_enabled       = var.management_resource_settings.log_analytics_workspace_internet_query_enabled
  log_analytics_workspace_local_authentication_enabled = var.management_resource_settings.log_analytics_workspace_local_authentication_enabled
  resource_group_creation_enabled                      = false
  tags                                                 = merge(var.tags, try(var.management_resource_settings.tags, null))
  user_assigned_managed_identities                     = var.management_resource_settings.user_assigned_managed_identities
}
