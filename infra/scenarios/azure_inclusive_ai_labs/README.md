# azure_inclusive_ai_labs

このTerraformシナリオは、Azure Container Apps上にazure_inclusive_ai_labsアプリケーションをデプロイします。音声認識（STT）、AI対話（GenAI）、音声合成（TTS）を組み合わせた**インクルーシブなAI対話システム**を構築できます。

## 🎯 このシナリオでできること

- **音声からテキストへの変換**（Speech-to-Text）: ユーザーの音声をテキストに変換
- **AIとの対話**（Generative AI）: テキストを元にAIが応答を生成
- **テキストから音声への変換**（Text-to-Speech）: AIの応答を音声で読み上げ

これにより、視覚障害者や手を使えない方でも、音声でAIと対話できるアクセシブルなシステムを実現します。

## 📦 デプロイされるコンポーネント

| コンポーネント | 役割 | 外部アクセス |
|---------------|------|-------------|
| **azure_inclusive_ai_labs** | メインAPIサーバー（対話処理の司令塔） | ✅ 可能 |
| **voicevox** | 日本語音声合成エンジン | ❌ 内部のみ |
| **ollama** | ローカルLLM実行エンジン | ❌ 内部のみ（設定で変更可） |

## 🏗️ システムアーキテクチャ

### 全体構成図

```mermaid
flowchart TB
    subgraph Internet["🌐 インターネット"]
        User["👤 ユーザー"]
    end

    subgraph Azure["☁️ Azure クラウド"]
        subgraph RG["📁 リソースグループ (rg-azureinclusiveailabs)"]
            subgraph CAE["🔷 Container Apps 環境"]
                direction TB

                subgraph External["外部公開サービス"]
                    IAL["🎯 azure_inclusive_ai_labs<br/>（メインAPI）<br/>ポート: 8000"]
                end

                subgraph Internal["内部サービス"]
                    VV["🎤 voicevox<br/>（音声合成）<br/>ポート: 50021"]
                    OL["🧠 ollama<br/>（ローカルLLM）<br/>ポート: 11434"]
                end
            end

            LAW["📊 Log Analytics<br/>（ログ監視）"]
            Storage["💾 Azure Storage<br/>（モデル永続化）"]
        end

        AOAI["🤖 Azure OpenAI<br/>（クラウドLLM）"]
    end

    User -->|"HTTPS リクエスト"| IAL
    IAL -->|"内部HTTP"| VV
    IAL -->|"内部HTTP"| OL
    IAL -.->|"HTTPS（オプション）"| AOAI
    CAE --> LAW
    OL --> Storage

    style IAL fill:#4CAF50,color:#fff
    style VV fill:#2196F3,color:#fff
    style OL fill:#9C27B0,color:#fff
    style AOAI fill:#FF9800,color:#fff
```

### Azure リソース構成図

```mermaid
flowchart LR
    subgraph Resources["Azure リソース一覧"]
        direction TB
        RG["📁 azurerm_resource_group"]
        LAW["📊 azurerm_log_analytics_workspace"]
        CAE["🔷 azurerm_container_app_environment"]
        SA["💾 azurerm_storage_account"]
        FS["📂 azurerm_storage_share"]
        ES["🔗 azurerm_container_app_environment_storage"]
        CA1["📦 azurerm_container_app<br/>(azure_inclusive_ai_labs)"]
        CA2["📦 azurerm_container_app<br/>(voicevox)"]
        CA3["📦 azurerm_container_app<br/>(ollama)"]
    end

    RG --> LAW
    RG --> SA
    LAW --> CAE
    SA --> FS
    FS --> ES
    ES --> CAE
    CAE --> CA1
    CAE --> CA2
    CAE --> CA3
```

## 🔄 処理フロー

### 音声対話の流れ

```mermaid
sequenceDiagram
    autonumber
    participant User as 👤 ユーザー
    participant API as 🎯 azure_inclusive_ai_labs
    participant STT as 🎧 STT モジュール<br/>(Whisper)
    participant LLM as 🧠 GenAI モジュール<br/>(Ollama / Azure OpenAI)
    participant TTS as 🎤 TTS モジュール<br/>(voicevox / piper)

    User->>+API: 音声データを送信
    Note over API: 音声ファイルを受信

    API->>+STT: 音声をテキストに変換依頼
    STT-->>-API: テキスト「こんにちは」
    Note over API: 音声認識完了

    API->>+LLM: テキストでAIに質問
    Note over LLM: プロバイダに応じて<br/>Ollama or Azure OpenAI を使用
    LLM-->>-API: 応答「こんにちは！何かお手伝いできますか？」
    Note over API: AI応答生成完了

    API->>+TTS: 応答テキストを音声に変換依頼
    Note over TTS: 言語に応じて<br/>voicevox(日本語) or piper(多言語) を使用
    TTS-->>-API: 音声データ(WAV)
    Note over API: 音声合成完了

    API-->>-User: 音声データを返却
    Note over User: 音声で応答を聞く
```

