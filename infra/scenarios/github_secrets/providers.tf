provider "github" {
  owner = var.github_owner
}

# NOTE: When using the backend azurerm, the azurerm provider must be declared even if not used directly.
provider "azurerm" {
  features {}
}
