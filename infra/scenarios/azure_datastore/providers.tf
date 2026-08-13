provider "azurerm" {
  features {
    enhanced_validation {
      locations          = true
      resource_providers = true
    }
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
    key_vault {
      purge_soft_delete_on_destroy = true
    }
  }

  resource_provider_registrations = "none"
  resource_providers_to_register = [
    "Microsoft.DBforPostgreSQL",
    "Microsoft.DocumentDB",
    "Microsoft.KeyVault",
    "Microsoft.Monitor",
    "Microsoft.Resources",
    "Microsoft.Storage",
  ]
}
