---
agent: 'agent'
description: 'README.md にシナリオやアーキテクチャ図、手順を追記する'
---

# README 更新

シナリオ追加や変更に伴う README の更新を行います。

## 入力情報

更新タイプ: ${input:updateType:更新タイプを選択（scenario-table / architecture / procedure）}
シナリオ名: ${input:scenarioName:対象シナリオ名（例: azure_container_apps）}
追加情報: ${input:additionalInfo:概要や操作内容など追加の情報}

## 実行内容

更新タイプに応じて以下を実行してください：

### scenario-table の場合
`README.md` のシナリオテーブルに ${input:scenarioName} を追記してください。
概要: ${input:additionalInfo}

### architecture の場合
${input:scenarioName} シナリオのアーキテクチャ図を `README.md` に追記してください。
図表はすべて Mermaid フォーマットを利用してください。

### procedure の場合
${input:additionalInfo} を実行する手順を `README.md` に追記してください。
shell コマンドで簡単に実行できる方法を記載してください。

## README フォーマット規則

- 図表は Mermaid 形式で記載する
- シナリオはプロバイダ（Azure, AWS, Google, GitHub, その他）ごとにテーブルで整理
- シナリオテーブルには以下の列を含める:
  - Scenario: シナリオへのリンク
  - Overview: 簡潔な説明

## 注意事項

- 技術者以外でもわかる平易な説明を心がける
- 冗長な一般的説明は避ける
- 具体的な操作手順はコマンド例を添える

## 参照ファイル

- `README.md` - 更新対象のファイル
- `infra/scenarios/` - 既存シナリオの実装例
