#!/usr/bin/env bash
# Populate Vault secrets cho Modami (thêm vào Vault hiện có của techinsight).
# Usage: export VAULT_ADDR và VAULT_TOKEN, rồi chạy script n��y.
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
ENV_FILE="${ENV_FILE:-$PROJECT_ROOT/.env}"

if [ -z "$VAULT_ADDR" ] || [ -z "$VAULT_TOKEN" ]; then
  echo "Set VAULT_ADDR and VAULT_TOKEN first."
  exit 1
fi

# Load .env if present
if [ -f "$ENV_FILE" ]; then
  set -a; source "$ENV_FILE"; set +a
fi

# Defaults (override via .env)
REDIS_PASSWORD="${REDIS_PASSWORD:-}"
MONGODB_URI="${MONGODB_URI:-mongodb://mongo1.techinsight.svc.cluster.local:27017/modami?replicaSet=rs0}"
MINIO_ACCESS_KEY="${MINIO_ROOT_USER:-minioadmin}"
MINIO_SECRET_KEY="${MINIO_ROOT_PASSWORD:-minioadmin123}"
ELASTICSEARCH_USER="${ELASTICSEARCH_USER:-}"
ELASTICSEARCH_PASSWORD="${ELASTICSEARCH_PASSWORD:-}"
EMAIL_SMTP_USERNAME="${EMAIL_SMTP_USERNAME:-}"
EMAIL_SMTP_PASSWORD="${EMAIL_SMTP_PASSWORD:-}"
EMAIL_FROM="${EMAIL_FROM:-noreply@modami.com}"

# Postgres
POSTGRES_USER_AUTH="${POSTGRES_USER_AUTH:-postgres}"
POSTGRES_PASSWORD_AUTH="${POSTGRES_PASSWORD_AUTH:-postgres_password}"
POSTGRES_USER_USER="${POSTGRES_USER_USER:-postgres}"
POSTGRES_PASSWORD_USER="${POSTGRES_PASSWORD_USER:-postgres_password}"

# Keycloak
KEYCLOAK_BASE_URL="${KEYCLOAK_BASE_URL:-}"
KEYCLOAK_CLIENT_SECRET="${KEYCLOAK_CLIENT_SECRET:-}"
KEYCLOAK_ADMIN_USER="${KEYCLOAK_ADMIN_USER:-admin}"
KEYCLOAK_ADMIN_PASS="${KEYCLOAK_ADMIN_PASS:-}"
KEYCLOAK_REDIRECT_URL="${KEYCLOAK_REDIRECT_URL:-}"
KEYCLOAK_FRONTEND_CALLBACK_URL="${KEYCLOAK_FRONTEND_CALLBACK_URL:-}"
KEYCLOAK_JWKS_URL="${KEYCLOAK_JWKS_URL:-}"

# Centrifugo
CENTRIFUGO_API_KEY="${CENTRIFUGO_API_KEY:-CHANGE_ME}"
CENTRIFUGO_HMAC_SECRET="${CENTRIFUGO_HMAC_SECRET:-CHANGE_ME}"
CENTRIFUGO_ADMIN_PASSWORD="${CENTRIFUGO_ADMIN_PASSWORD:-CHANGE_ME}"
CENTRIFUGO_ADMIN_SECRET="${CENTRIFUGO_ADMIN_SECRET:-CHANGE_ME}"

echo "Writing Modami secrets to Vault..."

vault kv put secret/modami/be-modami-auth-service \
  postgres_user="$POSTGRES_USER_AUTH" \
  postgres_password="$POSTGRES_PASSWORD_AUTH" \
  redis_password="$REDIS_PASSWORD" \
  keycloak_base_url="$KEYCLOAK_BASE_URL" \
  keycloak_client_secret="$KEYCLOAK_CLIENT_SECRET" \
  keycloak_admin_user="$KEYCLOAK_ADMIN_USER" \
  keycloak_admin_pass="$KEYCLOAK_ADMIN_PASS" \
  keycloak_redirect_url="$KEYCLOAK_REDIRECT_URL" \
  keycloak_frontend_callback_url="$KEYCLOAK_FRONTEND_CALLBACK_URL" \
  email_smtp_username="$EMAIL_SMTP_USERNAME" \
  email_smtp_password="$EMAIL_SMTP_PASSWORD" \
  email_from="$EMAIL_FROM"

