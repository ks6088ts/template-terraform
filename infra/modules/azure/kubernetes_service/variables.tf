variable "name" {
  description = "Base name for the AKS cluster"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9][a-zA-Z0-9-]{0,48}[a-zA-Z0-9]$", var.name))
    error_message = "Name must be 2-50 alphanumeric characters or hyphens and must start and end with an alphanumeric character so the generated AKS name and DNS prefix remain valid."
  }
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

  validation {
    condition     = var.dns_prefix == null || can(regex("^[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,52}[a-zA-Z0-9])?$", var.dns_prefix))
    error_message = "DNS prefix must contain 1-54 alphanumeric characters or hyphens and must start and end with an alphanumeric character."
  }
}

variable "kubernetes_version" {
  description = "Kubernetes version used at creation time. Null lets AKS select its current recommended GA version; automatic_upgrade_channel governs subsequent upgrades."
  type        = string
  default     = null

  validation {
    condition     = var.kubernetes_version == null || can(regex("^[0-9]+\\.[0-9]+(?:\\.[0-9]+)?$", var.kubernetes_version))
    error_message = "Kubernetes version must be null, a minor alias such as 1.35, or a full version such as 1.35.2."
  }
}

variable "sku_tier" {
  description = "AKS control-plane SKU tier"
  type        = string
  default     = "Free"

  validation {
    condition     = contains(["Free", "Standard", "Premium"], var.sku_tier)
    error_message = "SKU tier must be Free, Standard, or Premium."
  }
}

variable "oidc_issuer_enabled" {
  description = "Enable the OIDC issuer for the AKS cluster"
  type        = bool
  default     = true
}

variable "workload_identity_enabled" {
  description = "Enable Microsoft Entra Workload ID"
  type        = bool
  default     = true
}

variable "role_based_access_control_enabled" {
  description = "Enable Kubernetes role-based access control"
  type        = bool
  default     = true
}

variable "local_account_disabled" {
  description = "Disable local AKS accounts. Managed Microsoft Entra integration with at least one admin group is required when true."
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

  validation {
    condition = var.entra_id == null || alltrue([
      for object_id in var.entra_id.admin_group_object_ids :
      can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", object_id))
    ])
    error_message = "Every Microsoft Entra admin group object ID must be a UUID."
  }
}

variable "api_server_authorized_ip_ranges" {
  description = "CIDR ranges permitted to access the public Kubernetes API. An empty set leaves the public API unrestricted."
  type        = set(string)
  default     = []

  validation {
    condition     = alltrue([for cidr in var.api_server_authorized_ip_ranges : can(cidrhost(cidr, 0))])
    error_message = "Every API server authorized IP range must be valid CIDR notation."
  }
}

variable "automatic_upgrade_channel" {
  description = "AKS Kubernetes automatic upgrade channel"
  type        = string
  default     = "stable"

  validation {
    condition     = contains(["patch", "rapid", "stable", "node-image"], var.automatic_upgrade_channel)
    error_message = "Automatic upgrade channel must be patch, rapid, stable, or node-image."
  }
}

variable "node_os_upgrade_channel" {
  description = "AKS node operating-system upgrade channel"
  type        = string
  default     = "NodeImage"

  validation {
    condition     = contains(["Unmanaged", "SecurityPatch", "NodeImage", "None"], var.node_os_upgrade_channel)
    error_message = "Node OS upgrade channel must be Unmanaged, SecurityPatch, NodeImage, or None."
  }
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

  validation {
    condition     = var.image_cleaner_interval_hours >= 24 && var.image_cleaner_interval_hours <= 2160
    error_message = "Image Cleaner interval must be between 24 hours and 2160 hours (90 days)."
  }
}

variable "system_node_pool" {
  description = "System node pool configuration"
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

  validation {
    condition     = can(regex("^[a-z][a-z0-9]{0,11}$", var.system_node_pool.name))
    error_message = "The system node pool name must start with a lowercase letter and contain at most 12 lowercase alphanumeric characters."
  }

  validation {
    condition     = can(regex("^[a-z][a-z0-9]{0,11}$", var.system_node_pool.temporary_name_for_rotation)) && var.system_node_pool.temporary_name_for_rotation != var.system_node_pool.name
    error_message = "The temporary system pool name must be a different valid AKS pool name."
  }

  validation {
    condition     = var.system_node_pool.node_count >= 2 && var.system_node_pool.node_count <= 1000
    error_message = "The system node pool must contain between 2 and 1000 nodes."
  }

  validation {
    condition     = !can(regex("^Standard_B", var.system_node_pool.vm_size))
    error_message = "B-series virtual machines are not supported for the AKS system node pool."
  }

  validation {
    condition     = contains(["AzureLinux3", "Ubuntu", "Ubuntu2204", "Ubuntu2404"], var.system_node_pool.os_sku)
    error_message = "System pool os_sku must be AzureLinux3 or a supported Ubuntu SKU."
  }

  validation {
    condition     = contains(["Managed", "Ephemeral"], var.system_node_pool.os_disk_type)
    error_message = "System pool os_disk_type must be Managed or Ephemeral."
  }

  validation {
    condition     = var.system_node_pool.os_disk_size_gb >= 30 && var.system_node_pool.os_disk_size_gb <= 2048
    error_message = "System pool OS disk size must be between 30 and 2048 GB."
  }

  validation {
    condition     = can(regex("^(?:[1-9][0-9]*|100)%$", var.system_node_pool.max_surge)) || can(regex("^[1-9][0-9]*$", var.system_node_pool.max_surge))
    error_message = "System pool max_surge must be a positive integer or percentage."
  }
}

