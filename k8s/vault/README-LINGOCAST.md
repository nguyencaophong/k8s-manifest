# Vault — Lingocast (namespace `lingocast`)

KV paths and policies for `be-lingocast-core-service`, `be-lingocast-job-scheduler`, `voice-analyze-and-summarizer-asr`.

## Paths

| Path | Purpose |
|------|---------|
| `secret/lingocast/be-lingocast-core-service` | Core API service (consul-template) |
| `secret/lingocast/be-lingocast-job-scheduler` | Asynq job scheduler/worker |
| `secret/lingocast/voice-analyze-and-summarizer-asr` | Python ASR/summarizer worker |

This is a separate prefix from `secret/modami/*` and `secret/techinsight/*`, but shares the same
Vault, Consul, MongoDB, Redis, Kafka and MinIO instances (all running in namespace `techinsight`).

**Keycloak realm:** `be-lingocast-core-service` authenticates against the shared Keycloak instance
in namespace `modami`. Create a `lingocast` realm there before deploying (Keycloak admin console) —
`jwks_url` in `tpl-be-lingocast-core-service.yml` already points at
`http://keycloak.modami.svc.cluster.local:8180/realms/lingocast/protocol/openid-connect/certs`.

**Redis:** `be-lingocast-core-service` and `be-lingocast-job-scheduler` intentionally share Redis
DB index `8` — the job scheduler dequeues the asynq jobs the core service enqueues, so they must
point at the same DB.

## Scripts

- `policies/lingocast-*.hcl` — read-only policy per app.
- `setup-lingocast-policies-roles.sh` — `vault policy write` + `auth/kubernetes/role` for SAs in namespace `lingocast`.
- `populate-lingocast-secrets.sh` — writes KV for core-service, job-scheduler, and the ASR service.

## Order of operations

1. `./setup-lingocast-policies-roles.sh` (after exporting `VAULT_ADDR`/`VAULT_TOKEN`)
2. `./populate-lingocast-secrets.sh`
3. `../consul/load-config-into-consul.sh` to push the three `tpl-*.yml` templates into Consul KV
4. Apply `k8s/base/lingocast` and `k8s/apps/lingocast/*` (or let ArgoCD's `lingocast-base` /
   `lingocast-be-*` / `lingocast-voice-*` Applications sync them)
