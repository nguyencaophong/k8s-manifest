#!/usr/bin/env bash
# Populate Vault with secrets for TechInsight (single path per service, Cách B).
# Template reads secret/data/techinsight/<service> with snake_case keys.
# Usage: export VAULT_ADDR and VAULT_TOKEN, then ./populate-secrets.sh
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
JWT_SECRET="${JWT_SECRET:-your-super-secret-jwt-key-change-in-production-please}"
MONGODB_URI="${MONGODB_URI:-mongodb://mongo1:27017/techinsight?replicaSet=rs0}"
MINIO_ACCESS_KEY="${MINIO_ROOT_USER:-minioadmin}"
MINIO_SECRET_KEY="${MINIO_ROOT_PASSWORD:-minioadmin123}"
CONSUL_HTTP_TOKEN="${CONSUL_HTTP_TOKEN:-}"
ELASTICSEARCH_USER="${ELASTICSEARCH_USER:-}"
ELASTICSEARCH_PASSWORD="${ELASTICSEARCH_PASSWORD:-}"
EMAIL_SMTP_USERNAME="${EMAIL_SMTP_USERNAME:-techbross.dev@gmail.com}"
EMAIL_SMTP_PASSWORD="${EMAIL_SMTP_PASSWORD:-zumyixhgsibepkzc}"
GOOGLE_CLIENT_ID="${GOOGLE_CLIENT_ID:-72253594613-n9j88bgo9efe3ouoqvpuaujsvhqoe1d3.apps.googleusercontent.com}"
GOOGLE_CLIENT_SECRET="${GOOGLE_CLIENT_SECRET:-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}"

echo "Writing secrets to Vault (snake_case keys for consul-template)..."

# core-service: one path, keys match template .Data.data.*
vault kv put secret/techinsight/core-service \
  mongodb_uri="$MONGODB_URI" \
  jwt_secret="$JWT_SECRET" \
  redis_password="$REDIS_PASSWORD" \
  minio_access_key="$MINIO_ACCESS_KEY" \
  minio_secret_key="$MINIO_SECRET_KEY" \
  elasticsearch_user="$ELASTICSEARCH_USER" \
  elasticsearch_password="$ELASTICSEARCH_PASSWORD" \
  email_smtp_username="$EMAIL_SMTP_USERNAME" \
  email_smtp_password="$EMAIL_SMTP_PASSWORD" \
  google_client_id="$GOOGLE_CLIENT_ID" \
  google_client_secret="$GOOGLE_CLIENT_SECRET" \
  consul_http_addr="http://consul-server.consul.svc.cluster.local:8500" \
  consul_http_token="$CONSUL_HTTP_TOKEN"

# be-worker-service: same shape
vault kv put secret/techinsight/be-worker-service \
  mongodb_uri="$MONGODB_URI" \
  jwt_secret="$JWT_SECRET" \
  redis_password="$REDIS_PASSWORD" \
  minio_access_key="$MINIO_ACCESS_KEY" \
  minio_secret_key="$MINIO_SECRET_KEY" \
  elasticsearch_user="$ELASTICSEARCH_USER" \
  elasticsearch_password="$ELASTICSEARCH_PASSWORD" \
  email_smtp_username="$EMAIL_SMTP_USERNAME" \
  email_smtp_password="$EMAIL_SMTP_PASSWORD" \
  consul_http_addr="http://consul-server.consul.svc.cluster.local:8500" \
  consul_http_token="$CONSUL_HTTP_TOKEN"

# auth-service: no minio/elasticsearch but has email + google
vault kv put secret/techinsight/auth-service \
  mongodb_uri="$MONGODB_URI" \
  jwt_secret="$JWT_SECRET" \
  redis_password="$REDIS_PASSWORD" \
  email_smtp_username="$EMAIL_SMTP_USERNAME" \
  email_smtp_password="$EMAIL_SMTP_PASSWORD" \
  google_client_id="$GOOGLE_CLIENT_ID" \
  google_client_secret="$GOOGLE_CLIENT_SECRET" \
  consul_http_addr="http://consul-server.consul.svc.cluster.local:8500" \
  consul_http_token="$CONSUL_HTTP_TOKEN"

echo "Done. Secrets at:"
echo "  secret/techinsight/core-service"
echo "  secret/techinsight/be-worker-service"
echo "  secret/techinsight/auth-service"
echo "Optional: REDIS_PASSWORD, JWT_SECRET, MONGODB_URI, MINIO_*, ELASTICSEARCH_*, EMAIL_SMTP_*, GOOGLE_*, CONSUL_HTTP_TOKEN in .env"
