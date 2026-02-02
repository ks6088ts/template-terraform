# Data source to get the current AWS account ID
data "aws_caller_identity" "this" {}

# GitHub Actions OIDC Provider
resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com"
  ]

  # GitHub's OIDC thumbprint
  # Note: AWS no longer requires thumbprints for GitHub Actions OIDC,
  # but the parameter is still required by the API
  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1",
    "1c58a3a8518e8759bf075b76b750d4f2df264fcd"
  ]

  tags = var.tags
}

# Build the condition for the assume role policy
locals {
  github_repo_pattern = "repo:${var.github_organization}/${var.github_repository}"

  # Determine the subject condition based on branches and environments
  subject_conditions = concat(
    # If branches are specified, add branch conditions
    length(var.github_branches) > 0 ? [
      for branch in var.github_branches : "${local.github_repo_pattern}:ref:refs/heads/${branch}"
    ] : [],
    # If environments are specified, add environment conditions
    length(var.github_environments) > 0 ? [
      for env in var.github_environments : "${local.github_repo_pattern}:environment:${env}"
    ] : [],
    # If neither branches nor environments are specified, allow all
    length(var.github_branches) == 0 && length(var.github_environments) == 0 ? [
      "${local.github_repo_pattern}:*"
    ] : []
  )
}

# IAM Role for GitHub Actions
resource "aws_iam_role" "github_actions" {
  name = var.role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRoleWithWebIdentity"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Condition = {
          StringLike = {
            "token.actions.githubusercontent.com:sub" = local.subject_conditions
          }
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = var.tags
}

# Attach IAM policies to the role
resource "aws_iam_role_policy_attachment" "github_actions" {
  for_each = toset(var.policy_arns)

  role       = aws_iam_role.github_actions.name
  policy_arn = each.value
}
