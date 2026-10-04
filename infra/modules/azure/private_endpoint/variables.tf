variable "name" {
  description = "Base name used for the endpoint, service connection, and DNS zone group"
  type        = string
  nullable    = false

  validation {
    condition     = trimspace(var.name) != ""
    error_message = "Name must not be empty."
  }
}

variable "resource_group_name" {
  description = "Resource group for the endpoint and any newly created DNS zone"
  type        = string
  nullable    = false

  validation {
    condition     = trimspace(var.resource_group_name) != ""
    error_message = "Resource group name must not be empty."
  }
}

variable "location" {
  description = "Azure region for the endpoint"
  type        = string
  nullable    = false

  validation {
    condition     = trimspace(var.location) != ""
    error_message = "Location must not be empty."
  }
}

variable "tags" {
  description = "Tags applied to resources created by this module"
  type        = map(string)
  default     = {}
  nullable    = false
}

variable "subnet_id" {
  description = "ID of the subnet hosting the endpoint"
  type        = string
  nullable    = false

  validation {
    condition     = trimspace(var.subnet_id) != ""
    error_message = "Subnet ID must not be empty."
  }
}

variable "private_connection_resource_id" {
  description = "Resource ID of the target PaaS service"
  type        = string
  nullable    = false

  validation {
    condition     = trimspace(var.private_connection_resource_id) != ""
    error_message = "Private connection resource ID must not be empty."
  }
}

variable "subresource_names" {
  description = "Private Link subresources supported by the target service"
  type        = list(string)
  nullable    = false

  validation {
    condition     = length(var.subresource_names) > 0 && alltrue([for name in var.subresource_names : name == null ? false : trimspace(name) != ""])
    error_message = "Subresource names must contain at least one non-empty name."
  }
}

variable "create_private_dns_zone" {
  description = "Create a DNS zone and VNet links; otherwise use caller-managed zone IDs"
  type        = bool
  default     = true
  nullable    = false
}

variable "private_dns_zone_name" {
  description = "Service-specific Private DNS zone name, required only in create mode"
  type        = string
  default     = null

  validation {
    condition     = var.private_dns_zone_name == null ? true : trimspace(var.private_dns_zone_name) != ""
    error_message = "Private DNS zone name must be null or non-empty."
  }
}

variable "virtual_network_links" {
  description = "New zone links keyed by stable logical names, required only in create mode"
  type = map(object({
    name               = string
    virtual_network_id = string
  }))
  default  = {}
  nullable = false

  validation {
    condition = alltrue([
      for key, link in var.virtual_network_links : link == null ? false : (
        trimspace(key) != "" &&
        (link.name == null ? false : trimspace(link.name) != "") &&
        (link.virtual_network_id == null ? false : trimspace(link.virtual_network_id) != "")
      )
    ])
    error_message = "Each VNet link requires a non-empty logical key, name, and virtual_network_id."
  }

  validation {
    condition     = length(distinct([for link in var.virtual_network_links : link == null ? null : link.name])) == length(var.virtual_network_links)
    error_message = "VNet link names must be unique within the zone."
  }
}

variable "private_dns_zone_ids" {
  description = "Caller-managed zone IDs, required only in existing mode; links are managed outside this module"
  type        = list(string)
  default     = []
  nullable    = false

  validation {
    condition     = alltrue([for id in var.private_dns_zone_ids : id == null ? false : trimspace(id) != ""])
    error_message = "Private DNS zone IDs must not contain null or empty values."
  }
}
