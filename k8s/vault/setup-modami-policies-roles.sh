#!/usr/bin/env bash
# Thêm policies và roles cho Modami vào Vault hiện có (techinsight).
# Chạy trên cùng Vault instance đã setup cho techinsight.
# Usage: export VAULT_ADDR và VAULT_TOKEN, rồi chạy script này.
set -e

cd "$(dirname "$0")"

# Policies
for app in be-modami-auth-service be-modami-user-service be-modami-core-service; do
  policy_name="modami-${app}"
  vault policy write "$policy_name" "policies/modami-${app}.hcl"
  echo "Policy written: $policy_name"
done

# Kubernetes auth roles - bind SA trong namespace modami
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

echo "Done. Vault roles bound to namespace=modami."
