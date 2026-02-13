# Chia secret (Vault) và config (Consul) — Production flow

- **Config tĩnh** (DB host, port, …) → **Consul KV**
- **Secret** (username, password, JWT, …) → **Vault KV**
- **Khi Pod start**: Init container (consul-template) lấy config từ Consul + secret từ Vault → merge thành **1 file** `merged.env` → App container source file đó (Pattern A).

## Flow khi Pod init

1. **Vault Agent** (agent-init-first): dùng ServiceAccount JWT → login Vault → ghi token ra `/vault/secrets/token` (annotation `agent-inject-token: "true"`). Volume secrets được injector mount vào mọi container.
2. **Init container consul-template**: đọc `VAULT_TOKEN` từ file, `VAULT_ADDR`; chạy template (ConfigMap) vừa gọi `key "techinsight/..."` (Consul) vừa gọi `secret "secret/data/techinsight/..."` (Vault) → ghi `/app/configs/config.yml` (static) và `/app/configs/merged.env` (config tĩnh + secret).
3. **App container**: `source /app/configs/merged.env`; đọc `config.yml` nếu cần.

## Consul KV

| Key | Ý nghĩa |
|-----|--------|
| `techinsight/config/be-api-service` | Config YAML không nhạy cảm (file) |
| `techinsight/config/be-auth-service` | Idem |
| `techinsight/config/be-worker-service` | Idem |
| `techinsight/config/db/host` | DB host (config tĩnh) — dùng trong template merge |
| `techinsight/config/db/port` | DB port (config tĩnh) |

## Vault KV

| Path | Nội dung |
|------|----------|
| `secret/techinsight/db` | `host`, `username`, `password` |
| `secret/techinsight/be-api-service` | JWT_SECRET, REDIS_PASSWORD, MONGODB_URI, MINIO_*, ... |
| `secret/techinsight/be-auth-service` | JWT_SECRET, REDIS_PASSWORD, MONGODB_URI, CONSUL_* |
| `secret/techinsight/be-worker-service` | Giống be-api-service |

## Template merge (ConfigMap consul-templates)

Template `*-env.tpl` trong ConfigMap: vừa `key "techinsight/config/db/host"`, `key "techinsight/config/db/port"` (Consul) vừa `secret "secret/data/techinsight/db"`, `secret "secret/data/techinsight/be-*-service"` (Vault) → output `/app/configs/merged.env` (export DB_HOST=..., DB_USER=..., JWT_SECRET=..., ...).

## Deployment

- **Vault**: chỉ dùng `agent-inject-token: "true"` (không inject từng secret). Token để init container consul-template gọi Vault.
- **Init container**: mount volume vault-secrets (token), set VAULT_ADDR, đọc VAULT_TOKEN từ `/vault/secrets/.vault-token`, chạy consul-template với 2 template: config.yml (Consul) và merged.env (Consul + Vault).
- **App**: `source /app/configs/merged.env` (một bộ config tỏng).

## Sau khi thay đổi

1. **Vault**: `./populate-secrets.sh` (VAULT_ADDR, VAULT_TOKEN).
2. **Consul**: `./load-config-into-consul.sh` (gồm `techinsight/config/db/host`, `techinsight/config/db/port`).
3. Restart deployment: `kubectl -n techinsight rollout restart deployment be-api-service be-auth-service be-worker-service`.
