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
MONGODB_DATABASE_ASR="${MONGODB_DATABASE_ASR:-voice_analyzer}"
MONGODB_URI_ASR="${MONGODB_URI_ASR:-mongodb://mongo1.techinsight.svc.cluster.local:27017/${MONGODB_DATABASE_ASR}?replicaSet=rs0}"

# ASR uses its own Redis DB index (job-scheduler already owns db 8) and needs a
# single redis:// URL rather than separate host/port/db fields.
REDIS_DATABASE_ASR="${REDIS_DATABASE_ASR:-9}"
if [ -n "$REDIS_PASSWORD" ]; then
  REDIS_URL_ASR="${REDIS_URL_ASR:-redis://:${REDIS_PASSWORD}@redis.techinsight.svc.cluster.local:6379/${REDIS_DATABASE_ASR}}"
else
  REDIS_URL_ASR="${REDIS_URL_ASR:-redis://redis.techinsight.svc.cluster.local:6379/${REDIS_DATABASE_ASR}}"
fi

# Not sourced from a prior deploy — generate a fresh Flask session key unless one is supplied.
FLASK_SECRET_KEY_ASR="${FLASK_SECRET_KEY_ASR:-$(openssl rand -hex 32)}"

# Leave blank if not provided; patch in later with:
#   vault kv patch secret/lingocast/voice-analyze-and-summarizer-asr openai_api_key=sk-...
OPENAI_API_KEY_ASR="${OPENAI_API_KEY_ASR:-}"

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
  minio_secret_key="$MINIO_SECRET_KEY" \
  mongodb_uri="$MONGODB_URI_ASR" \
  redis_url="$REDIS_URL_ASR" \
  flask_secret_key="$FLASK_SECRET_KEY_ASR" \
  openai_api_key="$OPENAI_API_KEY_ASR"

echo "Done. Secrets at:"
echo "  secret/lingocast/be-lingocast-core-service"
echo "  secret/lingocast/be-lingocast-job-scheduler"
echo "  secret/lingocast/voice-analyze-and-summarizer-asr"
