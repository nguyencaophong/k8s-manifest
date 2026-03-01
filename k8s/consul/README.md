# Consul for TechInsight (templates + config)

Consul KV lưu **consul-template** cho mỗi service. Mỗi template chứa:
- Non-secret config (app, server, kafka, logging, tracing...)
- Vault secret references (`{{ .Data.data.xxx }}`) cho database, security, cache, storage...

Khi pod khởi động, init container `consul-template`:
1. Lấy template từ Consul KV HTTP API (`wget`)
2. Render template (thay `{{ .Data.data.xxx }}` bằng giá trị thực từ Vault)
3. Ghi ra `/app/configs/config.yml` → app đọc file này

## 1. Install Consul (Helm)

```bash
helm repo add hashicorp https://helm.releases.hashicorp.com
helm repo update
helm install consul hashicorp/consul -n consul --create-namespace -f values.yaml
```

## 2. Consul KV layout

| Key | Mô tả |
|-----|-------|
| `techinsight/templates/core-service` | Template cho core-service (API chính) |
| `techinsight/templates/auth-service` | Template cho auth-service |
| `techinsight/templates/be-worker-service` | Template cho be-worker-service |

## 3. Load templates vào Consul KV

```bash
cd k8s/consul
./load-config-into-consul.sh
```

Hoặc thủ công:

```bash
kubectl cp tpl-core-service.yml consul/consul-server-0:/tmp/tpl.yml -c consul
kubectl exec -n consul consul-server-0 -c consul -- consul kv put techinsight/templates/core-service @/tmp/tpl.yml
```

## 4. Cập nhật config

1. Sửa file `tpl-core-service.yml`, `tpl-auth-service.yml` hoặc `tpl-be-worker-service.yml`
2. Load lại vào Consul KV (bước 3)
3. Rollout restart deployment: `kubectl rollout restart deployment core-service auth-service be-worker-service -n techinsight`

## 5. Verify

```bash
# Xem template trong Consul KV
kubectl exec -n consul consul-server-0 -c consul -- consul kv get techinsight/templates/core-service

# Xem config đã render trong pod
kubectl exec -n techinsight <pod-name> -c api -- cat /app/configs/config.yml
```
