---
title: プロバイダー認証
description: Azure、AWS、Google Cloud、GitHub の各シナリオで Terraform プロバイダーを認証する
ms.date: 2026-08-13
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
