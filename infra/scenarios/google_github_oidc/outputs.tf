output "workload_identity_pool_name" {
  description = "Full name of the Workload Identity Pool"
  value       = module.github_oidc.workload_identity_pool_name
}

output "workload_identity_pool_id" {
  description = "ID of the Workload Identity Pool"
  value       = module.github_oidc.workload_identity_pool_id
}

output "workload_identity_provider_name" {
  description = "Full name of the Workload Identity Pool Provider"
  value       = module.github_oidc.workload_identity_provider_name
}

output "service_account_email" {
  description = "Email of the service account"
  value       = module.github_oidc.service_account_email
}

output "service_account_id" {
  description = "ID of the service account"
  value       = module.github_oidc.service_account_id
}

output "project_id" {
  description = "Google Cloud project ID"
  value       = module.github_oidc.project_id
}
