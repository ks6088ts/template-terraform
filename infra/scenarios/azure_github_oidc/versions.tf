terraform {
  required_version = ">= 1.6.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 5.9.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 3.10.0"
    }
  }
}
