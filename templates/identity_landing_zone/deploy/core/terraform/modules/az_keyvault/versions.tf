terraform {
  required_version = ">= 1.10.0"

  required_providers {
  azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.0.0"
  }
  time = {
      source  = "hashicorp/time"
      version = ">= 0.9.0"
  }
  random = {
      source  = "hashicorp/random"
      version = ">= 3.5.0"
  }
  }
}
