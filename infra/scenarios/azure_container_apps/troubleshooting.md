---
title: Azure Container Apps troubleshooting
description: Diagnose image builds, ACR pushes, Container Apps revisions, HTTP 421 responses, and authentication
---

This document covers the issues observed while building an image locally, pushing
it to Azure Container Registry (ACR), and deploying it to Azure Container Apps.
Run the commands from this directory:

```bash
cd infra/scenarios/azure_container_apps
```

## Initial checks

```bash
./scripts/validate_prerequisites.sh
```

Then explicitly select the image to operate on. Use the same values for
`build_image.sh`, `push_image.sh`, and `deploy_image.sh`.

```bash
export IMAGE_REPOSITORY=tasks-mcp-server
export IMAGE_TAG=v1
export IMAGE_PLATFORM=linux/amd64
```

If these variables are not exported, each script uses
`IMAGE_REPOSITORY=tasks-mcp-server`, `IMAGE_TAG=latest`, and
`IMAGE_PLATFORM=linux/amd64`. For example, if ACR contains only `v1`, running
`deploy_image.sh` with its defaults searches for a nonexistent `latest` tag.

## Symptoms and starting points

| Symptom | Likely cause | First check |
| --- | --- | --- |
| `No outputs found` | The command ran outside the directory that owns the Terraform state | `pwd` and `terraform output` |
| `Local image not found` | The repository or tag differs between build and push | `IMAGE_REPOSITORY` and `IMAGE_TAG` |
| `the specified tag does not exist` | The selected tag was not pushed to ACR | The ACR tag list |
| The Container App does not start | The digest, `AcrPull`, registry identity, or application startup failed | The revision and system log |
| `/health` is 200 but `/mcp` is 421 | MCP Host validation rejected the public FQDN | The deployed digest and runtime `app.py` |
| `/health` or `/mcp` is 401 | Microsoft Entra built-in authentication is enabled without a token, or the token has the wrong audience | Authentication outputs and Azure CLI sign-in |

## HTTP 421 Invalid Host header

### What returns 421

The MCP SDK 2.0.0 Streamable HTTP transport validates the `Host` header to
protect against DNS rebinding. In this scenario, `src/app.py` uses Azure
Container Apps built-in environment variables to allow these hostnames:

- App-level FQDN:
  `$CONTAINER_APP_NAME.$CONTAINER_APP_ENV_DNS_SUFFIX`
- Revision-specific FQDN: `$CONTAINER_APP_HOSTNAME`
- `localhost`, `127.0.0.1`, and `[::1]` for local development

`/health` is a FastAPI endpoint and does not pass through this MCP transport Host
validation. Therefore, `/health` can return 200 while only `/mcp` returns 421.

### Locate the 421 response

Start with verbose verification. It shows the request targets, HTTP status,
response format, and MCP tool names without printing the bearer token.

```bash
./scripts/verify_deployment.sh --verbose
```

Because `curl --fail` makes the error body difficult to inspect, collect the
status and body separately during diagnosis.

```bash
APP_URL=$(terraform output -raw container_app_url)

curl --silent --show-error \
  --write-out '\nHTTP %{http_code}\n' \
  "$APP_URL/health"

curl --silent --show-error \
  --header "Content-Type: application/json" \
  --header "Accept: application/json, text/event-stream" \
  --data '{"jsonrpc":"2.0","id":1,"method":"tools/list"}' \
  --write-out '\nHTTP %{http_code}\n' \
  "$APP_URL/mcp"
```

If the `/mcp` response body is `Invalid Host header`, investigate the following
two causes in order.

### Cause 1: The running image predates the Host allowlist

The first observed 421 occurred when the local image contained the updated
`app.py` with the Host allowlist, but ACR and the Container App still referenced
an older digest that predated the update.

First, inspect the digest persisted by Terraform.

```bash
jq -r .container_image deployment.auto.tfvars.json
```

Then inspect the tags and digests in ACR.

