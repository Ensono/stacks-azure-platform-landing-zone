module "az_naming" {
  source = "git::https://github.com/FiveB-Infra/fb-naming.git?ref=v2025.11.21.6"

  component_names    = var.component_names
  company_name_short = var.lz_short_code
  azure_location     = var.azure_location
  environment        = var.environment

}

module "tagging" {
  source = "git::https://github.com/FiveB-Infra/fb-tagging.git?ref=v2025.10.10.7"

  ProductDomain   = var.ProductDomain
  Application     = var.Application
  ApplicationCode = var.ApplicationCode
  Environment     = var.Environment
  Role            = var.Role
  Criticality     = var.Criticality
  CostCode        = var.CostCode
  Owner           = var.Owner
  CreatedOn       = var.CreatedOn
  CreatedBy       = var.CreatedBy
  Monitoring      = var.Monitoring
}

module "remote_state" {
  source = "./modules/tf_remote_state"

  workspace_name = terraform.workspace
  remote_state_configs = {
    # Management remote states
    "management_eastus2" = {
      storage_account_name = "steus2manprdtfstatecig"
      container_name       = "tfstate"
      key                  = "management/core"
      use_azuread_auth     = true
    }
    "management_centralus" = {
      storage_account_name = "stcusmanprdtfstatejqp"
      container_name       = "tfstate"
      key                  = "management/core"
      use_azuread_auth     = true
    }

    # Connectivity remote states
    "connectivity_eastus2" = {
      storage_account_name = "steus2conprdtfstatewee"
      container_name       = "tfstate"
      key                  = "connectivity/core"
      use_azuread_auth     = true
    }
    "connectivity_centralus" = {
      storage_account_name = "stcusconprdtfstatensj"
      container_name       = "tfstate"
      key                  = "connectivity/core"
      use_azuread_auth     = true
    }

    # Identity remote states
    "identity_eastus2" = {
      storage_account_name = "steus2ideprdtfstatehe1"
      container_name       = "tfstate"
      key                  = "identity/core"
      use_azuread_auth     = true
    }
    "identity_centralus" = {
      storage_account_name = "stcusideprdtfstateaee"
      container_name       = "tfstate"
      key                  = "identity/core"
      use_azuread_auth     = true
    }
  }
}

module "resource_groups" {
  source  = "Azure/avm-res-resources-resourcegroup/azurerm"
  version = "0.2.1"

  for_each = var.component_names

  location = var.azure_location
  name     = module.az_naming.naming_map[each.key].resource_group.name
  tags     = module.tagging.resource_tags

  lock = var.azure_resource_group_management_lock_level != "" ? {
    kind = var.azure_resource_group_management_lock_level
    name = "resource-group-level"
  } : null
}

module "network" {
  source = "./modules/az_network"

  vnet_name                        = module.az_naming.naming_map["networking"].virtual_network.name
  vnet_address_space               = var.vnet_address_space
  vnet_subnets                     = var.vnet_subnets
  vnet_nsg_rules                   = var.vnet_nsg_rules
  resource_group_name              = module.resource_groups["networking"].name
  resource_group_location          = var.azure_location
  regional_virtual_hub_resource_id = local.regional_virtual_hub_resource_id
  resource_tags                    = module.tagging.resource_tags
}

module "vm_domain_controller" {
  source = "./modules/vm_domain_controller"

  resource_group_name     = module.resource_groups["adds"].name
  resource_group_location = var.azure_location
  subnet_resource_id      = module.network.subnets["subn-activedirectory-1"].resource_id
  tags                    = module.tagging.resource_tags
  vms                     = var.vms
  vm_settings             = var.vm_settings
  region                  = module.az_naming.region

  # HLD-compliant VM naming (A2PW000DC01 format)
  vm_name_map           = local.vm_name_map
  vm_extend_name_map    = local.vm_extend_name_map
  availability_set_name = local.vm_availability_set_name

  # Admin credentials - temp password replaced via Azure CLI after creation
  admin_username      = var.vm_admin_username
  admin_temp_password = length(var.vms) > 0 ? random_password.vm_admin_temp[0].result : ""

  depends_on = [module.network]
}

#------------------------------------------------------------------------------
# Key Vault for storing VM admin credentials
# Uses local module - ephemeral password management in password.tf
#------------------------------------------------------------------------------

module "key_vault" {
  source = "./modules/az_keyvault"

  key_vault_name             = module.az_naming.naming_map["adds"].key_vault.name
  location                   = var.azure_location
  resource_group_name        = module.resource_groups["adds"].name
  tenant_id                  = data.azurerm_client_config.this.tenant_id
  deployment_principal_id    = data.azurerm_client_config.this.object_id
  private_endpoint_subnet_id = module.network.subnets["subn-privateendpoint-1"].resource_id
  tags                       = module.tagging.resource_tags

  depends_on = [module.resource_groups, module.network]
}

# Update VNet DNS settings to use domain controllers after they are created
# Update DNS servers on existing virtual network using Terraform resource
# DNS order: current region first, then remote region
resource "azurerm_virtual_network_dns_servers" "vnet_dns" {
  virtual_network_id = module.network.vnet_id
  dns_servers        = local.dns_servers

  depends_on = [module.vm_domain_controller, module.network]
}
