---
title: Provider Authentication
description: Authenticate Terraform providers for Azure, AWS, Google Cloud, and GitHub scenarios
ms.date: 2026-08-13
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
