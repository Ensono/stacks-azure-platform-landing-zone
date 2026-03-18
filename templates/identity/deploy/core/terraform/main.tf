resource "random_string" "random_seed" {
  length  = 3
  special = false
  upper   = false
  numeric = false
}

module "azure_regions" {
  source  = "Azure/avm-utl-regions/azurerm"
  version = "0.9.3"

  enable_telemetry = var.enable_avm_telemetry
}

module "naming" {
  source   = "Azure/naming/azurerm"
  version  = "0.4.3"
  for_each = var.component_names

  unique-seed = random_string.random_seed.result

  suffix = [
    substr(var.company_name, 0, 3),
    local.selected_region.geo_code,
    var.environment,
    each.key,
    "001"
  ]
}

module "remote_state" {
  source = "./modules/tf_remote_state"

  workspace_name       = terraform.workspace
  remote_state_configs = var.remote_state_configs
}

module "resource_groups" {
  source  = "Azure/avm-res-resources-resourcegroup/azurerm"
  version = "0.2.1"

  for_each = var.component_names

  location = var.azure_location
  name     = module.naming[each.key].resource_group.name
  tags     = local.resource_tags

  lock = var.azure_resource_group_management_lock_level != "" ? {
    kind = var.azure_resource_group_management_lock_level
    name = "resource-group-level"
  } : null
}

module "network" {
  source = "./modules/az_network"

  vnet_name                        = module.naming["networking"].virtual_network.name
  vnet_address_space               = var.vnet_address_space
  vnet_subnets                     = var.vnet_subnets
  vnet_nsg_rules                   = var.vnet_nsg_rules
  resource_group_name              = module.resource_groups["networking"].name
  resource_group_location          = var.azure_location
  regional_virtual_hub_resource_id = local.regional_virtual_hub_resource_id
  resource_tags                    = local.resource_tags
}

module "vm_domain_controller" {
  source = "./modules/vm_domain_controller"

  resource_group_name     = module.resource_groups["adds"].name
  resource_group_location = var.azure_location
  subnet_resource_id      = module.network.subnets["subn-activedirectory-1"].resource_id
  tags                    = local.resource_tags
  vms                     = var.vms
  vm_settings             = var.vm_settings
  region                  = local.selected_region

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

  key_vault_name             = module.naming["adds"].key_vault.name
  location                   = var.azure_location
  resource_group_name        = module.resource_groups["adds"].name
  tenant_id                  = data.azurerm_client_config.this.tenant_id
  deployment_principal_id    = data.azurerm_client_config.this.object_id
  private_endpoint_subnet_id = module.network.subnets["subn-privateendpoint-1"].resource_id
  tags                       = local.resource_tags

  depends_on = [module.resource_groups, module.network]
}

# Update VNet DNS settings to use domain controllers after they are created
# Update DNS servers on existing virtual network using Terraform resource
# DNS order: current region first, then remote region
resource "azurerm_virtual_network_dns_servers" "vnet_dns" {
  virtual_network_id = module.network.vnet_id
  dns_servers        = local.identity_vnet_dns_servers

  lifecycle {
    precondition {
      condition     = length(local.identity_vnet_dns_servers) > 0
      error_message = "ADR #0113 requires identity_vnet_dns_servers to resolve to at least one DNS proxy IP. Configure identity_vnet_dns_servers or provide connectivity remote state outputs."
    }
  }

  depends_on = [module.vm_domain_controller, module.network]
}

resource "terraform_data" "adds_dns_forwarder_guardrail" {
  input = local.adds_dns_forwarders

  lifecycle {
    precondition {
      condition     = length(local.adds_dns_forwarders) > 0
      error_message = "ADR #0113 requires ADDS DNS forwarders for onward resolution. Configure adds_dns_forwarders or ensure identity_vnet_dns_servers is populated."
    }
  }
}

resource "azurerm_virtual_machine_extension" "adds_dns_forwarders" {
  for_each = length(local.adds_dns_forwarders) == 0 ? {} : module.vm_domain_controller.vm_resource_ids

  name                       = "configure-adds-dns-forwarders"
  virtual_machine_id         = each.value
  publisher                  = "Microsoft.Compute"
  type                       = "CustomScriptExtension"
  type_handler_version       = "1.10"
  auto_upgrade_minor_version = true

  settings = jsonencode({
    commandToExecute = "powershell -ExecutionPolicy Bypass -Command \"$forwarders = @(${join(",", formatlist("'%s'", local.adds_dns_forwarders))}); if (Get-Command Add-DnsServerForwarder -ErrorAction SilentlyContinue) { Add-DnsServerForwarder -IPAddress $forwarders -UseRootHint `$false -ErrorAction SilentlyContinue | Out-Null }\""
  })

  depends_on = [module.vm_domain_controller, terraform_data.adds_dns_forwarder_guardrail]
}

resource "azurerm_role_assignment" "identity_admin" {
  for_each = var.identity_admin_role_assignments

  principal_id         = each.value.principal_id
  role_definition_name = each.value.role_definition_name
  scope                = local.identity_admin_scopes[each.value.scope]

  depends_on = [module.resource_groups, module.key_vault]
}
