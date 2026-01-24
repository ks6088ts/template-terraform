variable "github_owner" {
  description = "Specifies the GitHub owner (user or organization) for the provider"
  type        = string
  default     = "ks6088ts"
}

variable "repository_name" {
  description = "Specifies the name of the GitHub repository"
  type        = string
  default     = "template-terraform"
}

variable "environment_name" {
  description = "Specifies the name of the GitHub repository environment"
  type        = string
  default     = "dev"
}

variable "actions_environment_secrets" {
  description = "Specifies the environment secrets for the GitHub repository"
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}
