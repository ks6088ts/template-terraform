variable "repository_name" {
  description = "Specifies the name of the GitHub repository"
  type        = string
}

variable "environment_name" {
  description = "Specifies the name of the GitHub repository environment"
  type        = string
}

variable "prevent_self_review" {
  description = "Whether to prevent self-review for this environment"
  type        = bool
  default     = true
}

variable "deployment_branch_policy" {
  description = "Deployment branch policy configuration"
  type = object({
    protected_branches     = bool
    custom_branch_policies = bool
  })
  default = {
    protected_branches     = true
    custom_branch_policies = false
  }
}

variable "actions_environment_secrets" {
  description = "Specifies the environment secrets for the GitHub repository"
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}
