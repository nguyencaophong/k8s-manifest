# Consul for TechInsight (variables / config)

Use Consul KV for non-secret configuration (variables). Secrets stay in Vault; Consul holds app config (URIs, feature flags, etc.) that can change without redeploy.

## 1. Install Consul (Helm example)

```bash
helm repo add hashicorp https://helm.releases.hashicorp.com
helm repo update
helm install consul hashicorp/consul -n consul --create-namespace \
  -f values.yaml
```

Example `values.yaml` (minimal for KV only):

```yaml
global:
  name: consul
server:
  replicas: 1
  storage: 10Gi
ui:
  enabled: true
connect:
  enabled: false   # set true if you use service mesh later
```

## 2. Consul KV keys (variables)

Suggested key layout. Values are plain text or JSON.

| Key | Description |
|-----|-------------|
| `techinsight/config/app/environment` | production / staging |
| `techinsight/config/app/port` | 8080 |
| `techinsight/config/database/mongodb_uri` | mongodb://mongo1:27017/techinsight?replicaSet=rs0 |
| `techinsight/config/cache/redis_addr` | redis:6379 |
| `techinsight/config/kafka/brokers` | ["broker:29092"] |
| `techinsight/config/auth/grpc_addr` | be-auth-service:50051 |
| `techinsight/config/elasticsearch/url` | http://elasticsearch:9200 |
| `techinsight/config/features/analytics` | true |

Example:

```bash
consul kv put techinsight/config/app/environment production
consul kv put techinsight/config/database/mongodb_uri "mongodb://mongo1:27017/techinsight?replicaSet=rs0"
consul kv put techinsight/config/auth/grpc_addr be-auth-service:50051
```

## 3. Service account / ACL (optional)

To restrict read access with Consul ACLs:

- Create a policy that allows read on `techinsight/` prefix.
- Use Consul Kubernetes auth (Consul 1.9+) or store a Consul token in Vault and inject it via Vault Agent (same SA auth flow). Apps then use `CONSUL_HTTP_TOKEN` to read KV.

Storing Consul token in Vault:

```bash
vault kv patch secret/techinsight/be-api-service CONSUL_HTTP_TOKEN="<consul-acl-token>"
```

The existing Vault Agent inject will expose it as env; app or Consul Template can use it to read KV.

## 4. Reading config in the app

- **Option A**: App uses Consul client at startup (e.g. `consul/api` in Go), reads KV, builds config. Needs `CONSUL_HTTP_ADDR` and `CONSUL_HTTP_TOKEN` (from Vault).
- **Option B**: Consul Template sidecar or init container: template reads KV and writes `config.yml` to shared volume; app keeps reading from file. Consul token can be injected from Vault into the template container.

If you use Option B, add a Consul Template deployment or init container that renders `config.yml` from KV keys; point the app’s config path at the rendered file.
