provider "alz" {
  library_overwrite_enabled = true
  library_references = [
    {
      custom_url = "${path.root}/lib"
    }
  ]
}

provider "azapi" {
  skip_provider_registration = true
  subscription_id            = var.subscription_ids["management"]
}

provider "azurerm" {
  resource_provider_registrations = "none"
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}