### APIリクエスト処理の詳細

```mermaid
flowchart TD
    Start["🚀 リクエスト受信"] --> Parse["📝 リクエスト解析"]
    Parse --> Decision{"🔀 処理タイプ判定"}

    Decision -->|"音声入力"| STT["🎧 STTモジュール<br/>(Whisper)"]
    Decision -->|"テキスト入力"| GenAI

    STT --> GenAI["🧠 GenAIモジュール"]

    GenAI --> ProviderCheck{"🔄 GenAI<br/>プロバイダー選択"}
    ProviderCheck -->|"ollama"| Ollama["🏠 Ollama<br/>(ローカルLLM)"]
    ProviderCheck -->|"azure-openai"| AOAI["☁️ Azure OpenAI<br/>(クラウドLLM)"]

    Ollama --> Response["📄 テキスト応答"]
    AOAI --> Response

    Response --> TTSCheck{"🔊 音声出力?"}
    TTSCheck -->|"Yes"| TTSModule["🎤 TTSモジュール"]
    TTSCheck -->|"No"| TextOut["📤 テキスト返却"]

    TTSModule --> TTSProvider{"🔄 TTS<br/>プロバイダー選択"}
    TTSProvider -->|"日本語"| VV["🎤 voicevox<br/>(日本語特化)"]
    TTSProvider -->|"多言語"| Piper["🎤 piper<br/>(多言語対応)"]

    VV --> AudioOut["🔈 音声返却"]
    Piper --> AudioOut

    TextOut --> End["✅ 完了"]
    AudioOut --> End

    style Ollama fill:#9C27B0,color:#fff
    style AOAI fill:#FF9800,color:#fff
    style VV fill:#2196F3,color:#fff
    style Piper fill:#00BCD4,color:#fff
```

## � マルチプロバイダ対応

azure_inclusive_ai_labs は **STT（音声認識）**、**GenAI（生成AI）**、**TTS（音声合成）** の各モジュールで**複数のプロバイダを切り替え可能**な設計になっています。用途や要件に応じて最適なプロバイダを選択できます。

### プロバイダ対応一覧

```mermaid
flowchart TB
    subgraph STT["🎧 STT（音声認識）モジュール"]
        direction LR
        STT_IF["統一インターフェース"]
        STT_W["✅ Whisper<br/>（現在サポート）"]
        STT_Future["🔮 将来拡張可能"]
        STT_IF --> STT_W
        STT_IF -.-> STT_Future
    end

    subgraph GenAI["🧠 GenAI（生成AI）モジュール"]
        direction LR
        GENAI_IF["統一インターフェース"]
        GENAI_OL["✅ Ollama<br/>（ローカルLLM）"]
        GENAI_AO["✅ Azure OpenAI<br/>（クラウドLLM）"]
        GENAI_IF --> GENAI_OL
        GENAI_IF --> GENAI_AO
    end

    subgraph TTS["🎤 TTS（音声合成）モジュール"]
        direction LR
        TTS_IF["統一インターフェース"]
        TTS_VV["✅ voicevox<br/>（日本語向け）"]
        TTS_PP["✅ piper<br/>（多言語向け）"]
        TTS_IF --> TTS_VV
        TTS_IF --> TTS_PP
    end

    style STT_W fill:#4CAF50,color:#fff
    style GENAI_OL fill:#9C27B0,color:#fff
    style GENAI_AO fill:#FF9800,color:#fff
    style TTS_VV fill:#2196F3,color:#fff
    style TTS_PP fill:#00BCD4,color:#fff
```

### 各モジュールの詳細