```bash
ACR_NAME=$(terraform output -raw acr_name)
SUBSCRIPTION_ID=$(terraform output -raw acr_id | cut -d/ -f3)

az acr repository show-tags \
  --subscription "$SUBSCRIPTION_ID" \
  --name "$ACR_NAME" \
  --repository "$IMAGE_REPOSITORY" \
  --detail \
  --output table
```

Inspect the digest referenced by the Container App.

```bash
APP_NAME=$(terraform output -raw container_app_name)
RESOURCE_GROUP=$(terraform output -raw resource_group_name)

az containerapp show \
  --subscription "$SUBSCRIPTION_ID" \
  --resource-group "$RESOURCE_GROUP" \
  --name "$APP_NAME" \
  --query 'properties.template.containers[0].image' \
  --output tsv
```

`deployment.auto.tfvars.json`, the selected ACR tag, and the Container App must
identify the same digest. If only the ACR tag is current, rerun
`deploy_image.sh`. If ACR is also stale, repeat the workflow from the build.

```bash
./scripts/build_image.sh
./scripts/push_image.sh
./scripts/deploy_image.sh
```

Use a new tag for each update to avoid confusing reused tags.

```bash
export IMAGE_TAG=v2
./scripts/build_image.sh
./scripts/push_image.sh
./scripts/deploy_image.sh
```

### Cause 2: The previous revision responded during the revision change

The second observed 421 occurred after the ACR and Container App digests matched
and a new revision had been created. Immediately after the update, the previous
revision still responded to an external request and returned 421 from its older
MCP configuration. The same request returned 200 after the revision change
completed.

Inspect the revision state.

```bash
az containerapp show \
  --subscription "$SUBSCRIPTION_ID" \
  --resource-group "$RESOURCE_GROUP" \
  --name "$APP_NAME" \
  --query '{latestRevision:properties.latestRevisionName,latestReadyRevision:properties.latestReadyRevisionName}' \
  --output yaml

az containerapp revision list \
  --subscription "$SUBSCRIPTION_ID" \
  --resource-group "$RESOURCE_GROUP" \
  --name "$APP_NAME" \
  --output table
```

If `latestRevision` and `latestReadyRevision` differ, the new revision is still
becoming ready. Run verification again after they match.

```bash
./scripts/verify_deployment.sh
```

### If 421 persists after the digests match

Check whether the running container includes the Host allowlist implementation.

```bash
az containerapp exec \
  --subscription "$SUBSCRIPTION_ID" \
  --resource-group "$RESOURCE_GROUP" \
  --name "$APP_NAME" \
  --command "cat /app/app.py"
```

If `transport_security_settings` is absent, the image was built from older
source. Build, push, and deploy a new tag from the current `src/` directory.

You can also inspect the built-in environment variables. This command does not
display secrets.

```bash
az containerapp exec \
  --subscription "$SUBSCRIPTION_ID" \
  --resource-group "$RESOURCE_GROUP" \
  --name "$APP_NAME" \
  --command "printenv CONTAINER_APP_NAME CONTAINER_APP_ENV_DNS_SUFFIX CONTAINER_APP_HOSTNAME CONTAINER_APP_PORT"
```

`container_app_fqdn` must equal the first two values joined with a `.`.

```bash
terraform output -raw container_app_fqdn
```

The current `app.py` automatically allows the Container Apps app-level and
revision-specific FQDNs. Connecting to `/mcp` through a custom domain requires
additional implementation to add that domain to `allowed_hosts` and
`allowed_origins`.

## Image tag or digest does not match

### The ACR tag does not exist

The following error occurs when the scripts use different `IMAGE_TAG` values.

```text
the specified tag does not exist
```

Export the value in the same terminal session, or pass the same value to every
command.

```bash
IMAGE_TAG=v2 ./scripts/build_image.sh
IMAGE_TAG=v2 ./scripts/push_image.sh
IMAGE_TAG=v2 ./scripts/deploy_image.sh
```

