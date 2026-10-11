---
title: プロバイダー認証
description: Azure、AWS、Google Cloud、Databricks、Cloudflare、GitHub の各シナリオで Terraform プロバイダーを認証する
ms.date: 2026-10-11
ms.topic: how-to
---

## Azure

Azure シナリオを実行する前に、Azure CLI で認証し、対象のサブスクリプションを選択して、
アクティブなアカウントを確認します。

```bash
az login
az account set --subscription "<subscription-name-or-id>"
az account show --output table
```

リポジトリの Makefile は `ARM_SUBSCRIPTION_ID` を取得してエクスポートします。Terraform を
直接実行する場合は、手動でエクスポートします。

```bash
export ARM_SUBSCRIPTION_ID=$(az account show --query id --output tsv)
```

Azure Blob Storage バックエンドには、データプレーンに対する個別の認可要件があります。
リモートステートを有効にする場合は、[Azure Blob Storage バックエンドガイド](azure-blob-backend.ja.md)に
従ってください。

## AWS

標準の AWS 資格情報チェーンを使用します。構成済みのプロファイルを使用すると、Terraform
ファイルに資格情報を記述せずに済みます。

```bash
aws configure --profile <profile>
export AWS_PROFILE=<profile>
aws sts get-caller-identity
```

AWS IAM Identity Center のユーザーは、代わりに既存の SSO プロファイルで認証できます。

```bash
aws sso login --profile <profile>
export AWS_PROFILE=<profile>
```

AWS SDK は、`AWS_ACCESS_KEY_ID`、`AWS_SECRET_ACCESS_KEY`、省略可能な
`AWS_SESSION_TOKEN`、およびリージョン変数も認識します。長期使用するアクセスキーよりも
一時的な資格情報を優先してください。

## Google Cloud

ローカルで Terraform を実行する場合は、Application Default Credentials を使用します。

```bash
gcloud auth application-default login
gcloud auth application-default set-quota-project <project-id>
```

プロバイダーの資格情報では Terraform の入力変数が選択されないため、シナリオによっては
`TF_VAR_project_id` も必要です。シナリオの README に記載された方法で値を設定してください。

資格情報ファイルが必要な場合、Google SDK は `GOOGLE_APPLICATION_CREDENTIALS` も認識します。
資格情報ファイルをコミットしないでください。

## Databricks

Azure Databricks Workspace のシナリオでは、Workspace のテナントに属する主体で
[Azure CLI にログイン](#azure)します。シナリオは Databricks provider に
Workspace レベルの HTTPS `host` と `auth_type = "azure-cli"` を設定します。
PAT、クライアントシークレット、Databricks CLI は不要です。

実行主体には Databricks Workspace の利用権限と、参照するオブジェクトの閲覧権限が必要です。
Azure リソース管理の RBAC だけでは、Databricks のデータプレーンにアクセスできません。
Workspace レベルの操作では `DATABRICKS_ACCOUNT_ID` を設定しないでください。
Account Console の設定と Workspace の設定は異なります。
トークンや資格情報を Terraform ファイルに記述しないでください。

認証だけでは Terraform の入力 Workspace は選択されません。
[Databricks playground シナリオ](../../infra/scenarios/databricks_playground/README.ja.md)に従って、
既存 Workspace のスキームなし `workspace_url` を `TF_VAR_workspace_url` で渡します。
Provider が `https://` を付加するため、この入力に `databricks_host` 出力を渡さないでください。
`databricks_*` の Makefile ターゲットは `ARM_SUBSCRIPTION_ID` を取得しません。
Databricks provider だけで行うこの参照には不要ですが、別途設定した
Azure Blob backend には独自の認証が必要です。

CI の mock テストとローカル API fixture テストに Azure の認証情報や実 Databricks Workspace は不要です。
実 Workspace の認証と疎通は、手動の plan でのみ検証します。

## Cloudflare

Cloudflare プロバイダーは `CLOUDFLARE_API_TOKEN` を読み取ります。
対象 Account とシナリオに必要な権限に限定した
[API Token](https://developers.cloudflare.com/fundamentals/api/get-started/create-token/)を作成してください。
Account の参照シナリオで必要な権限は `Account Settings: Read` のみです。
旧来の Global API Key ではなく API Token を使用してください。

ポータルでユーザー API Token を作成する手順:

1. [My Profile → API Tokens](https://dash.cloudflare.com/profile/api-tokens/) を開きます。
2. **Create Token** を選択し、カスタムトークンを作成します。
3. **Permissions** を **Account → Account Settings → Read** に設定します。
4. **Account Resources** で **Include → Specific account** を選択し、
   Terraform に ID を渡す対象 Account を指定します。
   **TTL** で適切な有効期限を設定し、期限前にトークンを更新する運用を決めます。
5. **Continue to summary** で対象範囲を確認し、**Create Token** を選択します。
6. トークンを安全なシークレットストアに保存します。秘密値は一度しか表示されません。
   チャットへの貼り付け、コミット、変数ファイルへの記入は行わないでください。

Bash では、トークンの値を画面やシェル履歴に残さずに入力できます。

```bash
read -r -s -p "Cloudflare API token: " CLOUDFLARE_API_TOKEN
printf '\n'
export CLOUDFLARE_API_TOKEN
```

この `read` のオプションは Bash 用です。ターミナルが zsh（macOS の既定）の場合は、
先に `bash` を起動し、このコマンドと Terraform の両方をその Bash セッションで実行してください。
トークンを扱う際はシェルのトレース（`set -x`）を有効にしないでください。
旧来の `CLOUDFLARE_API_KEY`、`CLOUDFLARE_EMAIL`、
`CLOUDFLARE_API_USER_SERVICE_KEY` が設定されている場合は解除します。
プロバイダーは API Token 認証との併用を許可しません。

Terraform は同じターミナルで実行してください。そこでエクスポートしても、
起動済みの VS Code タスクや別のターミナルセッションには反映されません。
認証では Terraform 入力の Account ID は選択されません。シナリオの README に従って、
変数ファイルの `account_id` または `TF_VAR_account_id` を設定してください。
GitHub Actions では、`dev` の Environment Secrets に `CLOUDFLARE_API_TOKEN` と
`CLOUDFLARE_ACCOUNT_ID` を保存します。後者はワークフローで `TF_VAR_account_id` に渡されます。
独立した mock テスト job には、これらの Secrets や Environment の承認は不要です。
トークンを Terraform 変数、プロバイダー設定、ファイルに書き込まないでください。

## GitHub

GitHub プロバイダーは `GITHUB_TOKEN` を読み取ります。ローカルの GitHub CLI セッションを使用すると、
Terraform ファイルにトークンを書き込まずに指定できます。

```bash
gh auth login
gh auth status
export GITHUB_TOKEN=$(gh auth token)
```

シナリオで管理するリソースに合ったリポジトリおよび Organization の権限を持つトークンを使用してください。

## 自動化

CI/CD では、ワークロード ID フェデレーションなどの有効期間が短い資格情報メカニズムを
優先してください。資格情報は自動化プラットフォームのシークレットストアに保存し、サポートされる
環境変数を介して渡します。アクセスキー、クライアントシークレット、トークン、資格情報ファイルを、
Terraform 構成、バックエンド構成、変数ファイル、保存済みのプランに含めないでください。
