# TechInsight Kubernetes Manifests

Deploy app services and use Kong as Ingress. Config and secrets come from **Vault + Consul** (no ConfigMap). Infrastructure (MongoDB, Redis, Kafka, MinIO, etc.) can run outside the cluster or be deployed separately; update Consul KV or Vault secrets if external.

**Kiến trúc (North–South, East–West, phân tầng infra):** [ARCHITECTURE-V2.md](ARCHITECTURE-V2.md)

## Prerequisites

- Kubernetes cluster (e.g. kubeadm single-node, xem [KUBEADM-BOOTSTRAP.md](KUBEADM-BOOTSTRAP.md))
- Kong Ingress Controller installed, e.g.:

  ```bash
  helm repo add kong https://charts.konghq.com
  helm repo update
  helm install kong kong/kong -n kong --create-namespace
  ```

  Confirm the ingress class name (often `kong`):

  ```bash
  kubectl get ingressclass
  ```

## Vault + Consul (secrets and variables, Service Account auth)

Secrets are provided by **Vault**; variables/config can live in **Consul** KV. **be-api, be-auth, be-worker không start được nếu Consul hoặc Vault chưa cài/cấu hình** → xem [TROUBLESHOOTING.md](TROUBLESHOOTING.md) và chạy `scripts/install-consul.sh` nếu cần.

See **[VAULT_CONSUL.md](VAULT_CONSUL.md)** and:

- [k8s/vault/README.md](vault/README.md) – Vault Kubernetes auth, policies, roles
- [k8s/consul/README.md](consul/README.md) – Consul KV layout and optional ACL

Apply **serviceaccounts.yaml** before or with the rest so Vault roles can bind to them.

## Apply order

```bash
kubectl apply -f namespace.yaml
kubectl apply -f serviceaccounts.yaml
kubectl apply -f consul-templates-configmap.yaml
kubectl apply -f be-auth-service-deployment.yaml
kubectl apply -f be-api-service-deployment.yaml
kubectl apply -f be-worker-service-deployment.yaml
kubectl apply -f fe-service-deployment.yaml
kubectl apply -f fe-admin-service-deployment.yaml
kubectl apply -f ingress.yaml
kubectl apply -f pdb.yaml
```

Verify connections after deploy:

```bash
./verify-connections.sh
```

Or run:

```bash
./apply.sh
```

## Argo CD (visualize pods / GitOps)

Để xem pods và resources trong UI: cài Argo CD, tạo Application trỏ repo TechInsight. Chi tiết: [argocd/README.md](argocd/README.md).

```bash
./argocd/install-argocd.sh
# Sửa repoURL trong argocd/techinsight-application.yaml rồi: kubectl apply -f argocd/techinsight-application.yaml
# Truy cập UI: kubectl port-forward svc/argocd-server -n argocd 8080:443 -> https://localhost:8080
```

## Internal gRPC

`be-api-service` calls `be-auth-service` at `be-auth-service:50051` via ClusterIP. No Ingress is used for gRPC.

## External infra

If MongoDB, Redis, Kafka, MinIO, or Elasticsearch run outside the cluster, update Consul KV (e.g. `techinsight/config/be-api-service`) or Vault secrets with the external hostnames, then restart the deployments.
