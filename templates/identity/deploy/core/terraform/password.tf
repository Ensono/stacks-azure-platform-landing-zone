#------------------------------------------------------------------------------
# VM Admin Password (Ephemeral - NOT stored in Terraform state)
# Ephemeral resources must be in root module, not child modules
# Requires: Terraform >= 1.10.0, Azure CLI
#------------------------------------------------------------------------------

# MIGRATION: Remove old azapi_resource from state without destroying Azure resources
# These were replaced with terraform_data + az rest to avoid 405 DELETE errors
# The 'removed' block tells Terraform to forget about these without calling DELETE
# Can be removed after one successful apply
removed {
  from = azapi_resource.vm_admin_password

  lifecycle {
    destroy = false
  }
}

removed {
  from = azapi_resource.vm_admin_username

  lifecycle {
    destroy = false
  }
}

# Temporary password for VM creation (replaced immediately via Azure CLI)
# This IS in state but becomes stale immediately after creation
resource "random_password" "vm_admin_temp" {
  count            = length(var.vms) > 0 ? 1 : 0
  length           = 32
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
  min_lower        = 4
  min_upper        = 4
  min_numeric      = 4
  min_special      = 2

  lifecycle {
    ignore_changes = all
  }
}

# Ephemeral password - NEVER stored in state
# Must be in root module - child modules cannot have ephemeral outputs
ephemeral "random_password" "vm_admin" {
  length           = 32
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
  min_lower        = 4
  min_upper        = 4
  min_numeric      = 4
  min_special      = 2
}

# Update VM passwords via Azure CLI after VM creation or password rotation
# This replaces the temp password with the ephemeral password
# Triggers on: VM recreation OR password version change
resource "terraform_data" "vm_password_update" {
  for_each = var.vms

  triggers_replace = [
    module.vm_domain_controller.vm_resource_ids[each.key],
    var.vm_password_version
  ]

  provisioner "local-exec" {
    # Azure CLI requires explicit login in containerized environments
    # ARM_* env vars are available in container but CLI doesn't auto-login from them
    # Using shell variables ($VAR) - NOT stored in state, resolved at runtime
    command = <<-EOT
      az login --service-principal \
  -u "$ARM_CLIENT_ID" \
  -p "$ARM_CLIENT_SECRET" \
  --tenant "$ARM_TENANT_ID" \
  --output none && \
      az vm user update \
  --resource-group "${module.resource_groups["adds"].name}" \
  --name "${local.vm_name_map[each.key]}" \
  --username "${var.vm_admin_username}" \
  --password "$VM_ADMIN_PASSWORD" \
  --output none
  EOT

    # VM_ADMIN_PASSWORD is ephemeral - NEVER stored in state
    environment = {
      VM_ADMIN_PASSWORD = ephemeral.random_password.vm_admin.result
    }

    interpreter = ["bash", "-c"]
  }

  depends_on = [module.vm_domain_controller]
}

# Ensure DNS is ready before creating secrets
# The input reference creates an explicit dependency on module.key_vault.dns_wait_id
resource "terraform_data" "key_vault_dns_ready" {
  input = module.key_vault.dns_wait_id
}

# Store password in Key Vault using value_wo (write-only - value never in state)
# Only updates when vm_password_version is incremented - stays in sync with VM
resource "azurerm_key_vault_secret" "vm_admin_password" {
  count = length(var.vms) > 0 ? 1 : 0

  name            = "vm-admin-password"
  key_vault_id    = module.key_vault.resource_id
  content_type    = "password"
  expiration_date = timeadd(timestamp(), "2160h") # 90 days - Azure Policy max validity

  # value_wo = write-only, value NEVER stored in Terraform state
  # value_wo_version controls when secret is updated - MUST match vm_password_version
  # to ensure Key Vault and VM passwords stay in sync
  value_wo         = ephemeral.random_password.vm_admin.result
  value_wo_version = var.vm_password_version

  lifecycle {
    # Prevent recreation on every run - only update when version changes
    ignore_changes = [tags, expiration_date]
    # Replace when password version changes (handled by value_wo_version)
  }

  depends_on = [
    terraform_data.vm_password_update, # Ensure VM is updated BEFORE Key Vault
    terraform_data.key_vault_dns_ready,
    module.key_vault
  ]
}

# Store admin username in Key Vault (consistent pattern)
resource "azurerm_key_vault_secret" "vm_admin_username" {
  count = length(var.vms) > 0 ? 1 : 0

  name            = "vm-admin-username"
  key_vault_id    = module.key_vault.resource_id
  value           = var.vm_admin_username
  content_type    = "username"
  expiration_date = timeadd(timestamp(), "2160h") # 90 days - Azure Policy max validity

  lifecycle {
    ignore_changes = [tags, expiration_date]
  }

  depends_on = [
    terraform_data.key_vault_dns_ready,
    module.key_vault
  ]
}
