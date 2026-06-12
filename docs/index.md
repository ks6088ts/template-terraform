# Tutorials

This repository is a template for deploying and destroying the Terraform scenarios under `infra/scenarios/` via GNU Make. This page describes the basic operations.

## Prerequisites

- [Terraform CLI](https://developer.hashicorp.com/terraform/install)
- [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli) (required when using Azure scenarios)

You can check whether they are installed with the following command:

```shell
make install-deps-dev
```

## Basic operations

```shell
# Show the list of available make commands
make

# Log in to Azure
az login

# Show information about the current subscription
make info

# Specify the target scenario (a directory name under infra/scenarios)
SCENARIO=hello_world

# Deploy the resources
make deploy SCENARIO=$SCENARIO

# Show the output values
make output SCENARIO=$SCENARIO

# Destroy the resources
make destroy SCENARIO=$SCENARIO
```

> If `SCENARIO` is omitted, `hello_world` is used. See the [README](../README.md) for the list of available scenarios.

## (Optional) Configure a remote backend

Use this configuration when you want to manage the state file in a shared Azure Storage Account. It is not required if you only want to try things out locally.

1. Add the following to `infra/scenarios/YOUR_SCENARIO/backend.tf` for the target scenario (change the values to match your environment).

   ```hcl
   terraform {
     backend "azurerm" {
       use_cli              = true
       use_azuread_auth     = true
       resource_group_name  = "YOUR_RESOURCE_GROUP_NAME"
       storage_account_name = "YOUR_STORAGE_ACCOUNT_NAME"
       container_name       = "YOUR_CONTAINER_NAME"
       key                  = "YOUR_SCENARIO.dev.tfstate"
     }
   }
   ```

2. Assign the `Storage Blob Data Contributor` role on the backend Storage Account to yourself (or a service principal).

   ```shell
   ASSIGNEE_ID=$(az ad signed-in-user show --query id --output tsv)
   SUBSCRIPTION_ID=$(az account show --query id --output tsv)
   RESOURCE_GROUP_NAME="<your-resource-group-name>"
   STORAGE_ACCOUNT_NAME="<your-storage-account-name>"
   SCOPE="/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP_NAME/providers/Microsoft.Storage/storageAccounts/$STORAGE_ACCOUNT_NAME"

   az role assignment create \
     --assignee "$ASSIGNEE_ID" \
     --role "Storage Blob Data Contributor" \
     --scope "$SCOPE"
   ```

> You can create the backend Storage Account with the [azure_terraform_backend](../infra/scenarios/azure_terraform_backend/README.md) scenario.

## References

- [Terraform Documentation](https://developer.hashicorp.com/terraform/docs)
- [Authenticating using the Azure CLI](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/guides/azure_cli)
