output "id" {
  description = "ID of the existing Cloudflare account"
  value       = data.cloudflare_account.this.id
}

output "name" {
  description = "Name of the existing Cloudflare account"
  value       = data.cloudflare_account.this.name
}
