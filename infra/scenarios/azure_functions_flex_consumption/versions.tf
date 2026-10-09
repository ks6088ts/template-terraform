terraform {
  required_version = ">= 1.6.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 5.8.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 3.10.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.9.1"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.8.1"
    }
  }
}
