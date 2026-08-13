---
title: Azure Blob Storage バックエンド
description: Microsoft Entra ID 認可を使用して Terraform ステートを Azure Blob Storage に保存する
ms.date: 2026-08-13
ms.topic: how-to
---

## 使用する場合

ルートモジュールでバックエンドを宣言していない場合、Terraform はローカルバックエンドを
使用します。分離された評価やリポジトリのテストでは、ローカルステートを維持します。チームや
自動化プロセスで永続的なステートとステートロックを共有する必要がある場合は、Azure Blob
Storage を使用します。

> [!IMPORTANT]
> Terraform ステートにはシークレットが含まれる可能性があります。ストレージコンテナーへの
> アクセスを制限し、移行中は安全なバックアップを保持して、ステートファイルをコミットしないでください。

## バックエンドストレージの作成

`azure_terraform_backend` シナリオは、このガイドで使用するリソースグループ、ストレージ
アカウント、プライベート Blob コンテナーを作成します。作成対象のバックエンドに依存しないように、
このシナリオはローカルステートでブートストラップします。

```bash
make deploy SCENARIO=azure_terraform_backend

BACKEND_DIR=infra/scenarios/azure_terraform_backend
RESOURCE_GROUP_NAME=$(terraform -chdir="$BACKEND_DIR" output -raw resource_group_name)
STORAGE_ACCOUNT_NAME=$(terraform -chdir="$BACKEND_DIR" output -raw storage_account_name)
CONTAINER_NAME=$(terraform -chdir="$BACKEND_DIR" output -raw storage_container_name)
```

別のシナリオがコンテナーにステートを保存している間は、バックエンドシナリオを破棄しないでください。

## コンテナーへのアクセス権の付与

`azurerm` バックエンドは、Microsoft Entra ID を使用して Blob Storage に直接アクセスできます。
ローカルユーザーに、コンテナースコープで `Storage Blob Data Contributor` ロールを付与します。

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

自動化で使用するサービスプリンシパルまたはマネージド ID にも、同じデータプレーンロールを
割り当てます。ロールの割り当てが反映されるまで数分かかる場合があります。

## シナリオの構成

対象シナリオのディレクトリに `backend.tf` を作成します。リポジトリの `.gitignore` では
このファイルが除外されるため、環境固有のストレージ名はコミットされません。

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

`use_cli` は現在の Azure CLI セッションを使用します。`use_azuread_auth` はストレージ
アカウントキーの代わりに Microsoft Entra ID を使用して Blob データプレーンへのアクセスを
認可します。ステートキーは、独立して管理するシナリオと環境の組み合わせごとに一意である必要があります。

バックエンドブロックは `terraform init` の実行時に評価されます。入力変数、ローカル値、
リソース属性、データソースは参照できません。そのため、ストレージアカウント名、コンテナー名、
キーにはリテラル値を指定するか、部分バックエンド構成に含める必要があります。

Blob データプレーンに直接アクセスする場合、`resource_group_name` は不要です。
`lookup_blob_endpoint` を Azure DNS ゾーンエンドポイントに対して有効にする場合など、
バックエンドが Azure 管理プレーンへ問い合わせる必要がある場合には指定が必要です。

## 新しいステートの初期化

まだステートを作成していないシナリオでは、通常どおりバックエンドを初期化します。

```bash
cd infra/scenarios/<scenario>
terraform init
```

リソースを適用する前に、構成済みのバックエンドを確認します。

```bash
terraform state list
```

初回適用の前は、ステートファイルが存在しないと Terraform が報告する場合があります。
リソースの適用後、このコマンドはリソースアドレスを返します。

## 既存ステートの移行

バックエンド構成を変更する前に、現在のステートをバックアップします。バックアップには
シークレットが含まれる可能性があるため、保護する必要があります。

```bash
terraform state pull > state-backup.json
```

`backend.tf` を追加または変更した後、ステートを移行します。

```bash
terraform init -migrate-state
terraform state list
```

ローカルバックエンドとリモートバックエンドの間、またはリモートの保存先間でステートをコピーする
必要がある場合は、`-migrate-state` を使用します。コピーせずに新しい構成を Terraform に受け入れ
させる場合に限り、`-reconfigure` を使用します。たとえば、移行先にステートがすでに存在する場合です。

```bash
terraform init -reconfigure
```

必要な移行を `-reconfigure` で代用しないでください。既存のインフラストラクチャデプロイに
ステートがないように見える可能性があります。

## 部分バックエンド構成の使用

部分構成を使用すると、再利用可能なバックエンド構造と対象固有の値を分離できます。
`backend.tf` でバックエンドの種類と認証モードを宣言します。

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

残りのシークレットではない値を、`dev.azurerm.tfbackend` などのファイルに配置します。
バックエンド構成ファイルには属性のみを含め、`terraform` ブロックや `backend` ブロックは
含めません。

```hcl
storage_account_name = "<storage-account-name>"
container_name       = "<container-name>"
key                  = "<scenario>.dev.tfstate"
```

初期化時にファイルを明示的に渡します。

```bash
terraform init -backend-config=dev.azurerm.tfbackend
```

これによってステートの保存先が変わる場合は、`-migrate-state` を追加します。Terraform は
マージしたバックエンド構成を `.terraform` と保存済みのプランファイルにコピーします。資格情報や
その他のシークレットをバックエンドファイルや `-backend-config` 引数に含めないでください。
代わりに、バックエンドがサポートする環境変数またはワークロード ID を使用します。

## ローカルステートへの復帰

リモートステートをバックアップし、シナリオ固有の `backend.tf` を削除して、既定のローカル
バックエンドに移行します。

```bash
terraform state pull > state-backup.json
rm backend.tf
terraform init -migrate-state
terraform state list
```

バックエンド構成を削除しても、Blob オブジェクトは削除されません。ローカルへの移行を確認した後、
チームの復旧ポリシーに従ってリモートコピーを保持または削除します。

## PostgreSQL シナリオのアップグレード

既存の作業コピーには、環境固有のストレージ名と `azure_postgresql.dev.tfstate` キーを設定した、
`azure_postgresql` 用の無視対象 Azure バックエンドが含まれている場合があります。ローカルの
`backend.tf` を削除しても、その Blob ステートは削除されません。

そのステートを引き続き使用するには、`terraform init` を実行する前に、同じストレージアカウント、
コンテナー、キー、Entra ID 設定を指定した無視対象の `backend.tf` を再作成します。作業ディレクトリに
古いバックエンドメタデータが残っている場合は、`terraform init -reconfigure` を使用します。
別のバックエンドまたはローカルストレージへ意図的に移動する場合に限り、`-migrate-state` を使用します。

## 参考資料

* [バックエンドブロック構成の概要](https://developer.hashicorp.com/terraform/language/backend)
* [AzureRM バックエンドのリファレンス](https://developer.hashicorp.com/terraform/language/backend/azurerm)
* [`terraform init` コマンド](https://developer.hashicorp.com/terraform/cli/commands/init)
