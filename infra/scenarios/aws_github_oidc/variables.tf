variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "ap-northeast-1"
}

variable "github_organization" {
  description = "GitHub organization name"
  type        = string
  default     = "ks6088ts"
}

variable "github_repository" {
  description = "GitHub repository name"
  type        = string
  default     = "template-terraform"
}

variable "role_name" {
  description = "Name of the IAM role to create for GitHub Actions"
  type        = string
  default     = "GitHubActionsRole"
}

variable "policy_arns" {
  description = "List of IAM policy ARNs to attach to the role"
  type        = list(string)
  default     = ["arn:aws:iam::aws:policy/IAMReadOnlyAccess"]
}

variable "github_branches" {
  description = "List of GitHub branches allowed to assume the role (e.g., ['main', 'develop']). If empty, all branches are allowed."
  type        = list(string)
  default     = []
}

variable "github_environments" {
  description = "List of GitHub environments allowed to assume the role (e.g., ['production', 'staging']). If empty, environments are not restricted."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags to apply to the resources"
  type        = map(string)
  default = {
    Project   = "template-terraform"
    ManagedBy = "Terraform"
  }
}
