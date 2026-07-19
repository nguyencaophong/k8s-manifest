#!/usr/bin/env bash
# Setup Vault policies + Kubernetes auth roles for all Lingocast services.
# Usage: export VAULT_ADDR and VAULT_TOKEN, then run this script.
set -e

cd "$(dirname "$0")"

# ─── 1. Policies (file-based) ────────────────────────────────────────────────
for app in be-lingocast-core-service be-lingocast-job-scheduler voice-analyze-and-summarizer-asr; do
  policy_name="lingocast-${app}"
  vault policy write "$policy_name" "policies/lingocast-${app}.hcl"
  echo "Policy written: $policy_name"
done

# ─── 2. Kubernetes auth roles ────────────────────────────────────────────────
vault write auth/kubernetes/role/be-lingocast-core-service \
  bound_service_account_names=be-lingocast-core-service \
  bound_service_account_namespaces=lingocast \
  policies=lingocast-be-lingocast-core-service \
  ttl=1h

vault write auth/kubernetes/role/be-lingocast-job-scheduler \
  bound_service_account_names=be-lingocast-job-scheduler \
  bound_service_account_namespaces=lingocast \
  policies=lingocast-be-lingocast-job-scheduler \
  ttl=1h

vault write auth/kubernetes/role/voice-analyze-and-summarizer-asr \
  bound_service_account_names=voice-analyze-and-summarizer-asr \
  bound_service_account_namespaces=lingocast \
  policies=lingocast-voice-analyze-and-summarizer-asr \
  ttl=1h

echo "Done. All Vault roles bound to namespace=lingocast."
