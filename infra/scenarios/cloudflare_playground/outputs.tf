output "account_id" {
  description = "ID of the existing Cloudflare account"
  value       = module.account.id
}

output "account_name" {
  description = "Name of the existing Cloudflare account"
  value       = module.account.name
}
