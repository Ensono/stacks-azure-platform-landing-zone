# Storage account for VNet flow logs
# This storage account is created in the management subscription to allow:
# 1. Centralized storage for flow logs from all connectivity VNets
# 2. Azure Policy-driven flow log configuration
# 3. Private endpoint access from connectivity subscription

module "flow_logs_storage" {
  source  = "Azure/avm-res-storage-storageaccount/azurerm"
  version = "0.6.1"

  depends_on = [module.resource_groups]

  # Only create storage when both flow_logs_storage is enabled AND management_resources_enabled
  count = var.management_resources_enabled && var.flow_logs_storage.enabled ? 1 : 0

  # Required attributes
  location            = var.location
  name                = coalesce(var.flow_logs_storage.name, local.resource_names.flow_logs_storage)
  resource_group_name = local.resource_names.resource_group

  # Optional attributes
  access_tier                   = var.flow_logs_storage.access_tier
  account_kind                  = var.flow_logs_storage.account_kind
  account_replication_type      = var.flow_logs_storage.account_replication_type
  account_tier                  = var.flow_logs_storage.account_tier
  enable_telemetry              = var.enable_avm_telemetry
  min_tls_version               = var.flow_logs_storage.min_tls_version
  public_network_access_enabled = var.flow_logs_storage.public_network_access
  shared_access_key_enabled     = var.flow_logs_storage.shared_access_key_enabled
  tags                          = merge(var.tags, var.flow_logs_storage.tags)

  # Blob service configuration for flow logs retention
  blob_properties = {
    container_delete_retention_policy = {
      days = var.flow_logs_storage.retention_days
    }
    delete_retention_policy = {
      days = var.flow_logs_storage.retention_days
    }
    versioning_enabled = true # AVM default for data protection
  }

  # Container for flow logs - Azure creates 'insights-logs-networksecuritygroupflowevent' automatically
  # but we create a container for organization
  containers = {
    flowlogs = {
      container_access_type = "private"
      name                  = "insights-logs-flowlogflowevent"
    }
  }

  # Network rules - default to deny all public access
  network_rules = var.flow_logs_storage.public_network_access ? null : {
    bypass                     = var.flow_logs_storage.network_rules.bypass
    default_action             = var.flow_logs_storage.network_rules.default_action
    ip_rules                   = var.flow_logs_storage.network_rules.ip_rules
    virtual_network_subnet_ids = var.flow_logs_storage.network_rules.virtual_network_subnet_ids
  }

  # Role assignments - allow deploying principal to write flow logs
  role_assignments = {
    storage_blob_contributor = {
      principal_id               = data.azurerm_client_config.current.object_id
      principal_type             = "ServicePrincipal"
      role_definition_id_or_name = "Storage Blob Data Contributor"
    }
  }

  # Note: Private endpoint is created by connectivity module to connect from hub VNet
}

# Lifecycle management policy for flow logs retention
resource "azurerm_storage_management_policy" "flow_logs" {
  # Only create when both flow_logs_storage is enabled AND management_resources_enabled
  count = var.management_resources_enabled && var.flow_logs_storage.enabled ? 1 : 0

  storage_account_id = module.flow_logs_storage[0].resource_id

  rule {
    enabled = true
    name    = "flow-logs-retention"

    actions {
      base_blob {
        delete_after_days_since_modification_greater_than = var.flow_logs_storage.retention_days
      }
    }

    filters {
      blob_types   = ["blockBlob"]
      prefix_match = ["insights-logs-"]
    }
  }
}