`deploy_image.sh` resolves the ACR tag to a digest and stores it in
`deployment.auto.tfvars.json`. Building locally does not update ACR or the
Container App.

### Docker attempts to pull from the registry

If the selected tag does not exist locally, `docker run` attempts to pull it
from ACR and returns `authentication required` when Docker is not authenticated.
Check the local image first.

```bash
ACR_LOGIN_SERVER=$(terraform output -raw acr_login_server)

docker image inspect \
  "$ACR_LOGIN_SERVER/$IMAGE_REPOSITORY:$IMAGE_TAG"
```

Run `build_image.sh` if the image does not exist. To pull explicitly from ACR,
run `az acr login --name "$ACR_NAME"` first.

## Terraform outputs are unavailable

The following warning appears when the command does not reference the scenario's
Terraform state.

```text
Warning: No outputs found
```

Change to the scenario directory or specify `-chdir`.

```bash
terraform output -raw container_app_url

terraform \
  -chdir=infra/scenarios/azure_container_apps \
  output -raw container_app_url
```

If outputs remain unavailable in the correct directory, verify the backend and
workspace and run `terraform apply` first when required.

## The Container App cannot pull the image

Inspect the revision and system log.

```bash
az containerapp revision list \
  --subscription "$SUBSCRIPTION_ID" \
  --resource-group "$RESOURCE_GROUP" \
  --name "$APP_NAME" \
  --output table

az containerapp logs show \
  --subscription "$SUBSCRIPTION_ID" \
  --resource-group "$RESOURCE_GROUP" \
  --name "$APP_NAME" \
  --type system \
  --tail 100
```

Also inspect the role assignments at the ACR scope.

```bash
ACR_ID=$(terraform output -raw acr_id)

az role assignment list \
  --subscription "$SUBSCRIPTION_ID" \
  --scope "$ACR_ID" \
  --query "[?roleDefinitionName=='AcrPull' || roleDefinitionName=='AcrPush'].{role:roleDefinitionName,principalId:principalId}" \
  --output table
```

Verify the following conditions:

- The Container App has a user-assigned managed identity.
- The same identity's principal ID has `AcrPull`.
- The principal pushing locally has `AcrPush`.
- ACR, the Container App, and the role assignment scopes use the same subscription.

Role assignments for a new managed identity can take time to propagate. If a
pull fails after Terraform apply succeeds, inspect the system log and role
assignment propagation before restarting the revision.

## Microsoft Entra authentication returns 401

When `enable_authentication = true`, every path, including `/health`, requires a
bearer token. `verify_deployment.sh` obtains an Azure CLI token automatically
when the authentication identifier URI is present in the Terraform outputs.

Check the Azure CLI sign-in and token audience.

```bash
az account show --output table

AUDIENCE=$(terraform output -raw container_app_authentication_identifier_uri)
az account get-access-token \
  --resource "$AUDIENCE" \
  --query expiresOn \
  --output tsv
```

Do not paste the token itself into logs or issues. If token acquisition succeeds
but requests still return 401, inspect the Container App authConfig, tenant,
allowed audience, and Azure CLI public client pre-authorization.

## Information to collect if the issue persists

The following information helps identify whether the mismatch is in the image,
revision, or authentication configuration.

```bash
terraform output -raw resource_group_name
terraform output -raw acr_name
terraform output -raw container_app_name
terraform output -raw container_app_fqdn
jq -r .container_image deployment.auto.tfvars.json

az containerapp show \
  --subscription "$SUBSCRIPTION_ID" \
  --resource-group "$RESOURCE_GROUP" \
  --name "$APP_NAME" \
  --query '{image:properties.template.containers[0].image,latestRevision:properties.latestRevisionName,latestReadyRevision:properties.latestReadyRevisionName}' \
  --output yaml
```

Do not share these values:

- Azure access tokens
- Application Insights connection strings
- Terraform state
- ACR credentials
- Container App secret values
