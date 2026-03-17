terraform {
  required_version = ">= 1, < 2"

  required_providers {
    alz = {
      source  = "Azure/alz"
      version = "0.20.2"
    }
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }

  backend "azurerm" {
    use_azuread_auth = true
  }
}
