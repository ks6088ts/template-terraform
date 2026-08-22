---
title: template-terraform
description: 再利用可能な Terraform モジュールとデプロイ可能なクラウドインフラストラクチャシナリオ
---

[![テスト](https://github.com/ks6088ts/template-terraform/actions/workflows/test.yml/badge.svg?branch=main)](https://github.com/ks6088ts/template-terraform/actions/workflows/test.yml?query=branch%3Amain)

Terraform 用の GitHub テンプレートリポジトリです。

## ドキュメント

共通の Terraform ワークフロー、プロバイダー認証、リモートステートのガイダンスについては、
[ドキュメント](./docs/index.ja.md)を参照してください。

## シナリオ

### Azure

| シナリオ | 概要 |
| --- | --- |
| [azure_terraform_backend](./infra/scenarios/azure_terraform_backend/README.ja.md) | Terraform バックエンド用の Azure Storage Account を作成します。 |
| [azure_github_oidc](./infra/scenarios/azure_github_oidc/README.ja.md) | GitHub Actions から Azure に OIDC で接続するためのサービスプリンシパルを作成し、必要な権限を割り当てます。 |
| [azure_apim_playground](./infra/scenarios/azure_apim_playground/README.ja.md) | 実行可能な API Management core と、opt-in の backend resilience、AI gateway policy、Content Safety、可観測性をデプロイします。 |
| [azure_container_apps](./infra/scenarios/azure_container_apps/README.ja.md) | Docker Hub イメージを使用し、外部アクセス可能な Azure Container App をデプロイします。 |
| [azure_datastore](./infra/scenarios/azure_datastore/README.ja.md) | Cosmos DB、Storage、Key Vault、PostgreSQL、Monitor などの Azure データストアを、テスト用のパブリックアクセスを許可してデプロイします。 |
| [azure_functions_flex_consumption](./infra/scenarios/azure_functions_flex_consumption/README.ja.md) | Azure Functions の Flex Consumption プランを使用し、最小構成のサーバーレス実行環境をデプロイします。 |
| [azure_microsoft_foundry](./infra/scenarios/azure_microsoft_foundry/README.ja.md) | Microsoft Foundry ワークロードの実行に必要な Azure インフラストラクチャをデプロイします。 |
| [azure_spoke_network](./infra/scenarios/azure_spoke_network/README.ja.md) | Azure ハブアンドスポークアーキテクチャ用のスポークネットワークとして、VNet、Bastion、Storage のプライベートエンドポイント、VM をデプロイします。 |
| [azure_inclusive_ai_labs](./infra/scenarios/azure_inclusive_ai_labs/README.ja.md) | Azure Container Apps 上に azure_inclusive_ai_labs API と VOICEVOX を使用した音声合成サービスをデプロイします。 |
| [azure_kubernetes_playground](./infra/scenarios/azure_kubernetes_playground/README.ja.md) | 閉域構成を使用せず、コストを抑えた Azure Container Registry と Azure Kubernetes Service の環境をデプロイします。 |
| [azure_postgresql](./infra/scenarios/azure_postgresql/README.ja.md) | Azure Database for PostgreSQL Flexible Server をデプロイします。管理者パスワードは自動生成され、接続情報を出力から取得できます。 |

### AWS

| シナリオ | 概要 |
| --- | --- |
| [aws_github_oidc](./infra/scenarios/aws_github_oidc/README.ja.md) | GitHub Actions から AWS に OIDC で接続するための IAM ロールを作成し、必要な権限を割り当てます。 |

### Google Cloud

| シナリオ | 概要 |
| --- | --- |
| [google_github_oidc](./infra/scenarios/google_github_oidc/README.ja.md) | GitHub Actions から Google Cloud に OIDC で接続するための Workload Identity Federation を作成し、必要な権限を割り当てます。 |

### GitHub

| シナリオ | 概要 |
| --- | --- |
| [github_secrets](./infra/scenarios/github_secrets/README.ja.md) | GitHub Actions ワークフローで使用する GitHub リポジトリの環境シークレットを作成、管理します。 |

### その他

| シナリオ | 概要 |
| --- | --- |
| [hello_world](./infra/scenarios/hello_world/README.ja.md) | random プロバイダーでランダム文字列を生成し、Terraform の基本動作を示します。 |