vault kv put secret/modami/be-modami-user-service \
  postgres_user="$POSTGRES_USER_USER" \
  postgres_password="$POSTGRES_PASSWORD_USER" \
  redis_password="$REDIS_PASSWORD" \
  keycloak_jwks_url="$KEYCLOAK_JWKS_URL"

MONGODB_DATABASE_CORE="${MONGODB_DATABASE_CORE:-techinsights-core-service}"
vault kv put secret/modami/be-modami-core-service \
  mongodb_uri="$MONGODB_URI" \
  mongodb_database="$MONGODB_DATABASE_CORE" \
  jwt_secret="$JWT_SECRET" \
  redis_password="$REDIS_PASSWORD" \
  elasticsearch_user="$ELASTICSEARCH_USER" \
  elasticsearch_password="$ELASTICSEARCH_PASSWORD"

POSTGRES_USER_UPLOAD="${POSTGRES_USER_UPLOAD:-postgres}"
POSTGRES_PASSWORD_UPLOAD="${POSTGRES_PASSWORD_UPLOAD:-postgres_password}"
REDIS_CACHE_PASSWORD="${REDIS_CACHE_PASSWORD:-}"
VIMEO_CLIENT_ID="${VIMEO_CLIENT_ID:-}"
VIMEO_CLIENT_SECRET="${VIMEO_CLIENT_SECRET:-}"
VIMEO_ACCESS_TOKEN="${VIMEO_ACCESS_TOKEN:-}"
AWS_COGNITO_POOL_ID="${AWS_COGNITO_POOL_ID:-}"
KAFKA_SASL_USERNAME_UPLOAD="${KAFKA_SASL_USERNAME_UPLOAD:-}"
KAFKA_SASL_PASSWORD_UPLOAD="${KAFKA_SASL_PASSWORD_UPLOAD:-}"

vault kv put secret/modami/be-modami-upload-service \
  postgres_user="$POSTGRES_USER_UPLOAD" \
  postgres_password="$POSTGRES_PASSWORD_UPLOAD" \
  minio_access_key="$MINIO_ACCESS_KEY" \
  minio_secret_key="$MINIO_SECRET_KEY" \
  redis_cache_password="$REDIS_CACHE_PASSWORD" \
  vimeo_client_id="$VIMEO_CLIENT_ID" \
  vimeo_client_secret="$VIMEO_CLIENT_SECRET" \
  vimeo_access_token="$VIMEO_ACCESS_TOKEN" \
  aws_cognito_pool_id="$AWS_COGNITO_POOL_ID" \
  kafka_sasl_username="$KAFKA_SASL_USERNAME_UPLOAD" \
  kafka_sasl_password="$KAFKA_SASL_PASSWORD_UPLOAD"

vault kv put secret/modami/be-modami-noti-service \
  redis_password="$REDIS_PASSWORD" \
  centrifugo_api_key="$CENTRIFUGO_API_KEY" \
  centrifugo_hmac_secret="$CENTRIFUGO_HMAC_SECRET"

MONGODB_DATABASE_CHAT="${MONGODB_DATABASE_CHAT:-modami-chat-service}"
vault kv put secret/modami/be-modami-chat-service \
  mongodb_uri="$MONGODB_URI" \
  mongodb_database="$MONGODB_DATABASE_CHAT" \
  redis_password="$REDIS_PASSWORD" \
  centrifugo_api_key="$CENTRIFUGO_API_KEY" \
  centrifugo_hmac_secret="$CENTRIFUGO_HMAC_SECRET"

vault kv put secret/modami/centrifugo \
  api_key="$CENTRIFUGO_API_KEY" \
  token_hmac_secret_key="$CENTRIFUGO_HMAC_SECRET" \
  admin_password="$CENTRIFUGO_ADMIN_PASSWORD" \
  admin_secret="$CENTRIFUGO_ADMIN_SECRET"

echo "Done. Secrets at:"
echo "  secret/modami/be-modami-auth-service"
echo "  secret/modami/be-modami-user-service"
echo "  secret/modami/be-modami-core-service"
echo "  secret/modami/be-modami-upload-service"
echo "  secret/modami/be-modami-noti-service"
echo "  secret/modami/be-modami-chat-service"
echo "  secret/modami/centrifugo"
