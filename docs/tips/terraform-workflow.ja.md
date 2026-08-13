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

## Azure リソース名について

`azure_github_oidc` を除く Azure シナリオでは、`name` 変数を基底名として扱います。初回 apply
時に、各シナリオは 8 文字の小文字英数字による接尾辞を 1 個生成し、Azure の命名スコープで
衝突する可能性があるリソースに再利用します。たとえば、基底名 `azurecontainerapps` から
`azurecontainerapps-a1b2c3d4` のような名前が生成されます。Azure サービスの名前上限が短い
場合は基底名を切り詰めますが、接尾辞は維持します。

生成した接尾辞は Terraform ステートに保存され、同じステートを使用する後続の plan と apply
では変わりません。Azure の予約名と、独立した固定入力を持つ一部の子リソース名は変更しません。
`azure_github_oidc` は Entra と GitHub フェデレーションの表示名を安定させるため、対象外です。

> [!CAUTION]
> ステートの削除や紛失、`random_string` リソースの置換、destroy 後の再 apply では、異なる
> 接尾辞が生成されます。多くの Azure リソース名は変更できないため、Terraform によるリソースの
> 再作成が発生する可能性があります。ステートを保持し、命名変更を apply する前に plan を確認して
> ください。

## ステートの保存先の選択

ルートモジュールで別のバックエンドを宣言していない限り、Terraform はローカルステートを使用します。
分離された評価やリポジトリのテストにはローカルステートを使用します。共有または永続的なステートには、
[Azure Blob Storage バックエンドガイド](azure-blob-backend.ja.md)に従ってください。
