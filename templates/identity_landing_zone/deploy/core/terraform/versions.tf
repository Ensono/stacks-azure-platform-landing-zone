terraform {
  # Terraform >= 1.10.0 required for ephemeral resources
  required_version = ">= 1.10.0, < 2"

  backend "azurerm" {
    use_azuread_auth = true
  }

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.46.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2.4"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.6.0, < 4.0.0"
    }
    time = {
      source  = "hashicorp/time"
      version = ">= 0.9.0"
    }
    azapi = {
      source  = "azure/azapi"
      version = "~> 2.0"
    }
  }
}
