# Setup Vault + Consul (secrets + environment) cho TechInsight

Toàn bộ **secret** nằm trong **Vault**, toàn bộ **config/environment** nằm trong **Consul** KV. Pod dùng **Service Account** để auth Vault; init container lấy config từ Consul (dùng token lấy từ Vault).

## Thứ tự setup

### 1. Cài Vault (Helm)

```bash
helm repo add hashicorp https://helm.releases.hashicorp.com
helm repo update
helm install vault hashicorp/vault -n vault --create-namespace \
  --set "injector.enabled=true" \
  --set "server.ha.enabled=false" \
  --set "server.standalone.enabled=true"
# Unseal Vault (vault operator unseal ...) và init nếu mới.
```

### 2. Cấu hình Vault: KV + Kubernetes auth

```bash
export VAULT_ADDR='http://vault.vault.svc.cluster.local:8200'  # hoặc http://localhost:8200 nếu port-forward
vault login  # root token hoặc token có quyền

vault secrets enable -path=secret kv-v2
vault auth enable kubernetes

# K8s auth: dùng token của SA trong namespace vault để review JWT
vault write auth/kubernetes/config \
  kubernetes_host="https://kubernetes.default.svc:443" \
  token_reviewer_jwt="$(kubectl -n vault get secret $(kubectl -n vault get sa vault -o jsonpath='{.secrets[0].name}') -o jsonpath='{.data.token}' | base64 -d)" \
  kubernetes_ca_cert=@<(kubectl get secret -n vault $(kubectl -n vault get sa vault -o jsonpath='{.secrets[0].name}') -o jsonpath='{.data.ca\.crt}' | base64 -d)
```

(Nếu Vault chạy trong cluster, có thể dùng file token và ca.crt từ `/var/run/secrets/kubernetes.io/serviceaccount/`.)

### 3. Tạo policy và role Vault (Service Account auth)

```bash
cd k8s/vault
./setup-policies-roles.sh
```

### 4. Ghi toàn bộ secret vào Vault

Từ repo (có thể dùng .env):

```bash
cd k8s/vault
export VAULT_ADDR=... VAULT_TOKEN=...
# Tùy chọn: CONSUL_HTTP_TOKEN=...  (token Consul ACL nếu bật ACL)
./populate-secrets.sh
```

Secret được ghi tại:
- `secret/techinsight/be-api-service` (JWT_SECRET, REDIS_PASSWORD, MONGODB_URI, MINIO_*, CONSUL_HTTP_*)
- `secret/techinsight/be-worker-service`
- `secret/techinsight/be-auth-service`

### 5. Cài Consul (Helm)

```bash
helm install consul hashicorp/consul -n consul --create-namespace \
  -f consul/values.yaml
```

`consul/values.yaml` tối thiểu:

```yaml
global:
  name: consul
server:
  replicas: 1
  storage: 10Gi
ui:
  enabled: true
```

### 6. Ghi toàn bộ config (environment) vào Consul KV

```bash
cd k8s/consul
export CONSUL_HTTP_ADDR=http://localhost:8500   # hoặc port-forward consul-ui
./load-config-into-consul.sh
```

Script đọc từ `config-be-api-service.yml`, `config-be-worker-service.yml`, `config-be-auth-service.yml` và ghi vào key:
- `techinsight/config/be-api-service`
- `techinsight/config/be-worker-service`
- `techinsight/config/be-auth-service`

### 7. Apply Kubernetes

```bash
cd k8s
./apply.sh
```

Pod sẽ:
1. Chạy Vault Agent init → đọc secret từ Vault (bằng SA), ghi vào `/vault/secrets/config` (export env).
2. Chạy init container consul-template → source `/vault/secrets/config` (lấy CONSUL_HTTP_TOKEN), gọi Consul KV, ghi `/app/configs/config.yml`.
3. Chạy container chính → source `/vault/secrets/config`, đọc config từ `/app/configs/config.yml`.

## Sửa secret hoặc config

- **Secret:** `vault kv put secret/techinsight/be-api-service KEY=value ...` rồi restart deployment.
- **Config:** `consul kv put techinsight/config/be-api-service @config-be-api-service.yml` (hoặc sửa từng key) rồi restart deployment (init container chạy lại và tạo lại config.yml).

## Consul ACL (tùy chọn)

Nếu bật ACL Consul: tạo token có quyền đọc prefix `techinsight/`, ghi token đó vào Vault:

```bash
vault kv patch secret/techinsight/be-api-service CONSUL_HTTP_TOKEN="<consul-token>"
```

Rồi chạy lại `populate-secrets.sh` với `CONSUL_HTTP_TOKEN` set, hoặc patch từng path như trên.
