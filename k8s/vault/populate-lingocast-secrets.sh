#!/usr/bin/env bash
# Populate Vault secrets for Lingocast (added to the existing Vault used by techinsight/modami).
# Usage: export VAULT_ADDR and VAULT_TOKEN, then run this script.
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

# Defaults (override via .env) — shared MongoDB/Redis/MinIO instances in namespace techinsight
MONGODB_URI="${MONGODB_URI:-mongodb://mongo1.techinsight.svc.cluster.local:27017/lingocast?replicaSet=rs0}"
REDIS_PASSWORD="${REDIS_PASSWORD:-}"
MINIO_ACCESS_KEY="${MINIO_ROOT_USER:-minioadmin}"
MINIO_SECRET_KEY="${MINIO_ROOT_PASSWORD:-minioadmin123}"

MONGODB_DATABASE_CORE="${MONGODB_DATABASE_CORE:-lingocast-core-service}"
MONGODB_DATABASE_JOB_SCHEDULER="${MONGODB_DATABASE_JOB_SCHEDULER:-lingocast-job-scheduler}"

echo "Writing Lingocast secrets to Vault..."

vault kv put secret/lingocast/be-lingocast-core-service \
  mongodb_uri="$MONGODB_URI" \
  mongodb_database="$MONGODB_DATABASE_CORE" \
  redis_password="$REDIS_PASSWORD" \
  minio_access_key="$MINIO_ACCESS_KEY" \
  minio_secret_key="$MINIO_SECRET_KEY"

vault kv put secret/lingocast/be-lingocast-job-scheduler \
  mongodb_uri="$MONGODB_URI" \
  mongodb_database="$MONGODB_DATABASE_JOB_SCHEDULER" \
  redis_password="$REDIS_PASSWORD"

vault kv put secret/lingocast/voice-analyze-and-summarizer-asr \
  minio_access_key="$MINIO_ACCESS_KEY" \
  minio_secret_key="$MINIO_SECRET_KEY"

echo "Done. Secrets at:"
echo "  secret/lingocast/be-lingocast-core-service"
echo "  secret/lingocast/be-lingocast-job-scheduler"
echo "  secret/lingocast/voice-analyze-and-summarizer-asr"
