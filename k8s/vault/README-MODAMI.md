# Vault — Modami (namespace `modami`)

Các path KV và policy dùng cho `be-modami-auth-service`, `be-modami-user-service`, `be-modami-core-service`.

## Paths

| Path | Mục đích |
|------|----------|
| `secret/modami/be-modami-auth-service` | Auth service (consul-template) |
| `secret/modami/be-modami-user-service` | User service |
| `secret/modami/be-modami-core-service` | Core service |

**Lưu ý:** Đây khác prefix `secret/techinsight/*` dùng cho stack TechInsight. Nếu trên Vault chỉ thấy một path (ví dụ chỉ `be-modami-core-service`), cần chạy `./populate-modami-secrets.sh` (sau khi set `VAULT_ADDR` và `VAULT_TOKEN`) để ghi đủ cả ba.

## Scripts

- `policies/modami-be-modami-*.hcl` — policy read cho từng app.
- `setup-modami-policies-roles.sh` — `vault policy write` + `auth/kubernetes/role` cho SA trong namespace `modami`.
- `populate-modami-secrets.sh` — ghi KV cho auth, user, core (cùng pattern snake_case như template Consul).
