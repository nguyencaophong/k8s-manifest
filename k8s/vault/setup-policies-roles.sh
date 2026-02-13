#!/usr/bin/env bash
# Run with VAULT_ADDR and VAULT_TOKEN set. Creates policies and Kubernetes auth roles for TechInsight.
set -e

NAMESPACE="${VAULT_NAMESPACE:-techinsight}"

# Policies
for app in be-api-service be-worker-service be-auth-service; do
  policy_name="techinsight-${app}"
  vault policy write "$policy_name" - < "policies/techinsight-${app}.hcl"
  echo "Policy written: $policy_name"
done

# Kubernetes auth roles: bind K8s ServiceAccount to Vault policy
vault write auth/kubernetes/role/be-api-service \
  bound_service_account_names=be-api-service \
  bound_service_account_namespaces="$NAMESPACE" \
  policies=techinsight-be-api-service \
  ttl=1h

vault write auth/kubernetes/role/be-worker-service \
  bound_service_account_names=be-worker-service \
  bound_service_account_namespaces="$NAMESPACE" \
  policies=techinsight-be-worker-service \
  ttl=1h

vault write auth/kubernetes/role/be-auth-service \
  bound_service_account_names=be-auth-service \
  bound_service_account_namespaces="$NAMESPACE" \
  policies=techinsight-be-auth-service \
  ttl=1h

echo "Done. Ensure secrets are stored at secret/techinsight/<service> and injector is enabled."
