---
title: Azure Container Apps トラブルシューティング
description: イメージのビルド、ACR への push、Container Apps の revision、HTTP 421、認証の問題を診断する
---

この文書は、ローカルでビルドしたイメージを Azure Container Registry (ACR) へ
push し、Azure Container Apps へデプロイするまでに確認された問題と切り分け手順を
まとめたものです。コマンドはこのディレクトリから実行してください。

```bash
cd infra/scenarios/azure_container_apps
```

## 最初に確認する項目

```bash
./scripts/validate_prerequisites.sh
```

続けて、操作対象のイメージを明示します。`build_image.sh`、`push_image.sh`、
`deploy_image.sh` では同じ値を使用してください。

```bash
export IMAGE_REPOSITORY=tasks-mcp-server
export IMAGE_TAG=v1
export IMAGE_PLATFORM=linux/amd64
```

環境変数を export していない場合、各スクリプトは `IMAGE_REPOSITORY=tasks-mcp-server`、
`IMAGE_TAG=latest`、`IMAGE_PLATFORM=linux/amd64` を使用します。たとえば ACR に `v1`
しか存在しない状態で `deploy_image.sh` を既定値のまま実行すると、存在しない
`latest` を検索します。

## 症状と確認先

| 症状 | 主な原因 | 最初の確認 |
| --- | --- | --- |
| `No outputs found` | Terraform state を持たないディレクトリで実行した | `pwd` と `terraform output` |
| `Local image not found` | build と push で repository または tag が異なる | `IMAGE_REPOSITORY` と `IMAGE_TAG` |
| `the specified tag does not exist` | 対象 tag を ACR へ push していない | ACR の tag 一覧 |
| Container App が起動しない | digest、`AcrPull`、registry identity、アプリ起動のいずれかに問題がある | revision と system log |
| `/health` は 200、`/mcp` は 421 | MCP の Host 検証が公開 FQDN を拒否した | デプロイ済み digest と稼働中 `app.py` |
| `/health` または `/mcp` が 401 | Microsoft Entra 組み込み認証が有効で token がない、または対象 audience が異なる | authentication output と Azure CLI sign-in |

## HTTP 421 Invalid Host header

### 何が 421 を返すか

MCP SDK 2.0.0 の Streamable HTTP transport は DNS rebinding 対策として `Host`
ヘッダーを検証します。このシナリオでは `src/app.py` が Azure Container Apps の
built-in environment variables から次のホスト名を許可します。

- アプリ共通 FQDN:
  `$CONTAINER_APP_NAME.$CONTAINER_APP_ENV_DNS_SUFFIX`
- revision 固有 FQDN: `$CONTAINER_APP_HOSTNAME`
- ローカル開発用の `localhost`、`127.0.0.1`、`[::1]`

`/health` は FastAPI 側の endpoint であり、この MCP transport の Host 検証を
通りません。そのため、`/health` が 200 でも `/mcp` だけが 421 になる場合があります。

### 421 の発生箇所を確認する

`curl --fail` はエラー本文を確認しにくいため、診断時は status と本文を分けて取得します。

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

`/mcp` の本文が `Invalid Host header` の場合は、次の2つを順番に切り分けます。

### 原因1: Host allowlist 対応前のイメージを実行している

今回確認された最初の 421 は、ローカルイメージには Host allowlist 対応後の
`app.py` が含まれている一方、ACR と Container App が対応前の古い digest を参照して
いたことが原因でした。

まず Terraform が保存した digest を確認します。

```bash
jq -r .container_image deployment.auto.tfvars.json
```

次に ACR の tag と digest を確認します。

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

Container App が参照する digest を確認します。

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

`deployment.auto.tfvars.json`、ACR の対象 tag、Container App の3つが同じ digest を
示す必要があります。ACR の tag だけが新しく、Container App が古い場合は
`deploy_image.sh` を再実行します。ACR 自体が古い場合は build からやり直します。

```bash
./scripts/build_image.sh
./scripts/push_image.sh
./scripts/deploy_image.sh
```

同名 tag の取り違えを避けるには、更新ごとに新しい tag を使います。

```bash
export IMAGE_TAG=v2
./scripts/build_image.sh
./scripts/push_image.sh
./scripts/deploy_image.sh
```

### 原因2: revision の切り替え中に旧 revision が応答した

イメージ更新後に確認された2回目の 421 は、ACR と Container App の digest が一致し、
新 revision も作成済みでした。更新直後だけ旧 revision が外部要求へ応答し、その
revision に含まれる古い MCP 設定が 421 を返していました。切り替え完了後は同じ要求が
200 になりました。

revision の状態を確認します。

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

`latestRevision` と `latestReadyRevision` が異なる場合は、新 revision の準備中です。
同じになってから検証を再実行します。

```bash
./scripts/verify_deployment.sh
```

### digest が一致しても 421 が続く場合

稼働中コンテナーに Host allowlist 対応コードが含まれるか確認します。

