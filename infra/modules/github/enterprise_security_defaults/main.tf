resource "github_enterprise_security_analysis_settings" "this" {
  enterprise_slug = var.enterprise_slug

  advanced_security_enabled_for_new_repositories               = var.advanced_security_enabled_for_new_repositories
  secret_scanning_enabled_for_new_repositories                 = var.secret_scanning_enabled_for_new_repositories
  secret_scanning_push_protection_enabled_for_new_repositories = var.secret_scanning_push_protection_enabled_for_new_repositories
  secret_scanning_push_protection_custom_link                  = var.secret_scanning_push_protection_custom_link
  secret_scanning_validity_checks_enabled                      = var.secret_scanning_validity_checks_enabled
}
