variable "name" {
  description = "Base name for the Virtual Network resources"
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

variable "address_space" {
  description = "Address space for the virtual network"
  type        = list(string)
}

variable "subnets" {
  description = "List of subnets to create"
  type = list(object({
    name                              = string
    address_prefixes                  = list(string)
    private_endpoint_network_policies = optional(string)
  }))
  default = []
}

variable "network_security_groups" {
  description = "List of network security groups to create"
  type = list(object({
    name = string
  }))
  default = []
}

variable "nsg_subnet_associations" {
  description = "List of NSG to subnet associations"
  type = list(object({
    subnet_name = string
    nsg_name    = string
  }))
  default = []
}
