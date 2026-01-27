# Flow logs storage account - one per hub region
# https://learn.microsoft.com/en-us/azure/network-watcher/vnet-flow-logs-overview#considerations-for-virtual-network-flow-logs

locals {
  # Use created storage account or externally provided ID
  flow_logs_storage_account_ids = var.flow_logs.enabled ? {
    for region in keys(local.enabled_hubs) : region => (
      var.flow_logs.storage.create
      ? module.flow_logs_storage[region].resource_id
      : var.flow_logs.storage.external_storage_account_id
    )
  } : {}
}

module "flow_logs_storage" {
  source   = "Azure/avm-res-storage-storageaccount/azurerm"
  version  = "0.6.7"
  for_each = var.flow_logs.enabled && var.flow_logs.storage.create ? local.enabled_hubs : {}

  # Required attributes - storage account in same region as hub VNet
  location            = each.key
  name                = local.hub_names[each.key].flow_logs_storage
  resource_group_name = module.resource_groups["hub-${each.key}"].name

  # Storage account configuration
  access_tier               = var.flow_logs.storage.access_tier
  account_kind              = var.flow_logs.storage.account_kind
  account_replication_type  = var.flow_logs.storage.account_replication_type
  account_tier              = var.flow_logs.storage.account_tier
  enable_telemetry          = var.enable_avm_telemetry
  min_tls_version           = var.flow_logs.storage.min_tls_version
  shared_access_key_enabled = var.flow_logs.storage.shared_access_key_enabled
  tags                      = merge(var.tags, each.value.tags)

  public_network_access_enabled = var.flow_logs.storage.public_network_access

  # Blob service configuration - soft delete for accidental deletion protection
  blob_properties = {
    container_delete_retention_policy = {
      days = var.flow_logs.storage.retention_days
    }
    delete_retention_policy = {
      days = var.flow_logs.storage.retention_days
    }
    versioning_enabled = false # Not needed for flow logs
  }

  # Network rules - allow trusted Azure services for flow logs ingestion
  network_rules = var.flow_logs.storage.public_network_access ? null : {
    bypass                     = ["AzureServices"] # Required for flow logs
    default_action             = "Deny"
    ip_rules                   = var.flow_logs.storage.network_rules.ip_rules
    virtual_network_subnet_ids = var.flow_logs.storage.network_rules.virtual_network_subnet_ids
  }

  # Role assignments - allow deploying principal to configure flow logs
  role_assignments = {
    storage_blob_contributor = {
      principal_id               = data.azurerm_client_config.current.object_id
      principal_type             = "ServicePrincipal"
      role_definition_id_or_name = "Storage Blob Data Contributor"
    }
  }

  depends_on = [module.resource_groups]
}

# Lifecycle management policy for flow logs blob retention
# Note: This is storage-level blob lifecycle (var.flow_logs.storage.retention_days)
# Separate from flow log data retention (var.flow_logs.retention_days) which controls Network Watcher retention
resource "azurerm_storage_management_policy" "flow_logs" {
  for_each = var.flow_logs.enabled && var.flow_logs.storage.create ? local.enabled_hubs : {}

  storage_account_id = module.flow_logs_storage[each.key].resource_id

  rule {
    enabled = true
    name    = "flow-logs-retention"

    actions {
      base_blob {
        delete_after_days_since_modification_greater_than = var.flow_logs.storage.retention_days
      }
    }

    filters {
      blob_types   = ["blockBlob"]
      prefix_match = ["insights-logs-"]
    }
  }
}
