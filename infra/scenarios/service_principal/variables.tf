variable "service_principal_name" {
  description = "Specifies the service principal name"
  type        = string
  default     = "template-terraform_dev"
}

variable "role_definition_name" {
  description = "Specifies the role definition name"
  type        = string
  default     = "Contributor"
}

variable "github_organization" {
  description = "Specifies the GitHub organization"
  type        = string
  default     = "ks6088ts"
}

variable "github_repository" {
  description = "Specifies the GitHub repository"
  type        = string
  default     = "template-terraform"
}

variable "github_environment" {
  description = "Specifies the GitHub environment"
  type        = string
  default     = "dev"
}

variable "resource_access_permissions" {
  description = "Specifies the resource access permissions"
  type = list(object({
    resource_access_permission_name = string
    type                            = string
  }))
  default = [
    {
      resource_access_permission_name = "Domain.Read.All"
      type                            = "Role"
    },
    {
      resource_access_permission_name = "Group.ReadWrite.All"
      type                            = "Role"
    },
    {
      resource_access_permission_name = "GroupMember.ReadWrite.All"
      type                            = "Role"
    },
    {
      resource_access_permission_name = "User.ReadWrite.All"
      type                            = "Role"
    },
    {
      resource_access_permission_name = "Application.ReadWrite.All"
      type                            = "Role"
    },
  ]
}
