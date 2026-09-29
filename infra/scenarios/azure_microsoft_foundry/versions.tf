terraform {
  required_version = ">= 1.11.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 5.7.0"
    }
    azapi = {
      source  = "Azure/azapi"
      version = "2.13.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.9.1"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.14.2"
    }
  }
}
