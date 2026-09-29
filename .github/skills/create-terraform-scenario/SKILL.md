---
name: create-terraform-scenario
description: このリポジトリの infra/scenarios に Terraform シナリオを新規作成する。Azure・AWS・Google Cloud・GitHub などのインフラ構成例を追加、既存例から派生、モジュール・CI・README まで整備する依頼で使う。Use for "create/add a Terraform scenario", "シナリオを作成", "既存シナリオをベースに追加"; README のみの変更には update-terraform-readme を使う。
---

# Terraform シナリオの作成

`/create-terraform-scenario` の後にはシナリオ名、対象クラウドとリソース、任意の参考シナリオ・要件を自然文で指定できる。定型入力を要求せず、実装を左右する情報が足りない場合だけ質問する。

## 現状を確認する

1. 名前が既存の `azure_*`、`aws_*`、`google_*`、`github_*` またはプロバイダー非依存の命名に合うか確認する。同名のディレクトリがある場合、明示的な変更依頼なしに上書きしない。
2. 作業中の差分を確認し、依頼外の編集を保持する。[既存シナリオ](../../../infra/scenarios/)、[モジュール](../../../infra/modules/)、[CI](../../../.github/workflows/test.yml)、[Makefile](../../../Makefile)から近い例を調べる。指定されたベースを優先しつつ、対象外のリソースや固有設定を機械的にコピーしない。プロバイダーや権限、公開範囲などが未確定で安全な実装を決められないときは先に確認する。

## 必要なものだけ実装する

1. `infra/scenarios/<name>/` に `main.tf`（複雑なら役割別の `.tf`）、`variables.tf`、`outputs.tf`、`versions.tf` を作る。必要なプロバイダー設定は `providers.tf` に分け、近い例のバージョン制約と認証方式を基準にする。必要な機能がなければ Terraform の最低バージョンを上げない。AzureRM を使う場合は必要なリソースプロバイダーの登録設定も確認する。変更可能な値は型・説明・妥当な既定値を持つ変数にし、秘密値とその出力は `sensitive` にする。
2. まず既存モジュールを再利用する。新規モジュールは他でも使える境界があるときだけ `infra/modules/<provider>/` に作り、`variables.tf`・`outputs.tf`・`versions.tf` を揃える。ローカルの `backend.tf`、`.terraform/`、state、`*.tfvars`、資格情報を作成・複製しない。共有 state が必要な場合は [共通ガイド](../../../docs/tips/index.md)を参照する。
3. 振る舞いを確認できる `.tftest.hcl` を適宜追加し、認証なしで実行するテストは mock と `command = plan` を基本とする。[CI の provider 別固定 matrix](../../../.github/workflows/test.yml)に対象を追加するのは、その job の認証とテストが新シナリオに適合する場合だけにする。適合しない場合は必要な設定や未追加の理由を報告する。
4. [README 更新スキル](../update-terraform-readme/SKILL.md)を開き、その文書配置・英日同期ルールに従ってシナリオの `README.md`・`README.ja.md` とルートのシナリオ一覧を更新する。概要、固有の入力・出力、利用例、必要な構成図・参照先を、実装された内容に合わせて簡潔に書く。依頼に `cdk.tf` や `compose.yml` などの参考資料があれば照合し、採用した情報と相違点を明示する。

## 安全に確認する

対象ファイルだけ `terraform fmt` で整え、対象シナリオと追加モジュールで書式チェックを行う。実行可能ならシナリオ内で `terraform init -backend=false`、`terraform validate`、認証不要の mock / plan テストを実行する。`terraform test` は apply を含み得るため、テスト内容を見てから実行する。認証が必要な plan は条件と実行許可を確認する。`make clean`、`make _ci-test-base`、`apply`、`destroy` は既定では実行しない（`_ci-test-base` はローカル state などを消し得る）。

最後に作成・更新したファイル、検証結果、未実行の検証と理由を簡潔に報告する。未検証を成功と表現しない。
