variable "name" {
  description = "Base name for the Bastion resources"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region for resources"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "subnet_id" {
  description = "ID of the AzureBastionSubnet"
  type        = string
}

variable "sku" {
  description = "SKU for Azure Bastion"
  type        = string
  default     = "Basic"

  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.sku)
    error_message = "Bastion SKU must be Basic, Standard, or Premium."
  }
}
