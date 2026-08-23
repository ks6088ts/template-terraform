---
title: ドキュメント
description: 共通の Terraform ガイダンスとデプロイ可能なシナリオのエントリーポイント
ms.date: 2026-08-23
ms.topic: overview
---

## はじめに

このリポジトリでは、`infra/scenarios/` 配下の Terraform ルートモジュールを
デプロイおよび破棄します。[リポジトリの README](../README.ja.md) からシナリオを選択し、
プロバイダーの資格情報を構成して、GNU Make または Terraform CLI で実行します。

すべてのシナリオに共通する手順については、[Terraform のヒント](tips/index.ja.md) から
始めてください。各シナリオの README には、リソース固有の入力、コマンドのオーバーライド、
検証、デプロイ後の操作が記載されています。

## 共通ガイド

* [Terraform ワークフロー](tips/terraform-workflow.ja.md)
* [プロバイダー認証](tips/provider-authentication.ja.md)
* [Azure Blob Storage バックエンド](tips/azure-blob-backend.ja.md)
* [Infracost によるクラウドコスト見積もり](tips/infracost.ja.md)

## シナリオカタログ

Azure、AWS、Google Cloud、GitHub、およびプロバイダーに依存しないすべてのシナリオについては、
[リポジトリの README](../README.ja.md) を参照してください。

## 参考資料

* [Terraform ドキュメント](https://developer.hashicorp.com/terraform/docs)
* [Terraform CLI のインストール](https://developer.hashicorp.com/terraform/install)
