# AWS GitHub OIDC

This Terraform scenario creates the necessary AWS resources to enable GitHub Actions to authenticate with AWS using OpenID Connect (OIDC). This eliminates the need for storing long-lived AWS credentials as GitHub secrets.

## Resources Created

- **IAM OIDC Identity Provider**: Establishes trust between GitHub Actions and AWS
- **IAM Role**: Role that GitHub Actions workflows can assume
- **IAM Role Policy Attachments**: Attaches specified policies to the role

## Prerequisites

- Terraform CLI installed
- AWS CLI installed and configured
- AWS account with appropriate permissions to create IAM resources

## How to use

```shell
# Create backend.tf if you want to use S3 backend (optional)
cat <<EOF > backend.tf
terraform {
  backend "s3" {
    bucket = "YOUR_S3_BUCKET_NAME"
    key    = "aws_github_oidc/terraform.tfstate"
    region = "ap-northeast-1"
  }
}
EOF

# Or use local backend for testing
cat <<EOF > backend.tf
terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
}
EOF

# Configure AWS credentials
aws configure
# Or set environment variables
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_REGION="ap-northeast-1"

# Initialize Terraform
terraform init

# Plan the deployment
terraform plan

# Apply the deployment
terraform apply -auto-approve

# Confirm the output
terraform output

# Destroy the deployment
terraform destroy -auto-approve
```

## Variables

| Name | Description | Default |
|------|-------------|---------|
| `aws_region` | AWS region to deploy resources | `ap-northeast-1` |
| `github_organization` | GitHub organization name | `ks6088ts` |
| `github_repository` | GitHub repository name | `template-terraform` |
| `role_name` | Name of the IAM role to create | `GitHubActionsRole` |
| `policy_arns` | List of IAM policy ARNs to attach | `["arn:aws:iam::aws:policy/IAMReadOnlyAccess"]` |
| `github_branches` | List of allowed branches | `[]` (all branches) |
| `github_environments` | List of allowed environments | `[]` (not restricted) |
| `tags` | Tags to apply to resources | See variables.tf |

## Using the Role in GitHub Actions

After deploying this scenario, configure your GitHub Actions workflow to use OIDC authentication:

```yaml
name: AWS OIDC Example

on:
  push:
    branches:
      - main

permissions:
  id-token: write  # Required for OIDC
  contents: read

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::YOUR_ACCOUNT_ID:role/GitHubActionsRole
          aws-region: ap-northeast-1

      - name: Verify AWS credentials
        run: aws sts get-caller-identity
```

## Outputs

| Name | Description |
|------|-------------|
| `oidc_provider_arn` | ARN of the GitHub Actions OIDC provider |
| `oidc_provider_url` | URL of the GitHub Actions OIDC provider |
| `role_arn` | ARN of the IAM role for GitHub Actions |
| `role_name` | Name of the IAM role for GitHub Actions |
| `aws_account_id` | AWS account ID |

## Security Considerations

- The OIDC provider restricts which GitHub repositories can assume the role
- You can further restrict access by specifying `github_branches` or `github_environments`
- Grant only the minimum necessary permissions via `policy_arns`
- Consider using separate roles for different environments (dev, staging, production)
