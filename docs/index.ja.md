---
title: ドキュメント
description: 共通の Terraform ガイダンスとデプロイ可能なシナリオのエントリーポイント
ms.date: 2026-10-04
ms.topic: overview
---

## はじめに

このリポジトリでは、`infra/scenarios/` 配下の Terraform ルートモジュールを
デプロイおよび破棄します。[リポジトリの README](../README.ja.md) からシナリオを選択し、
プロバイダーの資格情報を構成して、GNU Make または Terraform CLI で実行します。

まず [共通の前提条件](tips/terraform-workflow.ja.md#前提条件)でツール、権限、
ネットワーク要件を確認してください。共通の操作手順は
[Terraform のヒント](tips/index.ja.md)にまとめています。
各シナリオの README には、リソース固有の入力、コマンドのオーバーライド、
検証、デプロイ後の操作が記載されています。

## 共通ガイド

* [前提条件](tips/terraform-workflow.ja.md#前提条件)
* [Terraform ワークフロー](tips/terraform-workflow.ja.md)
* [プロバイダー認証](tips/provider-authentication.ja.md)
* [Azure Blob Storage バックエンド](tips/azure-blob-backend.ja.md)
* [Infracost によるクラウドコスト見積もり](tips/infracost.ja.md)

## シナリオカタログ

Azure、AWS、Google Cloud、GitHub、およびプロバイダーに依存しないすべてのシナリオについては、
[リポジトリの README](../README.ja.md) を参照してください。

## GitHub Copilot Agent Skills

VS Code のエージェントモードでは、自然文で依頼するかスキル名を指定します。

* [`/create-terraform-scenario`](../.github/skills/create-terraform-scenario/SKILL.md) — シナリオとその説明を作成します。
* [`/update-terraform-readme`](../.github/skills/update-terraform-readme/SKILL.md) — シナリオ一覧、構成図、手順を更新します。

## 参考資料

* [Terraform ドキュメント](https://developer.hashicorp.com/terraform/docs)
* [Terraform CLI のインストール](https://developer.hashicorp.com/terraform/install)
