variable "name" {
  description = "Base name for the AKS cluster"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region for the AKS cluster"
  type        = string
}

variable "dns_prefix" {
  description = "DNS prefix for the AKS cluster"
  type        = string
  default     = null
}

variable "kubernetes_version" {
  description = "Kubernetes version (null for latest)"
  type        = string
  default     = null
}

variable "automatic_upgrade_channel" {
  description = "Automatic upgrade channel for the AKS control plane"
  type        = string
  default     = "patch"

  validation {
    condition     = var.automatic_upgrade_channel == null || contains(["node-image", "patch", "rapid", "stable"], var.automatic_upgrade_channel)
    error_message = "Automatic upgrade channel must be null or one of: node-image, patch, rapid, stable."
  }
}

variable "node_os_upgrade_channel" {
  description = "Upgrade channel for AKS node OS images"
  type        = string
  default     = "NodeImage"

  validation {
    condition     = contains(["None", "Unmanaged", "SecurityPatch", "NodeImage"], var.node_os_upgrade_channel)
    error_message = "Node OS upgrade channel must be one of: None, Unmanaged, SecurityPatch, NodeImage."
  }
}

variable "oidc_issuer_enabled" {
  description = "Enable the OIDC issuer for the AKS cluster"
  type        = bool
  default     = true
}

variable "workload_identity_enabled" {
  description = "Enable Microsoft Entra Workload ID for the AKS cluster"
  type        = bool
  default     = true
}

variable "key_vault_secrets_provider_enabled" {
  description = "Enable the Azure Key Vault Secrets Store CSI driver with secret rotation"
  type        = bool
  default     = false
}

variable "default_node_pool_name" {
  description = "Name of the default node pool"
  type        = string
  default     = "default"
}

variable "node_count" {
  description = "Number of nodes in the default node pool"
  type        = number
  default     = 2

  validation {
    condition     = var.node_count >= 2 && var.node_count <= 100
    error_message = "System node count must be between 2 and 100."
  }
}

variable "vm_size" {
  description = "VM size for the default node pool"
  type        = string
  default     = "Standard_D4s_v3"

  validation {
    condition     = !can(regex("^Standard_B", var.vm_size))
    error_message = "AKS system node pools do not support B-series VM sizes."
  }
}

variable "os_disk_size_gb" {
  description = "OS disk size in GB for the default node pool"
  type        = number
  default     = 128

  validation {
    condition     = var.os_disk_size_gb >= 30 && var.os_disk_size_gb <= 2048
    error_message = "OS disk size must be between 30 and 2048 GB."
  }
}

variable "auto_scaling_enabled" {
  description = "Enable auto-scaling for the default node pool"
  type        = bool
  default     = false
}

variable "min_count" {
  description = "Minimum number of nodes when auto-scaling is enabled"
  type        = number
  default     = 2

  validation {
    condition     = var.min_count >= 2 && var.min_count <= 100
    error_message = "System node pool min_count must be between 2 and 100."
  }
}

variable "max_count" {
  description = "Maximum number of nodes when auto-scaling is enabled"
  type        = number
  default     = 3

  validation {
    condition     = var.max_count >= 2 && var.max_count <= 100
    error_message = "System node pool max_count must be between 2 and 100."
  }
}

variable "only_critical_addons_enabled" {
  description = "Restrict the default system node pool to critical add-ons when a user node pool is enabled"
  type        = bool
  default     = true
}

variable "default_node_pool_temporary_name" {
  description = "Temporary node pool name used when rotating the default node pool"
  type        = string
  default     = "systemtmp"
}

variable "network_plugin" {
  description = "Network plugin for the AKS cluster (kubenet or azure)"
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

  validation {
    condition     = var.network_plugin_mode == null || contains(["overlay"], var.network_plugin_mode)
    error_message = "Network plugin mode must be null or overlay."
  }
}

variable "network_data_plane" {
  description = "Network data plane for the AKS cluster"
  type        = string
  default     = "cilium"

  validation {
    condition     = var.network_data_plane == null || contains(["azure", "cilium"], var.network_data_plane)
    error_message = "Network data plane must be null, azure, or cilium."
  }
}

variable "network_policy" {
  description = "Network policy for the AKS cluster (calico, azure, cilium, or null)"
  type        = string
  default     = "cilium"

  validation {
    condition     = var.network_policy == null || contains(["calico", "azure", "cilium"], var.network_policy)
    error_message = "Network policy must be null, calico, azure, or cilium."
  }
}

variable "load_balancer_sku" {
  description = "SKU of the AKS managed load balancer"
  type        = string
  default     = "standard"

  validation {
    condition     = contains(["standard"], var.load_balancer_sku)
    error_message = "Load balancer SKU must be standard."
  }
}

variable "outbound_type" {
  description = "Outbound routing method for the AKS cluster"
  type        = string
  default     = "loadBalancer"
}

variable "user_node_pool_enabled" {
  description = "Create a dedicated user node pool for workshop workloads"
  type        = bool
  default     = false
}

variable "user_node_pool_name" {
  description = "Name of the user node pool"
  type        = string
  default     = "workload"
}

variable "user_node_pool_vm_size" {
  description = "VM size for the user node pool"
  type        = string
  default     = "Standard_D4s_v3"
}

variable "user_node_pool_node_count" {
  description = "Number of user nodes when auto-scaling is disabled"
  type        = number
  default     = 1

  validation {
    condition     = var.user_node_pool_node_count >= 0 && var.user_node_pool_node_count <= 100
    error_message = "User node count must be between 0 and 100."
  }
}

variable "user_node_pool_auto_scaling_enabled" {
  description = "Enable auto-scaling for the user node pool"
  type        = bool
  default     = true
}

variable "user_node_pool_min_count" {
  description = "Minimum number of nodes in the auto-scaling user node pool"
  type        = number
  default     = 1

  validation {
    condition     = var.user_node_pool_min_count >= 0 && var.user_node_pool_min_count <= 100
    error_message = "User node pool min_count must be between 0 and 100."
  }
}

variable "user_node_pool_max_count" {
  description = "Maximum number of nodes in the auto-scaling user node pool"
  type        = number
  default     = 3

  validation {
    condition     = var.user_node_pool_max_count >= 1 && var.user_node_pool_max_count <= 100
    error_message = "User node pool max_count must be between 1 and 100."
  }
}

variable "user_node_pool_os_disk_size_gb" {
  description = "OS disk size in GB for the user node pool"
  type        = number
  default     = 128

  validation {
    condition     = var.user_node_pool_os_disk_size_gb >= 30 && var.user_node_pool_os_disk_size_gb <= 2048
    error_message = "User node pool OS disk size must be between 30 and 2048 GB."
  }
}

variable "user_node_pool_max_pods" {
  description = "Maximum number of pods per user node"
  type        = number
  default     = 110
}

variable "user_node_pool_os_sku" {
  description = "OS SKU for the user node pool"
  type        = string
  default     = "Ubuntu"
}

variable "user_node_pool_temporary_name" {
  description = "Temporary node pool name used when rotating the user node pool"
  type        = string
  default     = "worktmp"
}

variable "enable_acr_pull" {
  description = "Enable AcrPull role assignment for the ACR"
  type        = bool
  default     = false
}

variable "acr_id" {
  description = "ID of the Azure Container Registry to grant AcrPull access"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to the AKS cluster"
  type        = map(string)
  default     = {}
}
