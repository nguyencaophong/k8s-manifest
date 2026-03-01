# Chia secret (Vault) và config (Consul) — Production flow (Cách B)

- **Config không nhạy cảm** → **Consul KV** (`techinsight/config/<service-name>`).
- **Secret** (JWT, Redis, MinIO, mongodb.uri, …) → **Vault KV v2** (`secret/data/techinsight/<service-name>`).
- **Khi Pod start**: Init container (consul-template) lấy config từ Consul + **một** lần đọc secret từ Vault → merge thành **một file** `/app/configs/config.yml`. App đọc **chỉ** file này (không dùng env cho secret).

## Flow khi Pod init

1. **Vault Agent** (agent-init-first): dùng ServiceAccount JWT → login Vault → ghi token ra `/vault/secrets/token` hoặc `/vault/secrets/.vault-token` (annotation `agent-inject-token: "true"`).
2. **Init container consul-template**: đọc `VAULT_TOKEN` từ file, `VAULT_ADDR`, `CONSUL_HTTP_ADDR`; chạy **một** template: `key "techinsight/config/<service>"` (Consul) + **một** `with secret "secret/data/techinsight/<service>"` (Vault) → ghi `/app/configs/config.yml`. Thiếu key dùng `default "MISSING"`; Vault lỗi dùng `else "VAULT_UNAVAILABLE"` (fail fast).
3. **App container**: đọc **chỉ** `/app/configs/config.yml` (env `CONFIG_FILEPATH=/app/configs/config.yml`). Không source file env.

## Consul KV (Cách B – chỉ non-secret)

| Key | Ý nghĩa |
|-----|--------|
| `techinsight/config/be-api-service` | YAML chỉ không nhạy cảm: app, server, cache, kafka, logging, auth, elasticsearch, external/storage (không có security, không redis password, không minio keys, không database.mongodb) |
| `techinsight/config/be-auth-service` | Idem |
| `techinsight/config/be-worker-service` | Idem |

Load: `consul kv put techinsight/config/be-api-service @k8s/consul/config-be-api-service.yml` (và tương tự cho từng service).

## Vault KV (một path per service, snake_case keys)

| Path | Keys (ví dụ) |
|------|--------------|
| `secret/techinsight/be-api-service` | `mongodb_uri`, `jwt_secret`, `redis_password`, `minio_access_key`, `minio_secret_key`, `elasticsearch_user`, `elasticsearch_password`, `consul_http_addr`, `consul_http_token` |
| `secret/techinsight/be-auth-service` | `mongodb_uri`, `jwt_secret`, `redis_password`, `consul_http_*` |
| `secret/techinsight/be-worker-service` | Giống be-api-service |

Ghi: `./k8s/vault/populate-secrets.sh` (dùng snake_case keys).

## Template (ConfigMap consul-templates)

Mỗi service **một** file template `*-service.tpl`: Part 1 = `{{ key "techinsight/config/be-api-service" }}`, Part 2 = `{{- with secret "secret/data/techinsight/be-api-service" }}` rồi xuất database.mongodb, security, cache.redis.password, storage.minio với `| default "MISSING"` và `{{- else }}` với `VAULT_UNAVAILABLE`. **Một** `with secret` duy nhất; không có merged.env.

## Deployment

- **Vault**: chỉ `agent-inject-token: "true"`. Token để init container gọi Vault.
- **Init container**: consul-template với **một** template → `/app/configs/config.yml`.
- **App**: `CONFIG_FILEPATH=/app/configs/config.yml`, command `exec ./main` (hoặc `./worker`); không source merged.env.

## Sau khi thay đổi

1. **Vault**: `./k8s/vault/populate-secrets.sh` (VAULT_ADDR, VAULT_TOKEN).
2. **Consul**: `./k8s/consul/load-config-into-consul.sh` (đưa config YAML non-secret vào từng key).
3. Restart deployment: `kubectl -n techinsight rollout restart deployment be-api-service be-auth-service be-worker-service`.
