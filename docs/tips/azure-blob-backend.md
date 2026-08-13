---
title: Azure Blob Storage Backend
description: Store Terraform state in Azure Blob Storage with Microsoft Entra ID authorization
ms.date: 2026-08-13
ms.topic: how-to
---

## When to use it

Terraform uses the local backend when a root module does not declare a backend.
Keep local state for isolated evaluation and repository tests. Use Azure Blob
Storage when a team or automation process must share durable state and state
locking.

> [!IMPORTANT]
> Terraform state can contain secrets. Restrict access to the storage container,
> retain secure backups during migration, and never commit state files.

## Create the backend storage

The `azure_terraform_backend` scenario creates the resource group, storage
account, and private Blob container used by this guide. Bootstrap that scenario
with local state so it does not depend on the backend it creates:

```bash
make deploy SCENARIO=azure_terraform_backend

BACKEND_DIR=infra/scenarios/azure_terraform_backend
RESOURCE_GROUP_NAME=$(terraform -chdir="$BACKEND_DIR" output -raw resource_group_name)
STORAGE_ACCOUNT_NAME=$(terraform -chdir="$BACKEND_DIR" output -raw storage_account_name)
CONTAINER_NAME=$(terraform -chdir="$BACKEND_DIR" output -raw storage_container_name)
```

Do not destroy the backend scenario while another scenario stores state in its
container.

## Grant access to the container

The `azurerm` backend can access Blob Storage directly with Microsoft Entra ID.
Grant the local user the `Storage Blob Data Contributor` role at container scope:

```bash
SUBSCRIPTION_ID=$(az account show --query id --output tsv)
ASSIGNEE_OBJECT_ID=$(az ad signed-in-user show --query id --output tsv)
CONTAINER_SCOPE="/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP_NAME}/providers/Microsoft.Storage/storageAccounts/${STORAGE_ACCOUNT_NAME}/blobServices/default/containers/${CONTAINER_NAME}"

az role assignment create \
  --assignee-object-id "$ASSIGNEE_OBJECT_ID" \
  --assignee-principal-type User \
  --role "Storage Blob Data Contributor" \
  --scope "$CONTAINER_SCOPE"
```

Assign the same data-plane role to the service principal or managed identity
used by automation. Role assignments can take several minutes to propagate.

## Configure a scenario

Create `backend.tf` in the target scenario directory. The repository
`.gitignore` excludes this file so environment-specific storage names are not
committed:

```hcl
terraform {
  backend "azurerm" {
    use_cli              = true
    use_azuread_auth     = true
    storage_account_name = "<storage-account-name>"
    container_name       = "<container-name>"
    key                  = "<scenario>.<environment>.tfstate"
  }
}
```

`use_cli` uses the current Azure CLI session. `use_azuread_auth` authorizes Blob
data-plane access with Microsoft Entra ID instead of a storage account key. The
state key must be unique for each independently managed scenario and
environment.

A backend block is evaluated during `terraform init`. It cannot refer to input
variables, local values, resource attributes, or data sources. The storage
account name, container name, and key must therefore be literal values or part
of a partial backend configuration.

For direct Blob data-plane access, `resource_group_name` is not required. It is
needed when the backend must query the Azure management plane, such as when
`lookup_blob_endpoint` is enabled for Azure DNS zone endpoints.

## Initialize new state

For a scenario that has not created state yet, initialize the backend normally:

```bash
cd infra/scenarios/<scenario>
terraform init
```

Verify the configured backend before applying resources:

```bash
terraform state list
```

Before the first apply, Terraform may report that no state file exists. After
resources have been applied, the command should return their resource
addresses.

## Migrate existing state

Back up the current state before changing backend configuration. The backup can
contain secrets and must be protected:

```bash
terraform state pull > state-backup.json
```

After adding or changing `backend.tf`, migrate the state:

```bash
terraform init -migrate-state
terraform state list
```

Use `-migrate-state` when state must be copied between local and remote backends
or between remote locations. Use `-reconfigure` only when Terraform should
accept the new configuration without copying state, for example when the state
already exists at the destination:

```bash
terraform init -reconfigure
```

Do not substitute `-reconfigure` for a required migration. Doing so can make an
existing infrastructure deployment appear to have no state.

## Use partial backend configuration

Partial configuration keeps reusable backend structure separate from target
values. Declare the backend type and authentication mode in `backend.tf`:

```hcl
terraform {
  backend "azurerm" {
    use_cli              = true
    use_azuread_auth     = true
    storage_account_name = ""
    container_name       = ""
    key                  = ""
  }
}
```

Place the remaining non-secret values in a file such as
`dev.azurerm.tfbackend`. A backend configuration file contains attributes only,
without `terraform` or `backend` blocks:

```hcl
storage_account_name = "<storage-account-name>"
container_name       = "<container-name>"
key                  = "<scenario>.dev.tfstate"
```

Pass the file explicitly during initialization:

```bash
terraform init -backend-config=dev.azurerm.tfbackend
```

Add `-migrate-state` when this changes the state location. Terraform copies the
merged backend configuration into `.terraform` and saved plan files. Do not put
credentials or other secrets in backend files or `-backend-config` arguments;
use the backend's supported environment variables or workload identity instead.

## Return to local state

Back up the remote state, remove the scenario-local `backend.tf`, and migrate to
the default local backend:

```bash
terraform state pull > state-backup.json
rm backend.tf
terraform init -migrate-state
terraform state list
```

Removing backend configuration does not delete the Blob object. Retain or remove
the remote copy according to the team's recovery policy after verifying the
local migration.

## Upgrade the PostgreSQL scenario

An existing working copy may contain an ignored Azure backend for
`azure_postgresql` with environment-specific storage names and the key
`azure_postgresql.dev.tfstate`. Removing that local `backend.tf` does not delete
its Blob state.

To keep using that state, recreate an ignored `backend.tf` with the same storage
account, container, key, and Entra ID settings before running `terraform init`.
Use `terraform init -reconfigure` if the working directory still contains stale
backend metadata. Use `-migrate-state` only when intentionally moving that state
to another backend or to local storage.

## References

* [Backend block configuration overview](https://developer.hashicorp.com/terraform/language/backend)
* [AzureRM backend reference](https://developer.hashicorp.com/terraform/language/backend/azurerm)
* [`terraform init` command](https://developer.hashicorp.com/terraform/cli/commands/init)
