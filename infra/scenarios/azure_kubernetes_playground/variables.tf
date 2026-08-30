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
  description = "Kubernetes version used at cluster creation. Null lets AKS select the current recommended GA version."
  type        = string
  default     = null
}

variable "sku_tier" {
  description = "AKS control-plane SKU tier"
  type        = string
  default     = "Free"
}

variable "oidc_issuer_enabled" {
  description = "Enable the AKS OIDC issuer"
  type        = bool
  default     = true
}

variable "workload_identity_enabled" {
  description = "Enable Microsoft Entra Workload ID"
  type        = bool
  default     = true
}

variable "local_account_disabled" {
  description = "Disable local AKS accounts. Requires entra_id with an admin group."
  type        = bool
  default     = false
}

variable "entra_id" {
  description = "Optional managed Microsoft Entra integration settings"
  type = object({
    tenant_id              = optional(string)
    admin_group_object_ids = set(string)
    azure_rbac_enabled     = optional(bool, true)
  })
  default = null
}

variable "api_server_authorized_ip_ranges" {
  description = "CIDR ranges permitted to access the public Kubernetes API"
  type        = set(string)
  default     = []
}

variable "automatic_upgrade_channel" {
  description = "AKS Kubernetes automatic upgrade channel"
  type        = string
  default     = "stable"
}

variable "node_os_upgrade_channel" {
  description = "AKS node operating-system upgrade channel"
  type        = string
  default     = "NodeImage"
}

variable "image_cleaner_enabled" {
  description = "Enable AKS Image Cleaner"
  type        = bool
  default     = true
}

variable "image_cleaner_interval_hours" {
  description = "Image Cleaner run interval in hours"
  type        = number
  default     = 168
}

variable "system_node_pool" {
  description = "AKS system node pool configuration"
  type = object({
    name                         = optional(string, "system")
    vm_size                      = optional(string, "Standard_D4s_v5")
    node_count                   = optional(number, 2)
    os_sku                       = optional(string, "AzureLinux3")
    os_disk_size_gb              = optional(number, 64)
    os_disk_type                 = optional(string, "Managed")
    only_critical_addons_enabled = optional(bool, true)
    temporary_name_for_rotation  = optional(string, "systemtmp")
    max_surge                    = optional(string, "33%")
    zones                        = optional(set(string), [])
  })
  default = {}
}

variable "user_node_pools" {
  description = "Autoscaling AKS user node pools keyed by node pool name"
  type = map(object({
    vm_size                     = optional(string, "Standard_D4s_v5")
    node_count                  = optional(number, 1)
    min_count                   = optional(number, 1)
    max_count                   = optional(number, 3)
    os_sku                      = optional(string, "AzureLinux3")
    os_disk_size_gb             = optional(number, 64)
    os_disk_type                = optional(string, "Managed")
    temporary_name_for_rotation = optional(string)
    max_surge                   = optional(string, "33%")
    zones                       = optional(set(string), [])
    node_labels                 = optional(map(string), {})
    node_taints                 = optional(set(string), [])
  }))
  default = {
    user = {}
  }
}

variable "network_profile" {
  description = "AKS network profile"
  type = object({
    network_plugin      = optional(string, "azure")
    network_plugin_mode = optional(string, "overlay")
    network_data_plane  = optional(string, "cilium")
    network_policy      = optional(string, "cilium")
    pod_cidr            = optional(string, "10.244.0.0/16")
    service_cidr        = optional(string, "10.0.0.0/16")
    dns_service_ip      = optional(string, "10.0.0.10")
    load_balancer_sku   = optional(string, "standard")
    outbound_type       = optional(string, "loadBalancer")
    ip_versions         = optional(set(string), ["IPv4"])
  })
  default = {}
}

variable "maintenance_window_auto_upgrade" {
  description = "Optional weekly planned-maintenance window for Kubernetes upgrades"
  type = object({
    interval    = optional(number, 1)
    duration    = optional(number, 4)
    day_of_week = optional(string, "Sunday")
    start_time  = optional(string, "03:00")
    utc_offset  = optional(string, "+00:00")
    start_date  = optional(string)
  })
  default = null
}

variable "maintenance_window_node_os" {
  description = "Optional weekly planned-maintenance window for node OS upgrades"
  type = object({
    interval    = optional(number, 1)
    duration    = optional(number, 4)
    day_of_week = optional(string, "Sunday")
    start_time  = optional(string, "07:00")
    utc_offset  = optional(string, "+00:00")
    start_date  = optional(string)
  })
  default = null
}

# =============================================================================
# Monitoring Variables
# =============================================================================

variable "container_insights_enabled" {
  description = "Create a Log Analytics workspace and enable Container Insights"
  type        = bool
  default     = false
}

variable "log_analytics_retention_in_days" {
  description = "Log Analytics retention in days when Container Insights is enabled"
  type        = number
  default     = 30

  validation {
    condition     = var.log_analytics_retention_in_days >= 30 && var.log_analytics_retention_in_days <= 730
    error_message = "Log Analytics retention must be between 30 and 730 days."
  }
}
