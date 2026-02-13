#!/usr/bin/env bash
# Cài đặt Argo CD lên cluster (namespace argocd).
# Chạy: ./install-argocd.sh
# Sau đó: kubectl -n argocd get pods (đợi Running), lấy password (xem README.md).
set -e

INSTALL_URL="${ARGOCD_INSTALL_URL:-https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml}"

if ! kubectl cluster-info &>/dev/null; then
  echo "Error: kubectl không kết nối được cluster. Kiểm tra KUBECONFIG."
  exit 1
fi

echo "Creating namespace argocd..."
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -

echo "Installing Argo CD from $INSTALL_URL..."
kubectl apply -n argocd -f "$INSTALL_URL"

echo "Done. Đợi pods Running: kubectl -n argocd get pods -w"
echo "Lấy password admin: kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
echo "Truy cập UI: kubectl port-forward svc/argocd-server -n argocd 8080:443 -> https://localhost:8080"
