# Dependabot alerts are managed by github_repository_vulnerability_alerts in the
# repository_dependabot module instead of the deprecated vulnerability_alerts argument.
#trivy:ignore:AVD-GIT-0003
resource "github_repository" "this" {
  name        = var.name
  description = var.description
  visibility  = var.visibility
  topics      = var.topics

  has_issues      = var.has_issues
  has_discussions = var.has_discussions
  has_projects    = var.has_projects
  has_wiki        = var.has_wiki

  allow_merge_commit          = var.allow_merge_commit
  allow_squash_merge          = var.allow_squash_merge
  allow_rebase_merge          = var.allow_rebase_merge
  allow_update_branch         = true
  delete_branch_on_merge      = var.delete_branch_on_merge
  web_commit_signoff_required = var.web_commit_signoff_required

  auto_init          = var.auto_init
  archive_on_destroy = var.archive_on_destroy

  dynamic "security_and_analysis" {
    for_each = var.security_and_analysis == null ? [] : [var.security_and_analysis]
    content {
      dynamic "advanced_security" {
        for_each = security_and_analysis.value.advanced_security != null ? [security_and_analysis.value.advanced_security] : []
        content {
          status = advanced_security.value
        }
      }
      dynamic "code_security" {
        for_each = security_and_analysis.value.code_security != null ? [security_and_analysis.value.code_security] : []
        content {
          status = code_security.value
        }
      }
      dynamic "secret_scanning" {
        for_each = security_and_analysis.value.secret_scanning != null ? [security_and_analysis.value.secret_scanning] : []
        content {
          status = secret_scanning.value
        }
      }
      dynamic "secret_scanning_push_protection" {
        for_each = security_and_analysis.value.secret_scanning_push_protection != null ? [security_and_analysis.value.secret_scanning_push_protection] : []
        content {
          status = secret_scanning_push_protection.value
        }
      }
      dynamic "secret_scanning_ai_detection" {
        for_each = security_and_analysis.value.secret_scanning_ai_detection != null ? [security_and_analysis.value.secret_scanning_ai_detection] : []
        content {
          status = secret_scanning_ai_detection.value
        }
      }
      dynamic "secret_scanning_non_provider_patterns" {
        for_each = security_and_analysis.value.secret_scanning_non_provider_patterns != null ? [security_and_analysis.value.secret_scanning_non_provider_patterns] : []
        content {
          status = secret_scanning_non_provider_patterns.value
        }
      }
    }
  }

  lifecycle {
    precondition {
      condition     = !(var.visibility == "public" && try(var.security_and_analysis.advanced_security, null) != null)
      error_message = "advanced_security cannot be set on public repositories; it is always enabled."
    }
  }
}
