---
title: Terraform ワークフロー
description: GNU Make または Terraform CLI を使用してリポジトリのシナリオを実行する
ms.date: 2026-08-13
ms.topic: how-to
---

## 前提条件

対象シナリオに必要なツールをインストールしてから、関連する
[プロバイダー認証](provider-authentication.ja.md)を構成します。リポジトリのルートで、
使用中のマシンから利用できる開発コマンドを確認します。

```bash
make install-deps-dev
```

このコマンドは不足しているツールを報告します。ツールのインストールは行いません。

## GNU Make を使用したシナリオの実行

`SCENARIO` に `infra/scenarios` 配下のディレクトリ名を設定します。省略した場合の既定値は
`hello_world` です。

```bash
SCENARIO=azure_container_apps

make init SCENARIO="$SCENARIO"
make plan SCENARIO="$SCENARIO"
make deploy SCENARIO="$SCENARIO"
make output SCENARIO="$SCENARIO"
make destroy SCENARIO="$SCENARIO"
```

`make deploy` は `terraform init` に続けて `terraform apply -auto-approve` を実行します。
個別の `make plan` ターゲットは実行しません。変更に承認が必要な場合は、デプロイ前にプランを
確認してください。

その他の開発用ターゲットには次のものがあります。

```bash
make lint SCENARIO="$SCENARIO"
make test SCENARIO="$SCENARIO"
make fix SCENARIO="$SCENARIO"
```

Azure シナリオでは、`make info` によってアクティブなサブスクリプションとテナントが表示されます。
Makefile は現在の Azure CLI セッションから `ARM_SUBSCRIPTION_ID` を取得し、Terraform コマンドに
エクスポートします。

> [!CAUTION]
> `make clean SCENARIO="$SCENARIO"` は、シナリオディレクトリ内の `.terraform*` ファイルと
> `terraform.*` ファイルを削除します。これにはローカルステートが含まれ、ローカル変数ファイルも
> 含まれる場合があります。実行前に、保持する必要があるものをすべてバックアップしてください。

## Terraform CLI を使用したシナリオの実行

シナリオディレクトリから Terraform コマンドを直接実行します。

```bash
cd infra/scenarios/<scenario>

terraform init
terraform fmt -check
terraform validate
terraform plan
terraform apply
terraform output
terraform destroy
```

AzureRM プロバイダーのバージョン 4 以降では、サブスクリプション ID が必要です。リポジトリの
Makefile を経由せずにコマンドを実行する場合は、Azure サブスクリプションを選択してから
エクスポートします。

```bash
export ARM_SUBSCRIPTION_ID=$(az account show --query id --output tsv)
```

Azure シナリオでは AzureRM v5 の自動リソースプロバイダー登録を無効にしています。各シナリオは
必要な名前空間のみを明示的に登録し、プラン時の場所とリソースプロバイダーの検証を有効に保ちます。
Azure Preflight Validation は有効にしません。

シナリオの README に追加の変数、既定値以外のフラグ、出力の確認、デプロイ後の操作が指定されて
いる場合は、その内容を優先します。

## ステートの保存先の選択

ルートモジュールで別のバックエンドを宣言していない限り、Terraform はローカルステートを使用します。
分離された評価やリポジトリのテストにはローカルステートを使用します。共有または永続的なステートには、
[Azure Blob Storage バックエンドガイド](azure-blob-backend.ja.md)に従ってください。
