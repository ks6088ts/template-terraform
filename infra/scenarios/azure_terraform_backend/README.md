# Azure Terraform Backend Scenario

Create Azure Storage Account for Terraform backend.

## Architecture

```mermaid
flowchart TB
    subgraph Azure["Azure Resource Group"]
        SA["Storage Account<br/>- Blob Container<br/>- terraform.tfstate"]
    end

    TF["Terraform CLI"] -->|"State Read/Write"| SA
```

## Prerequisites

- Terraform CLI installed
- Azure CLI installed
- Azure subscription

## How to use

```shell
# Log in to Azure
az login

# (Optional) Confirm the details for the currently logged-in user
az ad signed-in-user show

# Set environment variables
export ARM_SUBSCRIPTION_ID=$(az account show --query id --output tsv)

# Initialize Terraform
terraform init

# Plan the deployment
terraform plan -out=tfplan

# Apply the deployment
terraform apply tfplan
# or simply
terraform apply -auto-approve

# Confirm the output
terraform output

# Confirm the state file
cat terraform.tfstate

# Destroy the deployment
terraform destroy -auto-approve
```
