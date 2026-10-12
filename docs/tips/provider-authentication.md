---
title: Provider Authentication
description: Authenticate Terraform providers for Azure, AWS, Google Cloud, Databricks, Cloudflare, and GitHub scenarios
ms.date: 2026-10-11
ms.topic: how-to
---

## Azure

Authenticate the Azure CLI, select the intended subscription, and inspect the
active account before running an Azure scenario:

```bash
az login
az account set --subscription "<subscription-name-or-id>"
az account show --output table
```

The repository Makefile derives and exports `ARM_SUBSCRIPTION_ID`. Export it
manually when running Terraform directly:

```bash
export ARM_SUBSCRIPTION_ID=$(az account show --query id --output tsv)
```

The Azure Blob Storage backend has separate data-plane authorization
requirements. Follow the [Azure Blob Storage backend guide](azure-blob-backend.md)
when remote state is enabled.

## AWS

Use the standard AWS credential chain. A configured profile avoids placing
credentials in Terraform files:

```bash
aws configure --profile <profile>
export AWS_PROFILE=<profile>
aws sts get-caller-identity
```

AWS IAM Identity Center users can authenticate an existing SSO profile instead:

```bash
aws sso login --profile <profile>
export AWS_PROFILE=<profile>
```

The AWS SDK also recognizes `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, an
optional `AWS_SESSION_TOKEN`, and region variables. Prefer temporary credentials
over long-lived access keys.

## Google Cloud

Use Application Default Credentials for local Terraform runs:

```bash
gcloud auth application-default login
gcloud auth application-default set-quota-project <project-id>
```

A scenario may separately require `TF_VAR_project_id` because provider
credentials do not select the Terraform input variable. Set that value as shown
in the scenario README.

The Google SDK also recognizes `GOOGLE_APPLICATION_CREDENTIALS` when a credential
file is required. Do not commit credential files.

## Databricks

For Azure Databricks workspace scenarios, complete the [Azure CLI login](#azure)
with an identity in the workspace's tenant. The scenario configures the Databricks
provider with a workspace-level HTTPS `host` and `auth_type = "azure-cli"`.
No PAT, client secret, or Databricks CLI is required.

The identity must have access to the Databricks workspace and permission to read
or create the scenario's objects. See the scenario prerequisites for optional
Notebook and Unity Catalog schema creation privileges. Azure resource-management RBAC alone does not grant
Databricks data-plane access. Do not set `DATABRICKS_ACCOUNT_ID` for these
workspace-level operations; account-console settings are not workspace settings.
Do not place tokens or credentials in Terraform files.

Authentication does not select the Terraform input workspace. Follow the
[Databricks playground scenario](../../infra/scenarios/databricks_playground/README.md)
to pass the existing workspace's scheme-free `workspace_url` through
`TF_VAR_workspace_url`. Its provider adds `https://`; do not pass the
`databricks_host` output as this input. The `databricks_*` Makefile targets do not
derive `ARM_SUBSCRIPTION_ID`, and these Databricks-provider operations do not require it.
A separately configured Azure Blob backend still needs its own authentication.

CI mock and local API fixture tests require no Azure credentials or real
Databricks workspace. Real-workspace authentication and connectivity require a
manual plan; Notebook execution requires the scenario's Databricks UI checks.

## Cloudflare

The Cloudflare provider reads `CLOUDFLARE_API_TOKEN`. Create an
[API Token](https://developers.cloudflare.com/fundamentals/api/get-started/create-token/)
limited to the intended account and the permissions needed by the scenario.
The Account lookup scenario needs only `Account Settings: Read`.
Use an API Token instead of a legacy Global API Key.

For a user API Token in the portal:

1. Open [My Profile → API Tokens](https://dash.cloudflare.com/profile/api-tokens/).
2. Select **Create Token**, then create a custom token.
3. Set **Permissions** to **Account → Account Settings → Read**.
4. Under **Account Resources**, select **Include → Specific account** and the
   account whose ID you will pass to Terraform.
   Set a suitable expiry under **TTL** and plan to rotate the token before it expires.
5. Select **Continue to summary**, check the scope, and select **Create Token**.
6. Save the token in a secure secret store. The secret is displayed only once;
   do not paste it into chat, commit it, or place it in a variable file.

In Bash, enter the token without echoing it or including its value in shell history:

```bash
read -r -s -p "Cloudflare API token: " CLOUDFLARE_API_TOKEN
printf '\n'
export CLOUDFLARE_API_TOKEN
```

These `read` options are Bash-specific. If your terminal uses zsh (the macOS
default), start `bash` first and run both this snippet and Terraform in that Bash
session. Do not enable shell tracing (`set -x`) while handling the token.
Unset legacy `CLOUDFLARE_API_KEY`, `CLOUDFLARE_EMAIL`, and
`CLOUDFLARE_API_USER_SERVICE_KEY` variables if they are set: the provider does not
allow them alongside API Token authentication.

Run Terraform in that same terminal; exporting a token there does not set it
in an already-running VS Code task or another terminal session.
Authentication does not select the Terraform input Account ID. Set `account_id`
in a variable file or through `TF_VAR_account_id` as described in the scenario README.
For GitHub Actions, store `CLOUDFLARE_API_TOKEN` and `CLOUDFLARE_ACCOUNT_ID`
in the `dev` environment Secrets; the workflow passes the latter as `TF_VAR_account_id`.
The separate mock-test job needs neither these Secrets nor environment approval.
Do not write the token into Terraform variables, provider configuration, or files.

## GitHub

The GitHub provider reads `GITHUB_TOKEN`. A local GitHub CLI session can supply
the token without writing it to a Terraform file:

```bash
gh auth login
gh auth status
export GITHUB_TOKEN=$(gh auth token)
```

Use a token whose repository and organization permissions match the resources
managed by the scenario.

## Automation

Prefer workload identity federation or another short-lived credential mechanism
for CI/CD. Store credentials in the automation platform's secret store and pass
them through supported environment variables. Do not put access keys, client
secrets, tokens, or credential files in Terraform configuration, backend
configuration, variable files, or saved plans.
