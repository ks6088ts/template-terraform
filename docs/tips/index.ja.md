---
title: Terraform のヒント
description: すべてのシナリオに共通する Terraform ワークフロー、プロバイダー認証、リモートステートのガイダンス
ms.date: 2026-08-13
ms.topic: overview
---

## ガイド

シナリオ間で共通するセットアップと運用には、次のガイドを使用してください。

* [Terraform ワークフロー](terraform-workflow.ja.md)
* [プロバイダー認証](provider-authentication.ja.md)
* [Azure Blob Storage バックエンド](azure-blob-backend.ja.md)

各シナリオの README には、そのシナリオに固有の入力、コマンドのオーバーライド、検証、
デプロイ後の操作のみが記載されています。

## ステートの保存先

シナリオに `backend` ブロックが含まれていない場合、Terraform はローカルバックエンドを
使用します。ローカルバックエンドは、個別の評価やこのリポジトリの自動テストに適しています。

ステートを共有する場合や作業ディレクトリの外部に永続化する場合は、
[Azure Blob Storage バックエンド](azure-blob-backend.ja.md)を使用してください。このリポジトリでは、
AWS S3 の例を [AWS GitHub OIDC シナリオ](../../infra/scenarios/aws_github_oidc/README.ja.md)に、
Google Cloud Storage の例を
[Google GitHub OIDC シナリオ](../../infra/scenarios/google_github_oidc/README.ja.md)に記載しています。
