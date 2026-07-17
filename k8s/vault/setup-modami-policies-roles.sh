#!/usr/bin/env bash
# Setup Vault policies + Kubernetes auth roles for all Modami services.
# Usage: export VAULT_ADDR and VAULT_TOKEN, then run this script.
set -e

cd "$(dirname "$0")"

# ─── 1. Policies (file-based) ────────────────────────────────────────────────
for app in be-modami-auth-service be-modami-user-service be-modami-core-service be-modami-upload-service be-modami-chat-service be-modami-noti-service centrifugo; do
  policy_name="modami-${app}"
  vault policy write "$policy_name" "policies/modami-${app}.hcl"
  echo "Policy written: $policy_name"
done

# ─── 2. Kubernetes auth roles ────────────────────────────────────────────────
vault write auth/kubernetes/role/be-modami-auth-service \
  bound_service_account_names=be-modami-auth-service \
  bound_service_account_namespaces=modami \
  policies=modami-be-modami-auth-service \
  ttl=1h

vault write auth/kubernetes/role/be-modami-user-service \
  bound_service_account_names=be-modami-user-service \
  bound_service_account_namespaces=modami \
  policies=modami-be-modami-user-service \
  ttl=1h

vault write auth/kubernetes/role/be-modami-core-service \
  bound_service_account_names=be-modami-core-service \
  bound_service_account_namespaces=modami \
  policies=modami-be-modami-core-service \
  ttl=1h

vault write auth/kubernetes/role/be-modami-upload-service \
  bound_service_account_names=be-modami-upload-service \
  bound_service_account_namespaces=modami \
  policies=modami-be-modami-upload-service \
  ttl=1h

vault write auth/kubernetes/role/be-modami-chat-service \
  bound_service_account_names=be-modami-chat-service \
  bound_service_account_namespaces=modami \
  policies=modami-be-modami-chat-service \
  ttl=1h

vault write auth/kubernetes/role/centrifugo \
  bound_service_account_names=centrifugo \
  bound_service_account_namespaces=modami \
  policies=modami-centrifugo \
  ttl=1h

for svc in be-modami-noti-service-api be-modami-noti-service-ingest be-modami-noti-service-ws-gateway be-modami-noti-service-worker-dispatch be-modami-noti-service-worker-push; do
  vault write auth/kubernetes/role/"${svc}" \
    bound_service_account_names="${svc}" \
    bound_service_account_namespaces=modami \
    policies=modami-be-modami-noti-service \
    ttl=1h
  echo "Role created: ${svc}"
done

echo "Done. All Vault roles bound to namespace=modami."
