# Vault + Consul with Service Account auth

TechInsight dùng **Vault** cho toàn bộ secret và **Consul** cho toàn bộ config/environment. Pod xác thực Vault bằng **Kubernetes Service Account** (JWT).

**Hướng dẫn setup từng bước:** [VAULT_CONSUL_SETUP.md](VAULT_CONSUL_SETUP.md)

## Flow

1. Each app has a dedicated **ServiceAccount** (e.g. `be-api-service` in namespace `techinsight`).
2. **Vault** Kubernetes auth method: pod sends its SA token to Vault; Vault validates with the K8s API and maps the SA to a **Vault role** (e.g. `be-api-service`) that has a **policy** allowing read of `secret/techinsight/be-api-service`.
3. **Vault Agent Injector** (sidecar): before the app starts, it uses the pod’s SA token to log in to Vault, reads the secret, and writes it to a file (or env) in the container. No static Secret in the cluster.
4. **Consul**: store non-secret config (URIs, feature flags) in Consul KV. Optionally store a Consul ACL token in Vault and inject it so the app can read from Consul.

## Apply order

1. Create namespace and **ServiceAccounts** (so they exist before Vault roles are used):

   ```bash
   kubectl apply -f namespace.yaml
   kubectl apply -f serviceaccounts.yaml
   ```

2. Install and configure **Vault** (see [vault/README.md](vault/README.md)):
   - Enable KV v2 and Kubernetes auth.
   - Run `vault/setup-policies-roles.sh` to create policies and K8s auth roles.
   - Store secrets at `secret/techinsight/be-api-service`, etc.

3. Install **Vault Agent Injector** (usually with Vault Helm: `injector.enabled=true`). Ensure the injector can validate JWTs for namespace `techinsight`.

4. Install **Consul** and optionally populate KV (see [consul/README.md](consul/README.md)).

5. Deploy app manifests (ConfigMap, Deployments, Services, Ingress). Deployments already have:
   - `serviceAccountName: <app>`
   - `vault.hashicorp.com/agent-inject*` annotations so the injector adds the sidecar and mounts secrets.

## What each deployment gets

| Deployment         | ServiceAccount   | Vault path                              | Consul (optional)      |
|-------------------|------------------|------------------------------------------|-------------------------|
| be-api-service    | be-api-service   | secret/techinsight/be-api-service        | CONSUL_HTTP_TOKEN from Vault, read techinsight/config/* |
| be-worker-service | be-worker-service| secret/techinsight/be-worker-service     | same                    |
| be-auth-service   | be-auth-service  | secret/techinsight/be-auth-service        | same                    |
| fe-service        | fe-service       | (no Vault by default)                    | -                       |
| fe-admin-service  | fe-admin-service | (no Vault by default)                    | -                       |

Backend services source `/vault/secrets/config` at startup (exported env) so they get `JWT_SECRET`, `MONGODB_URI`, etc. from Vault. Frontends can keep using ConfigMap/env only unless you add Vault/Consul for them.

## Troubleshooting

- **Injector not injecting**: Check injector logs and that the namespace is not excluded (`vault.hashicorp.com/agent-inject: "true"` and role name matches a Vault role).
- **Permission denied** from Vault: Ensure the Vault role’s `bound_service_account_names` and `bound_service_account_namespaces` match the pod’s SA, and the policy allows `read` on the secret path.
- **App doesn’t see env**: The container must source `/vault/secrets/config` before running the main process (see `command` in the deployments). If the image has no shell, use an entrypoint wrapper that sources the file then execs the binary.
