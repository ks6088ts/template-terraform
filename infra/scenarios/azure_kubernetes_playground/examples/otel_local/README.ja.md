---
description: Docker Compose で OpenTelemetry オブザーバビリティスタックをローカル実行する
---

# OpenTelemetry オブザーバビリティスタック

Docker Compose で構成された OpenTelemetry ベースのオブザーバビリティスタックです。トレース・メトリクス・ログの収集・可視化を行います。

## アーキテクチャ

```mermaid
flowchart LR
    subgraph Generators["テレメトリ生成"]
        GenTraces["telemetrygen<br/>(トレース)"]
        GenMetrics["telemetrygen<br/>(メトリクス)"]
    end

    subgraph Collector["OpenTelemetry Collector<br/>:4317 gRPC / :4318 HTTP"]
        direction TB
        OTLP_IN["OTLP レシーバー"]
        Batch["バッチプロセッサー"]
        OTLP_IN --> Batch
    end

    subgraph Backends["バックエンド"]
        Jaeger["Jaeger<br/>UI :16686"]
        Prometheus["Prometheus<br/>UI :9090"]
    end

    GenTraces -- "OTLP gRPC" --> OTLP_IN
    GenMetrics -- "OTLP gRPC" --> OTLP_IN

    Batch -- "トレース<br/>(OTLP エクスポート)" --> Jaeger
    Batch -- "メトリクス<br/>(リモートライトのプッシュ)" --> Prometheus
    Prometheus -. "メトリクス<br/>(スクレイプ :8889)" .-> Batch
    Batch -- "トレース / メトリクス / ログ" --> Debug["デバッグ<br/>(標準出力)"]
```

### コンポーネント一覧

| コンポーネント              | イメージ                                        | 役割                                     | 公開ポート                  |
|-----------------------------|-------------------------------------------------|------------------------------------------|-----------------------------|
| **Jaeger**                  | `jaegertracing/all-in-one`                      | 分散トレーシングバックエンドと UI        | `16686` (UI)                |
| **Prometheus**              | `prom/prometheus`                               | メトリクス収集・クエリエンジン           | `9090` (UI)                 |
| **OpenTelemetry Collector** | `otel/opentelemetry-collector-contrib`          | テレメトリの受信・処理・エクスポート     | `4317` (gRPC), `4318` (HTTP) |
| **telemetrygen (トレース)** | `opentelemetry-collector-contrib/telemetrygen`  | サンプルトレースを生成                   | -                           |
| **telemetrygen (メトリクス)** | `opentelemetry-collector-contrib/telemetrygen` | サンプルメトリクスを生成                 | -                           |

## データフロー

### トレース

```text
アプリケーション / telemetrygen → OTLP (gRPC :4317) → OTel Collector → Jaeger
```

### メトリクス

```text
アプリケーション / telemetrygen → OTLP (gRPC :4317) → OTel Collector → Prometheus (リモートライト + スクレイプ)
```

### ログ

```text
アプリケーション → OTLP (gRPC :4317) → OTel Collector → デバッグ (標準出力)
```

## 利用方法

### 起動

```shell
cd src
docker compose up -d
```

### UI へのアクセス

| サービス      | URL                      | 用途                         |
|---------------|--------------------------|------------------------------|
| Jaeger UI     | <http://localhost:16686> | トレースの検索・可視化       |
| Prometheus UI | <http://localhost:9090>  | メトリクスのクエリ・グラフ表示 |

### 動作確認

起動後、`telemetrygen` が自動的にサンプルデータ（トレース・メトリクス）を 5 分間、1 req/s のレートで OpenTelemetry Collector へ送信します。

1. **トレースの確認**: [Jaeger UI](http://localhost:16686) を開き、Service ドロップダウンから `telemetrygen` を選択して Search をクリックします。
2. **メトリクスの確認**: [Prometheus UI](http://localhost:9090) を開き、クエリ入力欄に `gen` と入力して候補からメトリクスを選択します。

### 自分のアプリケーションからテレメトリを送信する

OpenTelemetry SDK を使用して、以下のエンドポイントへテレメトリを送信できます。

| プロトコル | エンドポイント   |
|------------|------------------|
| OTLP gRPC  | `localhost:4317` |
| OTLP HTTP  | `localhost:4318` |

環境変数の設定例:

```shell
export OTEL_EXPORTER_OTLP_ENDPOINT="http://localhost:4317"
export OTEL_EXPORTER_OTLP_PROTOCOL="grpc"
```

### 停止

```shell
docker compose down
```

## 設定ファイル

| ファイル                     | 説明                                                                     |
|------------------------------|--------------------------------------------------------------------------|
| `compose.yaml`               | Docker Compose によるサービス定義                                       |
| `otel-collector-config.yaml` | OpenTelemetry Collector の受信・処理・エクスポート設定                  |
| `prometheus.yaml`            | Prometheus のスクレイプ設定（OTel Collector の `:8889` を対象）          |

## OpenTelemetry Collector パイプライン構成

```text
receivers:
  otlp (gRPC + HTTP)
      │
processors:
  batch
      │
exporters:
  ├── traces  → otlp/jaeger, debug
  ├── metrics → prometheus(:8889), prometheusremotewrite, debug
  └── logs    → debug
```
