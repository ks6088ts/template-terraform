---
name: update-terraform-readme
description: Terraform リポジトリの README と共通ドキュメントを更新する。シナリオ一覧への追記、Mermaid 構成図、利用・検証手順、変数・出力の説明、英日 README の同期を頼まれたら使う。Use for README updates, scenario documentation, architecture diagrams, procedures, and catalog entries; Terraform リソースの新規実装には create-terraform-scenario を使う。
---

# Terraform ドキュメントの更新

ユーザーの自然文から対象シナリオと変更内容を読み取る。`/update-terraform-readme` で直接呼ばれた場合も、決まった入力書式を要求しない。事実を確認できない箇所や更新先が曖昧な場合だけ質問する。

## 更新先を選ぶ

1. 対象の Terraform、既存の README、必要に応じてスクリプト・[共通ガイド](../../../docs/tips/index.md)を読む。説明は実装済みの内容に基づける。
2. シナリオ一覧はルートの [README.md](../../../README.md) と [README.ja.md](../../../README.ja.md) の該当プロバイダー（Azure、AWS、Google Cloud、GitHub、その他）の表を更新する。既存行があれば修正し、重複させない。列は Scenario / Overview（日本語版はシナリオ / 概要）、リンク先は各言語のシナリオ README とする。
3. 構成図、シナリオ固有の変数・出力・操作・検証は `infra/scenarios/<name>/README.md` と `README.ja.md` に書く。認証、標準的な Terraform ワークフロー、バックエンドなど複数シナリオに共通する説明は `docs/tips/` の英日ガイドにまとめ、必要ならその索引も更新する。
4. 更新先が明示されていれば尊重する。指定された場所と既存の情報設計が衝突し、どちらに置くかで結果が変わる場合は確認する。

## 簡潔かつ正確に書く

- 明示的に片言語のみ指定された場合を除き、英日ペアを同期する。既存の見出し、frontmatter、行順、説明の粒度に合わせ、一般論の重複を避ける。
- 図は Mermaid を使用し、リソースと接続関係を実際の設定から確認する。利用例は実行ディレクトリと `SCENARIO`・必要な引数が分かるシェルコマンドにし、共通手順は英日それぞれの `docs/tips/` にリンクする。
- 値や機能を推測して書かない。資格情報や実際の秘密値は例示しない。専門外の読者にも分かる短い概要にする。

変更後は英日差分、リンク先、記載した変数・出力・コマンドを確認する。結果は更新箇所と未確認事項だけを簡潔に報告する。ドキュメント作業のためにクラウドへのデプロイはしない。