| モジュール | プロバイダ | 対応言語・用途 | 特徴 |
|-----------|-----------|--------------|------|
| **STT** | Whisper | 多言語（100言語以上） | OpenAI開発の高精度音声認識モデル |
| **GenAI** | Ollama | 多言語 | ローカル実行、データが外部に出ない、無料 |
| **GenAI** | Azure OpenAI | 多言語 | GPT-4o等の高性能モデル、エンタープライズ対応 |
| **TTS** | voicevox | 🇯🇵 **日本語特化** | 高品質な日本語音声、キャラクター音声対応 |
| **TTS** | piper | 🌍 **多言語対応** | 英語・ドイツ語・フランス語等、軽量で高速 |

### プロバイダ選択のフロー

```mermaid
flowchart TD
    subgraph Selection["プロバイダ選択の判断基準"]
        Start["📝 要件の確認"] --> Lang{"🌐 対象言語は？"}

        Lang -->|"日本語メイン"| TTS_JP["TTS: voicevox を推奨"]
        Lang -->|"英語・多言語"| TTS_ML["TTS: piper を推奨"]

        Start --> Privacy{"🔒 データの機密性は？"}
        Privacy -->|"高い（外部送信NG）"| LLM_Local["GenAI: Ollama を推奨"]
        Privacy -->|"通常"| LLM_Cloud["GenAI: Azure OpenAI を推奨"]

        Start --> Performance{"⚡ 性能要件は？"}
        Performance -->|"最高品質"| LLM_Cloud
        Performance -->|"コスト重視"| LLM_Local
    end

    style TTS_JP fill:#2196F3,color:#fff
    style TTS_ML fill:#00BCD4,color:#fff
    style LLM_Local fill:#9C27B0,color:#fff
    style LLM_Cloud fill:#FF9800,color:#fff
```

### 環境変数によるプロバイダ切り替え

| 環境変数 | 設定値 | 説明 |
|---------|-------|------|
| `GENAI_DEFAULT_PROVIDER` | `ollama` / `azure-openai` | 使用するLLMプロバイダ |
| `TTS_DEFAULT_PROVIDER` | `voicevox` / `piper` | 使用する音声合成プロバイダ |
| `STT_DEFAULT_PROVIDER` | `whisper` | 使用する音声認識プロバイダ |

## 🔗 コンテナ間通信

```mermaid
flowchart TB
    subgraph CAE["Container Apps Environment"]
        direction TB

        subgraph DNS["内部DNS"]
            D1["app-inclusive-ai-labs"]
            D2["app-voicevox"]
            D3["app-ollama"]
        end

        IAL["azure_inclusive_ai_labs"]
        VV["voicevox"]
        OL["ollama"]

        D1 -.-> IAL
        D2 -.-> VV
        D3 -.-> OL
    end

    IAL -->|"http://app-voicevox:80"| VV
    IAL -->|"http://app-ollama:80"| OL
```

同じContainer Apps環境内では、アプリ名で直接通信できます。

- `http://app-voicevox` → voicevoxコンテナ
- `http://app-ollama` → ollamaコンテナ

## 📊 監視とログ

```mermaid
flowchart LR
    subgraph Apps["アプリケーション"]
        CA1["azure_inclusive_ai_labs"]
        CA2["voicevox"]
        CA3["ollama"]
    end

    subgraph Monitoring["監視基盤"]
        LAW["📊 Log Analytics<br/>Workspace"]
    end

    CA1 -->|"ログ送信"| LAW
    CA2 -->|"ログ送信"| LAW
    CA3 -->|"ログ送信"| LAW

    LAW --> Query["🔍 ログ検索"]
    LAW --> Alert["⚠️ アラート設定"]
    LAW --> Dashboard["📈 ダッシュボード"]
```

## ⚙️ 前提条件

- Azure サブスクリプション
- Terraform >= 1.6.0
- Azure CLI（ログイン済み）
- Azure OpenAI リソース（デプロイ済みモデル付き）※ Azure OpenAI を利用する場合

## 🚀 クイックスタート

1. **Terraformの初期化**

   ```bash
   terraform init
   ```

2. **`terraform.tfvars` ファイルを作成**

   ```hcl
   name     = "azureinclusiveailabs"
   location = "japaneast"

   # Azure OpenAI 設定（Azure OpenAI を使用する場合は必須）
   genai_azure_openai_endpoint = "https://your-openai-resource.openai.azure.com/"
   genai_azure_openai_api_key  = "your-api-key-here"
   genai_azure_openai_deployment_name = "gpt-4o"

   # ローカルLLM（Ollama）をデフォルトで使用する場合
   genai_default_provider = "ollama"
   ollama_model = "gemma3:270m"  # デフォルトモデル
   ```

