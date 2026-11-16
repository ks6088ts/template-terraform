output "id" {
  description = "ID of the repository ruleset"
  value       = github_repository_ruleset.this.id
}

output "name" {
  description = "Name of the repository ruleset"
  value       = github_repository_ruleset.this.name
}
