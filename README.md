---
title: template-terraform
description: Reusable Terraform modules and deployable cloud infrastructure scenarios
---

[![test](https://github.com/ks6088ts/template-terraform/actions/workflows/test.yml/badge.svg?branch=main)](https://github.com/ks6088ts/template-terraform/actions/workflows/test.yml?query=branch%3Amain)

A GitHub template repository for Terraform

## Documentation

Use the [documentation](./docs/index.md) for shared Terraform workflows,
provider authentication, and remote state guidance.

## Scenarios

### Azure

| Scenario | Overview |
| --- | --- |
| [azure_terraform_backend](./infra/scenarios/azure_terraform_backend/README.md) | Creates an Azure Storage account for a Terraform backend. |
| [azure_github_oidc](./infra/scenarios/azure_github_oidc/README.md) | Creates a service principal and role assignments for connecting GitHub Actions to Azure through OIDC. |
| [azure_apim_playground](./infra/scenarios/azure_apim_playground/README.md) | Deploys Azure API Management on the Consumption tier for testing a serverless API gateway. |
| [azure_container_apps](./infra/scenarios/azure_container_apps/README.md) | Deploys an externally accessible Azure Container App from a Docker Hub image. |
| [azure_datastore](./infra/scenarios/azure_datastore/README.md) | Deploys Azure data stores, including Cosmos DB, Storage, Key Vault, PostgreSQL, and Monitor, with public access for testing. |
| [azure_functions_flex_consumption](./infra/scenarios/azure_functions_flex_consumption/README.md) | Deploys a minimal serverless Azure Functions environment on the Flex Consumption plan. |
| [azure_microsoft_foundry](./infra/scenarios/azure_microsoft_foundry/README.md) | Deploys the Azure infrastructure required to run Microsoft Foundry workloads. |
| [azure_spoke_network](./infra/scenarios/azure_spoke_network/README.md) | Deploys a spoke network for an Azure hub-and-spoke architecture with a VNet, Bastion, private Storage endpoint, and VM. |
| [azure_inclusive_ai_labs](./infra/scenarios/azure_inclusive_ai_labs/README.md) | Deploys the azure_inclusive_ai_labs API and its VOICEVOX-powered speech synthesis services on Azure Container Apps. |
| [azure_kubernetes_playground](./infra/scenarios/azure_kubernetes_playground/README.md) | Deploys a cost-conscious Azure Container Registry and Azure Kubernetes Service environment without private networking. |
| [azure_postgresql](./infra/scenarios/azure_postgresql/README.md) | Deploys Azure Database for PostgreSQL Flexible Server with a generated administrator password and connection outputs. |

### AWS

| Scenario | Overview |
| --- | --- |
| [aws_github_oidc](./infra/scenarios/aws_github_oidc/README.md) | Creates an IAM role and permissions for connecting GitHub Actions to AWS through OIDC. |

### Google Cloud

| Scenario | Overview |
| --- | --- |
| [google_github_oidc](./infra/scenarios/google_github_oidc/README.md) | Creates Workload Identity Federation and permissions for connecting GitHub Actions to Google Cloud through OIDC. |

### GitHub

| Scenario | Overview |
| --- | --- |
| [github_secrets](./infra/scenarios/github_secrets/README.md) | Creates and manages GitHub repository environment secrets for use in GitHub Actions workflows. |

### Other

| Scenario | Overview |
| --- | --- |
| [hello_world](./infra/scenarios/hello_world/README.md) | Demonstrates basic Terraform behavior by generating a random string with the random provider. |