3. **デプロイ**

   ```bash
   terraform plan
   terraform apply
   ```

4. **アプリケーションへのアクセス**

   デプロイ完了後、URLが出力されます：

   ```bash
   terraform output azure_inclusive_ai_labs_url
   ```

## 📋 変数一覧

### 必須変数

| 名前 | 説明 |
|------|------|
| `genai_azure_openai_api_key` | Azure OpenAI APIキー（機密情報） |

### 基本設定

| 名前 | デフォルト値 | 説明 |
|------|-------------|------|
| `name` | `azureinclusiveailabs` | リソースの基本名 |
| `location` | `japaneast` | Azureリージョン |

### azure_inclusive_ai_labs コンテナ設定

| 名前 | デフォルト値 | 説明 |
|------|-------------|------|
| `azure_inclusive_ai_labs_image` | `ks6088ts/inclusive-ai-labs:latest` | Dockerイメージ |
| `azure_inclusive_ai_labs_cpu` | `2.0` | CPUコア数 |
| `azure_inclusive_ai_labs_memory` | `4Gi` | メモリ |
| `azure_inclusive_ai_labs_min_replicas` | `1` | 最小レプリカ数 |
| `azure_inclusive_ai_labs_max_replicas` | `3` | 最大レプリカ数 |

### voicevox コンテナ設定

| 名前 | デフォルト値 | 説明 |
|------|-------------|------|
| `voicevox_image` | `voicevox/voicevox_engine:cpu-ubuntu20.04-latest` | Dockerイメージ |
| `voicevox_cpu` | `2.0` | CPUコア数 |
| `voicevox_memory` | `4Gi` | メモリ |
| `voicevox_min_replicas` | `1` | 最小レプリカ数 |
| `voicevox_max_replicas` | `3` | 最大レプリカ数 |

### Ollama コンテナ設定

| 名前 | デフォルト値 | 説明 |
|------|-------------|------|
| `ollama_image` | `ollama/ollama:latest` | Dockerイメージ |
| `ollama_model` | `gemma3:270m` | 起動時にダウンロードするモデル |
| `ollama_cpu` | `2.0` | CPUコア数 |
| `ollama_memory` | `4Gi` | メモリ |
| `ollama_storage_quota_gb` | `10` | ストレージ容量(GB) |
| `ollama_external_enabled` | `false` | 外部公開するか |

### AI/音声処理設定

| 名前 | デフォルト値 | 説明 |
|------|-------------|------|
| `genai_default_provider` | `ollama` | LLMプロバイダー（`ollama` または `azure-openai`） |
| `genai_system_prompt` | `You are a helpful assistant.` | GenAIプロバイダーのシステムプロンプト |
| `genai_azure_openai_endpoint` | `` | Azure OpenAI エンドポイントURL |
| `genai_azure_openai_deployment_name` | `gpt-4o` | デプロイメント名 |
| `genai_azure_openai_api_version` | `2024-02-15-preview` | Azure OpenAI APIバージョン |
| `stt_default_provider` | `whisper` | 音声認識プロバイダー |
| `stt_whisper_model_size` | `small` | Whisperモデルサイズ |
| `stt_whisper_device` | `cpu` | Whisperデバイス（`cpu` / `cuda`） |
| `stt_whisper_compute_type` | `int8` | Whisper計算タイプ |
| `stt_hf_home` | `` | Hugging Faceモデルキャッシュディレクトリ |
| `tts_default_provider` | `voicevox` | 音声合成プロバイダー |
| `tts_default_voice` | `en_US-lessac-medium` | デフォルト音声（piper用） |
| `tts_voicevox_default_speaker` | `1` | voicevoxスピーカーID |
| `tts_voicevox_timeout` | `30.0` | voicevoxリクエストタイムアウト（秒） |
| `tts_piper_voices_dir` | `` | Piper音声モデルディレクトリ |

詳細は [variables.tf](variables.tf) を参照してください。

## 📤 出力値

| 名前 | 説明 |
|------|------|
| `azure_inclusive_ai_labs_url` | azure_inclusive_ai_labs APIの公開URL |
| `azure_inclusive_ai_labs_fqdn` | Container AppのFQDN |
| `voicevox_internal_fqdn` | voicevoxの内部FQDN |
| `ollama_internal_fqdn` | ollamaの内部FQDN |
| `ollama_url` | ollamaのURL（外部/内部） |

