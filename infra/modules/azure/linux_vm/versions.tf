terraform {
  required_version = ">= 1.6.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 5.9.0, < 6.0.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = ">= 4.4.1, < 5.0.0"
    }
  }
}
