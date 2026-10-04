variable "name" {
  description = "Base name used for Azure resources"
  type        = string
  default     = "azurehubspoke"

  validation {
    condition     = can(regex("^[a-z0-9-]{3,35}$", var.name))
    error_message = "Name must contain 3 to 35 lowercase letters, numbers, or hyphens."
  }
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
    scenario        = "azure_hub_spoke"
    owner           = "ks6088ts"
    SecurityControl = "Ignore"
    CostControl     = "Ignore"
  }
}

variable "enable_hub_spoke_peering" {
  description = "Create both directions of VNet peering between the hub and spoke"
  type        = bool
  default     = false
}

variable "enable_private_endpoint_example" {
  description = "Create the private Blob Storage connectivity example in the spoke"
  type        = bool
  default     = false
}

variable "enable_test_vm" {
  description = "Create a private VM for connectivity checks"
  type        = bool
  default     = false
}

variable "enable_bastion" {
  description = "Create Azure Bastion for the test VM; enable_test_vm must also be true"
  type        = bool
  default     = false
}

variable "enable_nat_gateway" {
  description = "Create a NAT Gateway for test VM outbound internet access; enable_test_vm must also be true"
  type        = bool
  default     = false
}

variable "hub_vnet_address_space" {
  description = "Address space for the hub VNet"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "spoke_vnet_address_space" {
  description = "Address space for the spoke VNet; it must not overlap the hub"
  type        = list(string)
  default     = ["10.1.0.0/16"]
}

variable "private_endpoint_subnet_address_prefixes" {
  description = "Address prefixes for the optional Private Endpoint subnet"
  type        = list(string)
  default     = ["10.1.1.0/24"]
}

variable "workload_subnet_address_prefixes" {
  description = "Address prefixes for the optional test VM subnet"
  type        = list(string)
  default     = ["10.1.2.0/24"]
}

variable "bastion_subnet_address_prefixes" {
  description = "Address prefixes for AzureBastionSubnet; Azure requires /26 or larger"
  type        = list(string)
  default     = ["10.1.0.0/26"]
}

variable "allow_forwarded_traffic" {
  description = "Allow forwarded traffic across both peerings; keep false until a hub router or firewall is added"
  type        = bool
  default     = false
}

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

variable "vm_size" {
  description = "Size of the virtual machine"
  type        = string
  default     = "Standard_B2s_v2"
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

variable "vm_identity_enabled" {
  description = "Enable system-assigned managed identity for the VM"
  type        = bool
  default     = true
}

variable "bastion_sku" {
  description = "SKU for Azure Bastion"
  type        = string
  default     = "Basic"

  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.bastion_sku)
    error_message = "Bastion SKU must be Basic, Standard, or Premium."
  }
}

variable "nat_gateway_idle_timeout_in_minutes" {
  description = "Idle timeout in minutes for the NAT Gateway"
  type        = number
  default     = 10

  validation {
    condition     = var.nat_gateway_idle_timeout_in_minutes >= 4 && var.nat_gateway_idle_timeout_in_minutes <= 120
    error_message = "NAT Gateway idle timeout must be between 4 and 120 minutes."
  }
}
