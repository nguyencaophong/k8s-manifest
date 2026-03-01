#!/usr/bin/env bash
# Run with VAULT_ADDR and VAULT_TOKEN set. Creates policies and Kubernetes auth roles for TechInsight.
set -e

NAMESPACE="${VAULT_NAMESPACE:-techinsight}"

# Policies: core-service, auth-service, be-worker-service
for app in core-service auth-service be-worker-service; do
  policy_name="techinsight-${app}"
  vault policy write "$policy_name" - < "policies/techinsight-${app}.hcl"
  echo "Policy written: $policy_name"
done

# Kubernetes auth roles: bind K8s ServiceAccount to Vault policy
vault write auth/kubernetes/role/core-service \
  bound_service_account_names=core-service \
  bound_service_account_namespaces="$NAMESPACE" \
  policies=techinsight-core-service \
  ttl=1h

vault write auth/kubernetes/role/auth-service \
  bound_service_account_names=auth-service \
  bound_service_account_namespaces="$NAMESPACE" \
  policies=techinsight-auth-service \
  ttl=1h

vault write auth/kubernetes/role/be-worker-service \
  bound_service_account_names=be-worker-service \
  bound_service_account_namespaces="$NAMESPACE" \
  policies=techinsight-be-worker-service \
  ttl=1h

echo "Done. Ensure secrets are stored at secret/techinsight/<service> and injector is enabled."