```bash
az containerapp exec \
  --subscription "$SUBSCRIPTION_ID" \
  --resource-group "$RESOURCE_GROUP" \
  --name "$APP_NAME" \
  --command "cat /app/app.py"
```

`transport_security_settings` が存在しない場合は、古いソースから作成されたイメージです。
現在の `src/` から新しい tag で build、push、deploy してください。

built-in environment variables も確認できます。次のコマンドは秘密情報を表示しません。

```bash
az containerapp exec \
  --subscription "$SUBSCRIPTION_ID" \
  --resource-group "$RESOURCE_GROUP" \
  --name "$APP_NAME" \
  --command "printenv CONTAINER_APP_NAME CONTAINER_APP_ENV_DNS_SUFFIX CONTAINER_APP_HOSTNAME CONTAINER_APP_PORT"
```

`container_app_fqdn` は、先頭2変数を `.` で連結した値と一致する必要があります。

```bash
terraform output -raw container_app_fqdn
```

現在の `app.py` が自動的に許可するのは、Container Apps のアプリ共通 FQDN と
revision 固有 FQDNです。独自ドメインから `/mcp` へ接続する場合は、そのドメインを
`allowed_hosts` と `allowed_origins` に追加する実装が別途必要です。

## Image tag または digest が一致しない

### ACR に tag が存在しない

次のエラーは、各スクリプトで異なる `IMAGE_TAG` を使ったときに発生します。

```text
the specified tag does not exist
```

同じ terminal session で値を export するか、各コマンドへ同じ値を渡します。

```bash
IMAGE_TAG=v2 ./scripts/build_image.sh
IMAGE_TAG=v2 ./scripts/push_image.sh
IMAGE_TAG=v2 ./scripts/deploy_image.sh
```

`deploy_image.sh` は ACR 上の tag を digest へ解決し、その値を
`deployment.auto.tfvars.json` に保存します。ローカルで build しただけでは、ACR と
Container App は更新されません。

### Docker が registry から pull しようとする

ローカルに指定 tag がない状態で `docker run` すると、Docker は ACR からの pull を
試み、未認証の場合は `authentication required` になります。先にローカルイメージを
確認します。

```bash
ACR_LOGIN_SERVER=$(terraform output -raw acr_login_server)

docker image inspect \
  "$ACR_LOGIN_SERVER/$IMAGE_REPOSITORY:$IMAGE_TAG"
```

存在しない場合は `build_image.sh` を実行します。ACR から明示的に pull する場合は
先に `az acr login --name "$ACR_NAME"` を実行します。

## Terraform output が取得できない

次の警告は、scenario の state を参照していない場合に発生します。

```text
Warning: No outputs found
```

scenario ディレクトリへ移動するか、`-chdir` を指定します。

```bash
terraform output -raw container_app_url

terraform \
  -chdir=infra/scenarios/azure_container_apps \
  output -raw container_app_url
```

正しいディレクトリでも output がない場合は、backend 設定と workspace を確認し、
必要であれば先に `terraform apply` を実行します。

## Container App がイメージを pull できない

revision と system log を確認します。

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

ACR scope のロール割り当ても確認します。

```bash
ACR_ID=$(terraform output -raw acr_id)

az role assignment list \
  --subscription "$SUBSCRIPTION_ID" \
  --scope "$ACR_ID" \
  --query "[?roleDefinitionName=='AcrPull' || roleDefinitionName=='AcrPush'].{role:roleDefinitionName,principalId:principalId}" \
  --output table
```

確認する項目は次のとおりです。

- Container App に user-assigned managed identity が割り当てられている
- 同じ identity の principal ID に `AcrPull` がある
- ローカルで push する principal に `AcrPush` がある
- ACR、Container App、role assignment の scope が同じ subscription にある

新しい managed identity のロール割り当ては反映に時間がかかる場合があります。
Terraform apply が成功しても pull に失敗する場合は、revision の再起動ではなく、まず
system log とロール割り当ての反映状態を確認してください。

## Microsoft Entra 認証で 401 になる

`enable_authentication = true` の場合、`/health` を含むすべてのパスで bearer token が
必要です。`verify_deployment.sh` は authentication identifier URI が output に存在する
場合、自動的に Azure CLI token を取得します。

Azure CLI の sign-in と token audience を確認します。

```bash
az account show --output table

AUDIENCE=$(terraform output -raw container_app_authentication_identifier_uri)
az account get-access-token \
  --resource "$AUDIENCE" \
  --query expiresOn \
  --output tsv
```

token 自体はログや Issue に貼り付けないでください。token を取得できても 401 になる
場合は、Container App の authConfig、tenant、allowed audience、および Azure CLI
public client の事前承認を確認します。

## 解決しない場合に収集する情報

次の情報があると、イメージ、revision、認証のどこで不整合が発生したかを確認できます。

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

次の値は共有しないでください。

- Azure access token
- Application Insights connection string
- Terraform state
- ACR credential
- Container App secret の値
