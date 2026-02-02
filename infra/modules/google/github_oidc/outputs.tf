output "workload_identity_pool_name" {
  description = "Full name of the Workload Identity Pool"
  value       = google_iam_workload_identity_pool.github.name
}

output "workload_identity_pool_id" {
  description = "ID of the Workload Identity Pool"
  value       = google_iam_workload_identity_pool.github.workload_identity_pool_id
}

output "workload_identity_provider_name" {
  description = "Full name of the Workload Identity Pool Provider"
  value       = google_iam_workload_identity_pool_provider.github.name
}

output "service_account_email" {
  description = "Email of the service account"
  value       = google_service_account.github_actions.email
}

output "service_account_id" {
  description = "ID of the service account"
  value       = google_service_account.github_actions.id
}

output "project_id" {
  description = "Google Cloud project ID"
  value       = var.project_id
}