variable "user_node_pools" {
  description = "Autoscaling user node pools keyed by AKS node pool name"
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

  validation {
    condition = alltrue([
      for name, pool in var.user_node_pools :
      can(regex("^[a-z][a-z0-9]{0,11}$", name)) &&
      (pool.temporary_name_for_rotation == null || (
        can(regex("^[a-z][a-z0-9]{0,11}$", pool.temporary_name_for_rotation)) &&
        pool.temporary_name_for_rotation != name
      ))
    ])
    error_message = "User pool names and temporary rotation names must be distinct valid AKS pool names."
  }

  validation {
    condition = alltrue([
      for pool in values(var.user_node_pools) :
      pool.min_count >= 0 &&
      pool.node_count >= pool.min_count &&
      pool.node_count <= pool.max_count &&
      pool.max_count <= 1000
    ])
    error_message = "Each user pool must satisfy 0 <= min_count <= node_count <= max_count <= 1000."
  }

  validation {
    condition = alltrue([
      for pool in values(var.user_node_pools) :
      contains(["AzureLinux3", "Ubuntu", "Ubuntu2204", "Ubuntu2404"], pool.os_sku) &&
      contains(["Managed", "Ephemeral"], pool.os_disk_type) &&
      pool.os_disk_size_gb >= 30 &&
      pool.os_disk_size_gb <= 2048
    ])
    error_message = "Every user pool must use a supported Linux OS SKU and disk type with a 30-2048 GB OS disk."
  }

  validation {
    condition = alltrue([
      for pool in values(var.user_node_pools) :
      can(regex("^(?:[1-9][0-9]*|100)%$", pool.max_surge)) || can(regex("^[1-9][0-9]*$", pool.max_surge))
    ])
    error_message = "Every user pool max_surge must be a positive integer or percentage."
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

  validation {
    condition     = contains(["azure", "kubenet"], var.network_profile.network_plugin)
    error_message = "Network plugin must be azure or kubenet."
  }

  validation {
    condition     = var.network_profile.network_plugin_mode == null || var.network_profile.network_plugin_mode == "overlay"
    error_message = "Network plugin mode must be null or overlay."
  }

  validation {
    condition     = var.network_profile.network_plugin_mode != "overlay" || var.network_profile.network_plugin == "azure"
    error_message = "Azure CNI Overlay requires network_plugin to be azure."
  }

  validation {
    condition = var.network_profile.network_data_plane != "cilium" || (
      var.network_profile.network_plugin == "azure" &&
      var.network_profile.network_plugin_mode == "overlay" &&
      var.network_profile.network_policy == "cilium"
    )
    error_message = "Cilium requires the Azure network plugin, overlay mode, and the cilium network policy."
  }

  validation {
    condition = alltrue([
      can(cidrhost(var.network_profile.pod_cidr, 0)),
      can(cidrhost(var.network_profile.service_cidr, 0)),
      can(cidrhost("${var.network_profile.dns_service_ip}/32", 0)),
    ])
    error_message = "Pod CIDR, service CIDR, and DNS service IP must be valid IPv4 values."
  }

  validation {
    condition     = contains(["standard"], var.network_profile.load_balancer_sku)
    error_message = "Only the standard load balancer SKU is supported by this module."
  }

  validation {
    condition     = contains(["loadBalancer", "managedNATGateway", "userDefinedRouting", "none"], var.network_profile.outbound_type)
    error_message = "Unsupported AKS outbound type."
  }
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

  validation {
    condition = var.maintenance_window_auto_upgrade == null || (
      var.maintenance_window_auto_upgrade.interval >= 1 &&
      var.maintenance_window_auto_upgrade.duration >= 4 &&
      var.maintenance_window_auto_upgrade.duration <= 24 &&
      contains(["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"], var.maintenance_window_auto_upgrade.day_of_week) &&
      can(regex("^(?:[01][0-9]|2[0-3]):[0-5][0-9]$", var.maintenance_window_auto_upgrade.start_time))
    )
    error_message = "The auto-upgrade maintenance window must be a valid weekly window lasting 4-24 hours."
  }
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

  validation {
    condition = var.maintenance_window_node_os == null || (
      var.maintenance_window_node_os.interval >= 1 &&
      var.maintenance_window_node_os.duration >= 4 &&
      var.maintenance_window_node_os.duration <= 24 &&
      contains(["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"], var.maintenance_window_node_os.day_of_week) &&
      can(regex("^(?:[01][0-9]|2[0-3]):[0-5][0-9]$", var.maintenance_window_node_os.start_time))
    )
    error_message = "The node OS maintenance window must be a valid weekly window lasting 4-24 hours."
  }
}

variable "log_analytics_workspace_id" {
  description = "Optional Log Analytics workspace resource ID used to enable Container Insights"
  type        = string
  default     = null

  validation {
    condition     = var.log_analytics_workspace_id == null || can(regex("(?i)^/subscriptions/[^/]+/resourceGroups/[^/]+/providers/Microsoft\\.OperationalInsights/workspaces/[^/]+$", var.log_analytics_workspace_id))
    error_message = "Log Analytics workspace ID must be a complete Azure resource ID."
  }
}

variable "container_registry_id" {
  description = "Optional Azure Container Registry resource ID to grant the kubelet identity AcrPull access"
  type        = string
  default     = null

  validation {
    condition     = var.container_registry_id == null || can(regex("(?i)^/subscriptions/[^/]+/resourceGroups/[^/]+/providers/Microsoft\\.ContainerRegistry/registries/[^/]+$", var.container_registry_id))
    error_message = "Container Registry ID must be a complete Azure resource ID."
  }
}

variable "tags" {
  description = "Tags to apply to the AKS cluster"
  type        = map(string)
  default     = {}
}
