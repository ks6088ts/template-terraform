output "environment_name" {
  description = "Name of the created GitHub repository environment"
  value       = github_repository_environment.this.environment
}

output "repository" {
  description = "Name of the repository"
  value       = github_repository_environment.this.repository
}

output "id" {
  description = "ID of the GitHub repository environment"
  value       = github_repository_environment.this.id
}

output "secret_names" {
  description = "List of created secret names"
  value       = [for secret in github_actions_environment_secret.this : secret.secret_name]
}
