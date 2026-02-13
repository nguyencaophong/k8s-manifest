# Vault setup for TechInsight (Kubernetes auth / Service Account)

Pods authenticate to Vault using their Kubernetes ServiceAccount token (JWT). Run these steps once Vault is installed (e.g. via Helm).

## 1. Install Vault (Helm example)

```bash
helm repo add hashicorp https://helm.releases.hashicorp.com
helm repo update
helm install vault hashicorp/vault -n vault --create-namespace \
  --set "server.ha.enabled=true" \
  --set "injector.enabled=true"
# Unseal and init Vault, then enable KV and Kubernetes auth (see below).
```

Or use Vault outside the cluster and point `VAULT_ADDR` to it.

## 2. Enable KV secret engine and Kubernetes auth

```bash
export VAULT_ADDR='http://vault.vault:8200'   # or your Vault address

vault login  # use root or admin token

vault secrets enable -path=secret kv-v2

vault auth enable kubernetes

# Configure Kubernetes auth to use the cluster where techinsight runs
vault write auth/kubernetes/config \
  kubernetes_host="https://kubernetes.default.svc:443" \
  token_reviewer_jwt="$(kubectl -n vault get secret $(kubectl -n vault get sa vault -o jsonpath='{.secrets[0].name}') -o jsonpath='{.data.token}' | base64 -d)" \
  kubernetes_ca_cert=@/var/run/secrets/kubernetes.io/serviceaccount/ca.crt
```

If Vault runs inside the same cluster, you can use the injector's SA or a dedicated reviewer token. Alternative (Vault in-cluster):

```bash
vault write auth/kubernetes/config \
  kubernetes_host="https://$KUBERNETES_PORT_443_TCP_ADDR:443" \
  token_reviewer_jwt="$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)" \
  kubernetes_ca_cert=@/var/run/secrets/kubernetes.io/serviceaccount/ca.crt
```

## 3. Create policy and role per service (Service Account auth)

Each TechInsight app has a ServiceAccount. Create a Vault policy that allows reading only that app's secrets, then a Vault role that binds the Kubernetes ServiceAccount to that policy.

Run the script:

```bash
./setup-policies-roles.sh
```

Or apply the HCL policy and role commands from `policies/` and `roles/` manually (see below).

## 4. Store secrets in Vault

Example for be-api-service (KV v2 path is `secret/data/...`):

```bash
vault kv put secret/techinsight/be-api-service \
  JWT_SECRET="your-jwt-secret" \
  REDIS_PASSWORD="" \
  MONGODB_URI="mongodb://mongo1:27017/techinsight?replicaSet=rs0" \
  MINIO_ACCESS_KEY="..." \
  MINIO_SECRET_KEY="..."
```

Repeat for `secret/techinsight/be-worker-service`, `secret/techinsight/be-auth-service`, etc., as needed.

## 5. Vault Agent Injector annotations

Deployments in `../` use annotations so the Vault Agent Injector (sidecar) logs in with the pod's ServiceAccount, reads the role `be-api-service`, and injects secrets from `secret/techinsight/be-api-service` into the container (e.g. as env or file). No static Kubernetes Secret needed for those values.
