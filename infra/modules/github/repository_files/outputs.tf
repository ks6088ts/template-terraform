output "files" {
  description = "Paths of the managed files"
  value       = keys(github_repository_file.this)
}
