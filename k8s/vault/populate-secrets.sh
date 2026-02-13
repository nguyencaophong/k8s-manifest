#!/usr/bin/env bash
# Populate Vault with all secrets and env for TechInsight.
# Usage: export VAULT_ADDR and VAULT_TOKEN, then ./populate-secrets.sh
# Optional: set CONSUL_HTTP_TOKEN for Consul ACL token to store in Vault.
# Values are read from ../.env if present, else use defaults below.
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
ENV_FILE="${ENV_FILE:-$PROJECT_ROOT/.env}"

if [ -z "$VAULT_ADDR" ] || [ -z "$VAULT_TOKEN" ]; then
  echo "Set VAULT_ADDR and VAULT_TOKEN (e.g. export VAULT_ADDR=http://vault:8200 VAULT_TOKEN=...)"
  exit 1
fi

# Load .env if present
if [ -f "$ENV_FILE" ]; then
  set -a
  # shellcheck source=/dev/null
  source "$ENV_FILE"
  set +a
fi

# Defaults (override via .env or env)
REDIS_PASSWORD="${REDIS_CONTENT_PASSWORD:-}"
JWT_SECRET="${JWT_SECRET:-your-super-secret-jwt-key-change-in-production}"
MONGODB_URI="${MONGODB_URI:-mongodb://mongo1:27017/techinsight?replicaSet=rs0}"
MINIO_ACCESS_KEY="${MINIO_ROOT_USER:-minioadmin}"
MINIO_SECRET_KEY="${MINIO_ROOT_PASSWORD:-minioadmin123}"
CONSUL_HTTP_TOKEN="${CONSUL_HTTP_TOKEN:-}"

echo "Writing secrets to Vault..."

# be-api-service: all secrets + Consul token
vault kv put secret/techinsight/be-api-service \
  JWT_SECRET="$JWT_SECRET" \
  REDIS_PASSWORD="$REDIS_PASSWORD" \
  MONGODB_URI="$MONGODB_URI" \
  MINIO_ACCESS_KEY="$MINIO_ACCESS_KEY" \
  MINIO_SECRET_KEY="$MINIO_SECRET_KEY" \
  CONSUL_HTTP_ADDR="http://consul-server.consul.svc.cluster.local:8500" \
  CONSUL_HTTP_TOKEN="$CONSUL_HTTP_TOKEN"

# be-worker-service: same as API (shared config)
vault kv put secret/techinsight/be-worker-service \
  JWT_SECRET="$JWT_SECRET" \
  REDIS_PASSWORD="$REDIS_PASSWORD" \
  MONGODB_URI="$MONGODB_URI" \
  MINIO_ACCESS_KEY="$MINIO_ACCESS_KEY" \
  MINIO_SECRET_KEY="$MINIO_SECRET_KEY" \
  CONSUL_HTTP_ADDR="http://consul-server.consul.svc.cluster.local:8500" \
  CONSUL_HTTP_TOKEN="$CONSUL_HTTP_TOKEN"

# be-auth-service
vault kv put secret/techinsight/be-auth-service \
  JWT_SECRET="$JWT_SECRET" \
  CONSUL_HTTP_ADDR="http://consul-server.consul.svc.cluster.local:8500" \
  CONSUL_HTTP_TOKEN="$CONSUL_HTTP_TOKEN"

echo "Done. Secrets are at secret/techinsight/{be-api-service,be-worker-service,be-auth-service}"
echo "Optional: set CONSUL_HTTP_TOKEN before running to store Consul ACL token in Vault."
