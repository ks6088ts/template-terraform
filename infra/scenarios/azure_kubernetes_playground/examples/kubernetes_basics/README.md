# Kubernetes Basics Exercise

This exercise applies a small, self-contained workload that demonstrates the Kubernetes APIs not covered directly by the OpenTelemetry example.

## Covered resources

| Area | Resources |
| --- | --- |
| Configuration and identity | ConfigMap, generated Secret, ServiceAccount, Role, RoleBinding |
| Stateless workload | Deployment, ClusterIP Service, probes, requests and limits |
| Availability and scaling | PodDisruptionBudget, HorizontalPodAutoscaler |
| Stateful workload | StatefulSet, headless Service, PersistentVolumeClaim |
| Node and batch workloads | DaemonSet, Job, suspended CronJob |
| Network isolation | Default-deny and allow-list NetworkPolicy |

The generated Secret contains training-only data. Never put real credentials in a Kustomization file. Use Microsoft Entra Workload ID and a managed secret store for Azure-connected applications.

## Run

From the scenario directory:

```bash
./scripts/30_run_kubernetes_basics.sh
```

Inspect the resources:

```bash
kubectl get all,pvc,configmap,secret,networkpolicy,poddisruptionbudget -n workshop-basics
kubectl describe hpa web -n workshop-basics
kubectl logs job/one-time-task -n workshop-basics
kubectl exec -n workshop-basics statefulset/data-writer -- tail /data/events.log
kubectl auth can-i get configmaps \
  --as system:serviceaccount:workshop-basics:workshop-reader \
  -n workshop-basics
```

Access the web service without creating a public IP:

```bash
kubectl port-forward -n workshop-basics service/web 8080:80
```

Open <http://localhost:8080>, then stop port forwarding with `Ctrl-C`.

## Clean up

```bash
kubectl delete -k examples/kubernetes_basics
```
