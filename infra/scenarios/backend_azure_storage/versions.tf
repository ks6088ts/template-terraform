terraform {
  required_version = ">= 1.6.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.22.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.8.0"
    }
  }
}
