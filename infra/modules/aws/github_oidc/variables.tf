variable "github_organization" {
  description = "GitHub organization name"
  type        = string
}

variable "github_repository" {
  description = "GitHub repository name"
  type        = string
}

variable "role_name" {
  description = "Name of the IAM role to create"
  type        = string
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
  default     = {}
}
