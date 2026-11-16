output "name" {
  description = "Name of the repository"
  value       = github_repository.this.name
}

output "full_name" {
  description = "Full name (owner/name) of the repository"
  value       = github_repository.this.full_name
}

output "repo_id" {
  description = "Numeric ID of the repository"
  value       = github_repository.this.repo_id
}

output "html_url" {
  description = "URL of the repository"
  value       = github_repository.this.html_url
}
