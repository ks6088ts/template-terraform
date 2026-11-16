output "enterprise_slug" {
  description = "Slug of the enterprise whose security defaults are managed, or null"
  value       = one(module.enterprise_security_defaults[*].enterprise_slug)
}

output "security_defaults" {
  description = "Security defaults applied to new repositories in the enterprise, or null"
  value       = one(module.enterprise_security_defaults[*].settings)
}
