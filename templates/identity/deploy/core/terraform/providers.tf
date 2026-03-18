provider "azurerm" {
  storage_use_azuread = true

  features {
    resource_group {
      # Allow deletion of resource groups that contain resources not managed by Terraform
      # Required for destroy operations when Azure creates resources (e.g., Recovery Services Vault)
      prevent_deletion_if_contains_resources = false
    }
  }
}

# NOTE: Connectivity provider removed - Private DNS zone integration now handled by
# Azure Policy (DINE) at management group level instead of cross-subscription Terraform
