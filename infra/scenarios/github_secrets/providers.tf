provider "github" {
  owner = var.organization
}

# NOTE: When using the backend azurerm, the azurerm provider must be declared even if not used directly.
provider "azurerm" {
  features {}
}
