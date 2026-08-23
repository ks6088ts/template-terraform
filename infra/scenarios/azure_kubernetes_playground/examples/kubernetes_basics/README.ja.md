# Kubernetes 基礎演習

この演習では、OpenTelemetry の例で直接扱っていない Kubernetes API を、小さな自己完結型ワークロードで確認します。

## 対象リソース

| 分野 | リソース |
| --- | --- |
| 構成と ID | ConfigMap、生成される Secret、ServiceAccount、Role、RoleBinding |
| ステートレスワークロード | Deployment、ClusterIP Service、probe、requests/limits |
| 可用性とスケーリング | PodDisruptionBudget、HorizontalPodAutoscaler |
| ステートフルワークロード | StatefulSet、headless Service、PersistentVolumeClaim |
| ノード・バッチ処理 | DaemonSet、Job、停止状態の CronJob |
| ネットワーク分離 | default-deny と許可ルールの NetworkPolicy |

生成される Secret は演習専用のダミーデータです。実際の資格情報を Kustomization ファイルに記載しないでください。Azure に接続するアプリケーションでは、Microsoft Entra Workload ID とマネージドなシークレットストアを使用します。

## 実行

シナリオディレクトリから実行します。

```bash
./scripts/30_run_kubernetes_basics.sh
```

リソースを確認します。

```bash
kubectl get all,pvc,configmap,secret,networkpolicy,poddisruptionbudget -n workshop-basics
kubectl describe hpa web -n workshop-basics
kubectl logs job/one-time-task -n workshop-basics
kubectl exec -n workshop-basics statefulset/data-writer -- tail /data/events.log
kubectl auth can-i get configmaps \
  --as system:serviceaccount:workshop-basics:workshop-reader \
  -n workshop-basics
```

パブリック IP を作成せずに Web サービスへアクセスします。

```bash
kubectl port-forward -n workshop-basics service/web 8080:80
```

<http://localhost:8080> を開き、確認後に `Ctrl-C` でポートフォワードを停止します。

## クリーンアップ

```bash
kubectl delete -k examples/kubernetes_basics
```