## 🔗 内部通信の仕組み

`azure_inclusive_ai_labs` コンテナは、Container Apps環境内の内部DNSを使用して他のコンテナと通信します：

```mermaid
flowchart LR
    subgraph CAE["Container Apps 環境"]
        IAL["azure_inclusive_ai_labs"]
        VV["voicevox"]
        OL["ollama"]

        IAL -->|"TTS_VOICEVOX_BASE_URL<br/>http://app-voicevox"| VV
        IAL -->|"GENAI_OLLAMA_BASE_URL<br/>http://app-ollama"| OL
    end
```

環境変数で自動設定されます：

- `TTS_VOICEVOX_BASE_URL=http://app-voicevox`
- `GENAI_OLLAMA_BASE_URL=http://app-ollama`

## 🗑️ リソースの削除

```bash
terraform destroy
```

## 💡 ユースケース

### ユースケース 1: アクセシブルなAIアシスタント

```mermaid
flowchart TB
    subgraph User["利用者"]
        Blind["👤 視覚障害者"]
        Elder["👴 高齢者"]
        Hands["🙋 両手がふさがっている人"]
    end

    subgraph System["システム"]
        Voice["🎙️ 音声入力"]
        AI["🧠 AI処理"]
        Speech["🔊 音声出力"]
    end

    User -->|"話しかける"| Voice
    Voice --> AI
    AI --> Speech
    Speech -->|"音声で応答"| User
```

### ユースケース 2: 多言語対話システム

```mermaid
flowchart LR
    subgraph Input["音声入力"]
        JP["🇯🇵 日本語音声"]
        EN["🇺🇸 英語音声"]
        DE["🇩🇪 ドイツ語音声"]
    end

    subgraph STT_Module["STTモジュール"]
        STT["🎧 Whisper<br/>(多言語対応)"]
    end

    subgraph GenAI_Module["GenAIモジュール"]
        LLM["🧠 Ollama / Azure OpenAI"]
    end

    subgraph TTS_Module["TTSモジュール"]
        VV["🎤 voicevox<br/>(日本語)"]
        PP["🎤 piper<br/>(英語・ドイツ語等)"]
    end

    subgraph Output["音声出力"]
        OutJP["🔊 日本語音声"]
        OutEN["🔊 英語音声"]
    end

    JP --> STT
    EN --> STT
    DE --> STT
    STT --> LLM
    LLM --> VV
    LLM --> PP
    VV --> OutJP
    PP --> OutEN

    style VV fill:#2196F3,color:#fff
    style PP fill:#00BCD4,color:#fff
```

## ⚠️ 注意事項

- **voicevox** は言語モデルをロードするため、起動に1〜2分かかることがあります
- **ollama** は最初の起動時にモデルをダウンロードするため、追加の時間がかかります
- コールドスタートを避けるため、最小レプリカ数は1に設定されています
- 開発環境でコストを最適化する場合は、`min_replicas` を 0 に設定できます
- Ollamaのモデルデータは Azure Storage に永続化されるため、コンテナ再起動後も保持されます

## 📚 関連リソース

- [Azure Container Apps ドキュメント](https://learn.microsoft.com/ja-jp/azure/container-apps/)
- [voicevox エンジン](https://github.com/VOICEVOX/voicevox_engine)
- [Ollama](https://ollama.ai/)
- [OpenAI Whisper](https://github.com/openai/whisper)
- [Azure OpenAI Service](https://learn.microsoft.com/ja-jp/azure/ai-services/openai/)

## 🔧 トラブルシューティング

### コンテナが起動しない場合

```mermaid
flowchart TD
    Start["コンテナ起動失敗"] --> Check1{"ログを確認"}
    Check1 -->|"メモリ不足"| Fix1["memory を増やす"]
    Check1 -->|"イメージ取得失敗"| Fix2["イメージ名を確認"]
    Check1 -->|"ヘルスチェック失敗"| Fix3["起動時間を待つ"]

    Fix1 --> Retry["terraform apply で再デプロイ"]
    Fix2 --> Retry
    Fix3 --> Wait["2-3分待ってから再確認"]
```

### ログの確認方法

```bash
# Azure CLIでログを確認
az containerapp logs show \
  --name app-inclusive-ai-labs \
  --resource-group rg-azureinclusiveailabs \
  --type console
```
