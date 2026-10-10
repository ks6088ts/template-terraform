---
title: Terraform ワークフロー
description: GNU Make または Terraform CLI を使用してリポジトリのシナリオを実行する
ms.date: 2026-10-11
ms.topic: how-to
---

## 前提条件

### ローカル端末のツール

| ツール | 必要な場合 | 確認方法 |
|---|---|---|
| Git | リポジトリの取得・更新 | `git --version` |
| Terraform CLI | すべてのシナリオ | `terraform version` |
| GNU Make | `make` の手順を使用する場合 | `make --version` |
| Bash | README の Bash コマンドや検証スクリプトを実行する場合 | `bash --version` |
| Azure CLI | Azure CLI 認証や `az` による状態確認を行う場合 | `az version` |
| その他の CLI・ツール | 対象シナリオの README に記載されている場合 | 各シナリオの手順を参照 |

Terraform の必要バージョンは、対象シナリオの `versions.tf` の `required_version`
を確認してください。テストの構文には追加のバージョン要件がある場合があるため、
開発・テストでは [CI](../../.github/workflows/test.yml) の `TERRAFORM_VERSION` を
基準にします。provider の制約と `.terraform.lock.hcl` はリポジトリの設定を使用します。
GNU Make は Terraform CLI を直接実行する場合には不要です。

