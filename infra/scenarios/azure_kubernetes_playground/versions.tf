terraform {
  required_version = ">= 1.6.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 5.0.1, < 6.0.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.8.0"
    }
  }
}
