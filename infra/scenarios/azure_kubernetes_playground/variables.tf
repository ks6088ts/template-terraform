variable "name" {
  description = "Specifies the base name for resources"
  type        = string
  default     = "azurekubernetesplayground"
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
    scenario        = "azure_kubernetes_playground"
    owner           = "ks6088ts"
    SecurityControl = "Ignore"
    CostControl     = "Ignore"
  }
}

# =============================================================================
# ACR Variables
# =============================================================================

variable "acr_sku" {
  description = "SKU for the Azure Container Registry"
  type        = string
  default     = "Basic"

  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.acr_sku)
    error_message = "ACR SKU must be one of: Basic, Standard, Premium."
  }
}

variable "acr_admin_enabled" {
  description = "Enable admin user for the Azure Container Registry"
  type        = bool
  default     = false
}

# =============================================================================
# AKS Variables
# =============================================================================

variable "kubernetes_version" {
  description = "Kubernetes version for AKS (null for latest stable)"
  type        = string
  default     = null
}

variable "automatic_upgrade_channel" {
  description = "Automatic upgrade channel for the AKS control plane"
  type        = string
  default     = "patch"
}

variable "node_os_upgrade_channel" {
  description = "Upgrade channel for AKS node OS images"
  type        = string
  default     = "NodeImage"
}

variable "oidc_issuer_enabled" {
  description = "Enable the OIDC issuer for AKS"
  type        = bool
  default     = true
}

variable "workload_identity_enabled" {
  description = "Enable Microsoft Entra Workload ID for AKS"
  type        = bool
  default     = true
}

variable "key_vault_secrets_provider_enabled" {
  description = "Enable the Azure Key Vault Secrets Store CSI driver"
  type        = bool
  default     = true
}

variable "vm_size" {
  description = "VM size for AKS system nodes"
  type        = string
  default     = "Standard_D4s_v3"
}

variable "node_count" {
  description = "Number of nodes in the default system node pool"
  type        = number
  default     = 2

  validation {
    condition     = var.node_count >= 2 && var.node_count <= 100
    error_message = "System node count must be between 2 and 100."
  }
}

variable "os_disk_size_gb" {
  description = "OS disk size in GB for AKS system nodes"
  type        = number
  default     = 128
}

variable "auto_scaling_enabled" {
  description = "Enable auto-scaling for the system node pool"
  type        = bool
  default     = false
}

variable "min_count" {
  description = "Minimum system node count when auto-scaling is enabled"
  type        = number
  default     = 2
}

variable "max_count" {
  description = "Maximum system node count when auto-scaling is enabled"
  type        = number
  default     = 3
}

variable "network_plugin" {
  description = "Network plugin for AKS (kubenet or azure)"
  type        = string
  default     = "azure"

  validation {
    condition     = contains(["kubenet", "azure"], var.network_plugin)
    error_message = "Network plugin must be either 'kubenet' or 'azure'."
  }
}

variable "network_plugin_mode" {
  description = "Network plugin mode for Azure CNI"
  type        = string
  default     = "overlay"
}

variable "network_data_plane" {
  description = "Network data plane for AKS"
  type        = string
  default     = "cilium"
}

variable "network_policy" {
  description = "Network policy implementation for AKS"
  type        = string
  default     = "cilium"
}

variable "user_node_pool_enabled" {
  description = "Create a dedicated user node pool for workshop workloads"
  type        = bool
  default     = true
}

variable "user_node_pool_vm_size" {
  description = "VM size for workshop workload nodes"
  type        = string
  default     = "Standard_D4s_v3"
}

variable "user_node_pool_auto_scaling_enabled" {
  description = "Enable auto-scaling for the workshop workload node pool"
  type        = bool
  default     = true
}

variable "user_node_pool_min_count" {
  description = "Minimum number of workshop workload nodes"
  type        = number
  default     = 1
}

variable "user_node_pool_max_count" {
  description = "Maximum number of workshop workload nodes"
  type        = number
  default     = 3
}

variable "user_node_pool_os_disk_size_gb" {
  description = "OS disk size in GB for workshop workload nodes"
  type        = number
  default     = 128
}
