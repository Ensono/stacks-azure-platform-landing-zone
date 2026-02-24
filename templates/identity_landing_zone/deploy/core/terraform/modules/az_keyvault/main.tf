#------------------------------------------------------------------------------
# Key Vault Module for Identity Landing Zone
# Uses AVM module - ephemeral password management stays in root module
#------------------------------------------------------------------------------

module "key_vault" {
  source  = "Azure/avm-res-keyvault-vault/azurerm"
  version = "0.10.0"

  name                = var.key_vault_name
  location            = var.location
  resource_group_name = var.resource_group_name
  tenant_id           = var.tenant_id

  # Security settings - hardened for Identity LZ
  enable_telemetry                = false
  public_network_access_enabled   = false
  enabled_for_disk_encryption     = false
  enabled_for_deployment          = false
  enabled_for_template_deployment = false
  purge_protection_enabled        = true
  soft_delete_retention_days      = 90
  sku_name                        = "standard"
  legacy_access_policies_enabled  = false

  # Disable trusted Azure services bypass - private endpoint only
  network_acls = {
    bypass         = "None"
    default_action = "Deny"
  }

  wait_for_rbac_before_secret_operations = {
    create = "60s"
  }

  # RBAC for deployment identity
  role_assignments = {
    deployment_identity = {
      role_definition_id_or_name = "Key Vault Secrets Officer"
      principal_id               = var.deployment_principal_id
      principal_type             = "ServicePrincipal"
    }
  }

  # DNS zone group is managed by Azure Policy (DINE) at management group level
  # Policy: "Configure Azure Key Vaults to use private DNS zones"
  private_endpoints_manage_dns_zone_group = false

  # Private endpoint for Key Vault
  private_endpoints = {
    vault = {
      name                            = "pep-${var.key_vault_name}"
      subnet_resource_id              = var.private_endpoint_subnet_id
      private_service_connection_name = "psc-${var.key_vault_name}"
      network_interface_name          = "nic-${var.key_vault_name}"
      tags                            = var.tags
    }
  }

  tags = var.tags
}

#------------------------------------------------------------------------------
# Wait for Azure Policy to create DNS record for Private Endpoint
# DINE policy is asynchronous - blind wait for policy evaluation cycle
# TODO: Add DNS polling when Identity SPN has Reader on Connectivity sub
#------------------------------------------------------------------------------
resource "time_sleep" "wait_for_dns_policy" {
  depends_on = [module.key_vault]

  triggers = {
    private_endpoint_id = module.key_vault.private_endpoints["vault"].id
  }

  # Wait for Azure Policy to detect PE and create DNS zone group
  # DINE policy can take 5-10 minutes depending on Azure Policy evaluation cycles
  # Increased to 10 minutes to ensure DNS is fully propagated before secret operations
  create_duration = "600s"
}
