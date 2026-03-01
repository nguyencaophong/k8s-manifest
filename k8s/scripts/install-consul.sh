#!/usr/bin/env bash
# Cài Consul (Helm) vào namespace consul để be-api, be-auth, be-worker có thể start.
# Các pod này cần init container kết nối consul-server.consul.svc.cluster.local:8500.
# Sau khi chạy: load config vào Consul (load-config-into-consul.sh) và đảm bảo Vault đã setup.
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
K8S_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
CONSUL_VALUES="$K8S_DIR/consul/values.yaml"

if ! command -v helm &>/dev/null; then
  echo "Error: helm not found. Install Helm rồi chạy lại."
  exit 1
fi
if ! kubectl cluster-info &>/dev/null; then
  echo "Error: kubectl không kết nối được cluster."
  exit 1
fi

echo "Adding HashiCorp Helm repo..."
helm repo add hashicorp https://helm.releases.hashicorp.com
helm repo update

echo "Creating namespace consul..."
kubectl create namespace consul --dry-run=client -o yaml | kubectl apply -f -

echo "Installing Consul (values: $CONSUL_VALUES)..."
# --skip-crds: tránh conflict với CRD Gateway API đã có sẵn trên cluster (gatewayclasses.gateway.networking.k8s.io)
helm upgrade --install consul hashicorp/consul -n consul -f "$CONSUL_VALUES" --skip-crds --wait --timeout 5m

echo ""
echo "Consul đã cài. Tiếp theo:"
echo "  1. Load config vào Consul KV (cho api/auth/worker):"
echo "     kubectl port-forward -n consul svc/consul-server 8500:8500 &"
echo "     cd $K8S_DIR/consul && CONSUL_HTTP_ADDR=http://127.0.0.1:8500 ./load-config-into-consul.sh"
echo "  2. Đảm bảo Vault đã cài, unseal, có policies/roles và đã chạy vault/populate-secrets.sh"
echo "  3. Restart các deployment techinsight: kubectl -n techinsight rollout restart deployment core-service auth-service be-worker-service"
echo ""
echo "Truy cập Consul UI: kubectl port-forward -n consul svc/consul-server 8500:8500 -> http://localhost:8500"