未インストールの場合は、[Terraform CLI](https://developer.hashicorp.com/terraform/install)、
[Git](https://git-scm.com/downloads)、[GNU Make](https://www.gnu.org/software/make/)、
[Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli) の公式案内に従ってください。
シェルの手順は Bash で実行します。Windows では WSL などの Bash 環境を用意し、
その環境から必要なツールを実行できることを確認してください。

### 認証と権限

関連する [プロバイダー認証](provider-authentication.ja.md)を構成し、意図した
アカウント・サブスクリプション・プロジェクトを選択します。Azure CLI 認証では、
認証後に次を実行し、対象サブスクリプションと `state=Enabled` を確認します。

```bash
az account show --query '{subscription:id,name:name,tenant:tenantId,state:state}' -o table
```

認証成功だけではデプロイ権限を確認できません。少なくとも次の条件が必要です。

- 対象スコープで、シナリオのリソースを作成・参照・更新・削除できること。
  Azure で Resource Group 自体を作る場合は、その作成権限も必要です。
- シナリオが使用する Azure リソースプロバイダーが登録済み、またはその登録権限が
  あること。必要な名前空間は対象の `providers.tf` を確認します。
- ロール割り当て、Entra ID 操作、診断取得などを行うシナリオでは、それぞれの追加
  権限があること。リソースの管理権限だけでデータプレーンの読み書きは保証されません。
- 共有 backend を使う場合は、state 保存先へのアクセス権限があること。
  [Azure Blob Storage バックエンド](azure-blob-backend.ja.md)は個別の認可要件を持ちます。

組織ポリシーで必要なリソースが禁止されている場合は、対応する構成を選んでください。
ポリシーの無効化や、未承認の権限・機能登録を前提にしないでください。

### ネットワーク・容量・ステート

- ローカル端末から Terraform Registry、provider の配布先、利用するクラウド API
  への DNS 解決と HTTPS 接続ができること。proxy や証明書の制約がある場合は、
  組織の手順に従って構成します。TLS 証明書検証を無効にしないでください。
- リージョンでサービス・SKU が利用でき、サブスクリプションの quota と空き容量が
  足りること。SKU の一覧に載っていても、実際の割り当てが成功する保証ではありません。
- ワークロードからの通信要件は、シナリオの README で個別に確認すること。
  ローカル端末のインターネット接続と VM の outbound 接続は別の要件です。
- 作成時の課金を確認し、plan をレビューできること。認証や plan の成功だけで、
  デプロイや実通信の成功とは判断しないでください。
- ローカル state を使用する場合は、作業ディレクトリを安全に保持できること。
  state・plan・資格情報には機密値が含まれる場合があります。Git やログに公開しないでください。

### 開発用ツールの確認

リポジトリ全体の開発・lint・コスト見積もりを行う場合は、リポジトリルートで
次を実行します。

```bash
make install-deps-dev
```

このコマンドは `terraform`、`tfupdate`、`curl`、`jq`、`az`、`gh`、`tflint`、
`trivy`、`infracost`、`actionlint` の存在を確認します。不足を報告して失敗しますが、インストールは
行いません。これらすべてが、個々のシナリオのデプロイに必要なわけではありません。
シナリオ固有の追加条件は各 README の「前提条件」を優先してください。

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

## Terraform プロバイダーの更新

Dependabot は、同じ Terraform プロバイダーの更新を、設定されたすべてのシナリオと
モジュールディレクトリを横断して 1 つの Pull Request にまとめます。

プロバイダー制約と追跡対象の依存関係ロックファイルをローカルで一括更新し、
各 Terraform ルートを検証するには、次を実行します。

```bash
make update
```

このターゲットには Terraform と Git に加えて
[tfupdate](https://github.com/minamijoyo/tfupdate)、`curl`、`jq` が必要です。
tfupdate はリリースからインストールするか、Go を使用します。

```bash
go install github.com/minamijoyo/tfupdate@v0.10.2
```

Git で追跡している `.terraform.lock.hcl` からプロバイダーと現在の major を検出します。
Terraform Registry にプロバイダーごとに 1 回問い合わせ、その major 内の最新安定版を選択します。
プレリリースは除外します。tfupdate の HCL パーサーを使用し、シナリオのプロバイダー制約を
`~> <最新バージョン>`、再利用可能なモジュールの制約を
`>= <最新バージョン>, <次のmajor>.0.0` に更新します。
固定バージョンのプロバイダーも major を変えずに更新します。同じプロバイダーで
ロック済み major が異なる場合は、自動統一せずエラーにします。

制約更新後、追跡済みロックファイルがある各ルートで、分離した一時 Terraform データディレクトリを
使用して `terraform init -backend=false -upgrade -input=false`、
`terraform providers lock -platform=darwin_arm64 -platform=linux_amd64`、
`terraform validate` を実行します。ロックの生成では、macOS ARM64 の開発端末と Linux AMD64 の
CI runner の両方の checksum を記録します。
リモートバックエンドへの接続、既存の `.terraform/` に保存されたバックエンド設定の再利用、
ロックファイルを追跡していないモジュールでの新規作成は行いません。
自動更新の対象は、追跡済みロックファイルに含まれるプロバイダーのみです。

Registry の取得に失敗した場合は、制約を変更する前に停止します。その後の更新や検証で失敗した場合も
停止しますが、更新済みのファイルは保持するため `git diff` で確認してください。
provider の動作変更を確認するときは、validate だけでなく plan やシナリオのテストも必要です。

更新ワークフローのオフライン回帰テストは `sh scripts/tests/test_update.sh` で実行できます。

### provider を更新せずに不足した platform checksum を補完する

readonly の初期化で `Provider lock file not updated` が表示され、validate が
`the cached package ... does not match any of the checksums recorded in the dependency
lock file` で失敗する場合、runner の platform 用 `h1:` checksum が不足している可能性があります。
`zh:` はダウンロードしたアーカイブの checksum であり、validate ではインストール後の
展開済み package に対応する `h1:` checksum も必要です。

リポジトリルートで、provider の選択済みバージョンを変更せず、追跡済みの全 lock file を補完します。

```bash
(
  set -e
  data_root=$(mktemp -d)
  trap 'find "$data_root" -depth -delete' EXIT
  git ls-files 'infra/**/.terraform.lock.hcl' >"$data_root/lock-files"
  while IFS= read -r lock_file; do
    root=${lock_file%/.terraform.lock.hcl}
    export TF_DATA_DIR="$data_root/$(printf '%s' "$root" | tr '/' '_')"
    terraform -chdir="$root" init -backend=false -lockfile=readonly -input=false
    terraform -chdir="$root" providers lock -platform=darwin_arm64 -platform=linux_amd64
    terraform -chdir="$root" init -backend=false -lockfile=readonly -input=false
    terraform -chdir="$root" validate
  done <"$data_root/lock-files"
)
```

この手順は `-upgrade` を使わず、backend に接続せず、既存の local state や `.terraform/`
ディレクトリも変更しません。更新した lock file を確認してコミットしてください。
checksum 検証を回避せず、CI の初期化は readonly のままにします。

Azure シナリオでは、`make info` によってアクティブなサブスクリプションとテナントが表示されます。
Makefile は現在の Azure CLI セッションから `ARM_SUBSCRIPTION_ID` を取得し、Terraform コマンドに
エクスポートします。

> [!CAUTION]
> `make clean SCENARIO="$SCENARIO"` は、シナリオディレクトリ内の `.terraform/` キャッシュのみを
> 削除します。追跡対象の依存関係ロックファイル、ローカルステート、変数ファイルは保持されます。

## Terraform CLI を使用したシナリオの実行

シナリオディレクトリから Terraform コマンドを直接実行します。

```bash
cd infra/scenarios/<scenario>

terraform init -lockfile=readonly
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

プロバイダー制約を変更するときは、対応する追跡対象のロックファイルも同じ変更内で更新します。
Google プロバイダー 8 には破壊的変更があるため、最新の 7 系（`7.46.1`）に留めています。
メジャーバージョンを採用する前に、OIDC シナリオへの影響を個別に確認してください。
