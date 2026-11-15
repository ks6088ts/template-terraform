resource "github_repository_vulnerability_alerts" "this" {
  repository = var.repository
  enabled    = var.vulnerability_alerts_enabled
}

resource "github_repository_dependabot_security_updates" "this" {
  repository = var.repository
  enabled    = var.vulnerability_alerts_enabled && var.security_updates_enabled

  depends_on = [github_repository_vulnerability_alerts.this]
}
