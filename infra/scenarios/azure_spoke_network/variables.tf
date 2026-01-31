variable "name" {
  description = "Specifies the base name for resources"
  type        = string
  default     = "azurespokenetwork"
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "japaneast"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default = {
    scenario        = "azure_spoke_network"
    owner           = "ks6088ts"
    SecurityControl = "Ignore"
    CostControl     = "Ignore"
  }
}

# -------------------------------------------------------------------
# Network Configuration
# -------------------------------------------------------------------

variable "vnet_address_space" {
  description = "Address space for the spoke VNet"
  type        = list(string)
  default     = ["10.1.0.0/16"]
}

variable "subnet_bastion_address_prefixes" {
  description = "Address prefixes for the Bastion subnet (must be /26 or larger)"
  type        = list(string)
  default     = ["10.1.0.0/26"]
}

variable "subnet_paas_address_prefixes" {
  description = "Address prefixes for the PaaS (Private Endpoint) subnet"
  type        = list(string)
  default     = ["10.1.1.0/24"]
}

variable "subnet_vm_address_prefixes" {
  description = "Address prefixes for the VM subnet"
  type        = list(string)
  default     = ["10.1.2.0/24"]
}

# -------------------------------------------------------------------
# Storage Account Configuration
# -------------------------------------------------------------------

variable "storage_account_tier" {
  description = "Storage account tier"
  type        = string
  default     = "Standard"

  validation {
    condition     = contains(["Standard", "Premium"], var.storage_account_tier)
    error_message = "Storage account tier must be Standard or Premium."
  }
}

variable "storage_account_replication_type" {
  description = "Storage account replication type"
  type        = string
  default     = "LRS"

  validation {
    condition     = contains(["LRS", "GRS", "RAGRS", "ZRS", "GZRS", "RAGZRS"], var.storage_account_replication_type)
    error_message = "Storage account replication type must be one of: LRS, GRS, RAGRS, ZRS, GZRS, RAGZRS."
  }
}

# -------------------------------------------------------------------
# VM Configuration
# -------------------------------------------------------------------

variable "vm_size" {
  description = "Size of the virtual machine"
  type        = string
  default     = "Standard_B2s"
}

variable "vm_admin_username" {
  description = "Admin username for the virtual machine"
  type        = string
  default     = "azureuser"

  validation {
    condition     = length(var.vm_admin_username) >= 1 && length(var.vm_admin_username) <= 64
    error_message = "Admin username must be between 1 and 64 characters."
  }
}

variable "vm_os_disk_size_gb" {
  description = "OS disk size in GB"
  type        = number
  default     = 30

  validation {
    condition     = var.vm_os_disk_size_gb >= 30 && var.vm_os_disk_size_gb <= 4095
    error_message = "OS disk size must be between 30 and 4095 GB."
  }
}

variable "vm_os_disk_type" {
  description = "OS disk storage account type"
  type        = string
  default     = "Standard_LRS"

  validation {
    condition     = contains(["Standard_LRS", "StandardSSD_LRS", "Premium_LRS", "StandardSSD_ZRS", "Premium_ZRS"], var.vm_os_disk_type)
    error_message = "OS disk type must be one of: Standard_LRS, StandardSSD_LRS, Premium_LRS, StandardSSD_ZRS, Premium_ZRS."
  }
}

# -------------------------------------------------------------------
# Bastion Configuration
# -------------------------------------------------------------------

variable "bastion_sku" {
  description = "SKU for Azure Bastion"
  type        = string
  default     = "Basic"

  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.bastion_sku)
    error_message = "Bastion SKU must be Basic, Standard, or Premium."
  }
}
