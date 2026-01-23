provider "alz" {
  library_overwrite_enabled = true
  library_references = [
    {
      custom_url = "${path.root}/lib"
    }
  ]
}

provider "azapi" {
  enable_preflight = true

  skip_provider_registration = true
  subscription_id            = var.management_subscription_id
}

provider "azurerm" {
  resource_provider_registrations = "none"
  storage_use_azuread             = true
  subscription_id                 = var.management_subscription_id

  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}
