output "oidc_provider_arn" {
  description = "ARN of the GitHub Actions OIDC provider"
  value       = module.github_oidc.oidc_provider_arn
}

output "oidc_provider_url" {
  description = "URL of the GitHub Actions OIDC provider"
  value       = module.github_oidc.oidc_provider_url
}

output "role_arn" {
  description = "ARN of the IAM role for GitHub Actions"
  value       = module.github_oidc.role_arn
}

output "role_name" {
  description = "Name of the IAM role for GitHub Actions"
  value       = module.github_oidc.role_name
}

output "aws_account_id" {
  description = "AWS account ID"
  value       = module.github_oidc.aws_account_id
}
