provider "azapi" {
  enable_preflight = true

  skip_provider_registration = true
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }

  resource_provider_registrations = "none"
  storage_use_azuread             = true
}
