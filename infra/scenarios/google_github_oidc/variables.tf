variable "project_id" {
  description = "Google Cloud project ID"
  type        = string
  default     = "template-terraform"
}

variable "region" {
  description = "Google Cloud region"
  type        = string
  default     = "asia-northeast1"
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

variable "workload_identity_pool_id" {
  description = "ID for the Workload Identity Pool (must be 4-32 characters, lowercase letters, numbers, and hyphens)"
  type        = string
  default     = "github-actions-pool"
}

variable "workload_identity_pool_display_name" {
  description = "Display name for the Workload Identity Pool"
  type        = string
  default     = "GitHub Actions Pool"
}

variable "workload_identity_pool_provider_id" {
  description = "ID for the Workload Identity Pool Provider"
  type        = string
  default     = "github"
}

variable "workload_identity_pool_provider_display_name" {
  description = "Display name for the Workload Identity Pool Provider"
  type        = string
  default     = "GitHub"
}

variable "service_account_id" {
  description = "ID for the service account (must be 6-30 characters, lowercase letters, numbers, and hyphens)"
  type        = string
  default     = "github-actions"
}

variable "service_account_display_name" {
  description = "Display name for the service account"
  type        = string
  default     = "GitHub Actions Service Account"
}

variable "roles" {
  description = "List of IAM roles to grant to the service account"
  type        = list(string)
  default     = ["roles/viewer"]
}
