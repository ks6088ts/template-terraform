terraform {
  required_version = ">= 1.11.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 5.0"
    }
    azapi = {
      source  = "Azure/azapi"
      version = "2.8.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.8.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.13"
    }
  }
}
