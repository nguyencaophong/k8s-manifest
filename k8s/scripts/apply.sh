#!/usr/bin/env bash
# Apply TechInsight k8s manifests in order.
# Cần KUBECONFIG trỏ tới cluster (sau kubeadm init: cp /etc/kubernetes/admin.conf $HOME/.kube/config).
set -e
cd "$(dirname "$0")"

if [ -z "${SKIP_CLUSTER_CHECK:-}" ] && ! kubectl cluster-info &>/dev/null; then
  echo "Error: cannot reach cluster (check KUBECONFIG / kubeconfig and cluster is up)."
  echo "Or: SKIP_CLUSTER_CHECK=1 ./apply.sh to try apply anyway."
  exit 1
fi

echo "Creating namespace and service accounts..."
kubectl apply -f namespace.yaml
kubectl apply -f serviceaccounts.yaml

echo "Applying Consul templates (config from Vault+Consul)..."
kubectl apply -f consul-templates-configmap.yaml

echo "Applying deployments and services..."
kubectl apply -f be-auth-service-deployment.yaml
kubectl apply -f be-api-service-deployment.yaml
kubectl apply -f be-worker-service-deployment.yaml
kubectl apply -f fe-service-deployment.yaml
kubectl apply -f fe-admin-service-deployment.yaml

echo "Applying ingress..."
kubectl apply -f ingress.yaml

echo "Applying PDB..."
kubectl apply -f pdb.yaml

echo "Done. Verify: ./verify-connections.sh"
kubectl -n techinsight get pods -o wide 2>/dev/null || true
