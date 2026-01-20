provider "azapi" {
  enable_preflight = true

  skip_provider_registration = true
}

provider "azurerm" {
  storage_use_azuread = true

  resource_provider_registrations = "none"

  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}
