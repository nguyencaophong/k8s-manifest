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
REDIS_PASSWORD="${REDIS_PASSWORD:-}"
JWT_SECRET="${JWT_SECRET:-your-super-secret-jwt-key-change-in-production}"
MONGODB_URI="${MONGODB_URI:-mongodb://mongo1:27017/techinsight?replicaSet=rs0}"
# DB structured (for template format DB_HOST, DB_USER, DB_PASS)
DB_HOST="${DB_HOST:-mongo1}"
DB_USER="${DB_USER:-}"
DB_PASS="${DB_PASS:-}"
MINIO_ACCESS_KEY="${MINIO_ROOT_USER:-minioadmin}"
MINIO_SECRET_KEY="${MINIO_ROOT_PASSWORD:-minioadmin123}"
CONSUL_HTTP_TOKEN="${CONSUL_HTTP_TOKEN:-}"
ELASTICSEARCH_USER="${ELASTICSEARCH_USER:-}"
ELASTICSEARCH_PASSWORD="${ELASTICSEARCH_PASSWORD:-}"

echo "Writing secrets to Vault..."

# Shared DB credentials (structured: host, username, password) - dùng trong template {{ with secret "secret/data/techinsight/db" }}
vault kv put secret/techinsight/db \
  host="$DB_HOST" \
  username="$DB_USER" \
  password="$DB_PASS"

# be-api-service: toàn bộ secret (username/password/...); config không nhạy cảm để trong Consul
vault kv put secret/techinsight/be-api-service \
  JWT_SECRET="$JWT_SECRET" \
  REDIS_PASSWORD="$REDIS_PASSWORD" \
  MONGODB_URI="$MONGODB_URI" \
  MINIO_ACCESS_KEY="$MINIO_ACCESS_KEY" \
  MINIO_SECRET_KEY="$MINIO_SECRET_KEY" \
  ELASTICSEARCH_USER="$ELASTICSEARCH_USER" \
  ELASTICSEARCH_PASSWORD="$ELASTICSEARCH_PASSWORD" \
  CONSUL_HTTP_ADDR="http://consul-server.consul.svc.cluster.local:8500" \
  CONSUL_HTTP_TOKEN="$CONSUL_HTTP_TOKEN"

# be-worker-service: same as API
vault kv put secret/techinsight/be-worker-service \
  JWT_SECRET="$JWT_SECRET" \
  REDIS_PASSWORD="$REDIS_PASSWORD" \
  MONGODB_URI="$MONGODB_URI" \
  MINIO_ACCESS_KEY="$MINIO_ACCESS_KEY" \
  MINIO_SECRET_KEY="$MINIO_SECRET_KEY" \
  ELASTICSEARCH_USER="$ELASTICSEARCH_USER" \
  ELASTICSEARCH_PASSWORD="$ELASTICSEARCH_PASSWORD" \
  CONSUL_HTTP_ADDR="http://consul-server.consul.svc.cluster.local:8500" \
  CONSUL_HTTP_TOKEN="$CONSUL_HTTP_TOKEN"

# be-auth-service
vault kv put secret/techinsight/be-auth-service \
  JWT_SECRET="$JWT_SECRET" \
  REDIS_PASSWORD="$REDIS_PASSWORD" \
  MONGODB_URI="$MONGODB_URI" \
  CONSUL_HTTP_ADDR="http://consul-server.consul.svc.cluster.local:8500" \
  CONSUL_HTTP_TOKEN="$CONSUL_HTTP_TOKEN"

echo "Done. Secrets at:"
echo "  secret/techinsight/db           (host, username, password)"
echo "  secret/techinsight/be-api-service, be-worker-service, be-auth-service"
echo "Optional: CONSUL_HTTP_TOKEN, ELASTICSEARCH_USER, ELASTICSEARCH_PASSWORD, DB_USER, DB_PASS in .env"
