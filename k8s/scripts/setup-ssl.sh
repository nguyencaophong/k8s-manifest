#!/usr/bin/env bash
# Setup SSL cho techinsightsworld.com bằng cert-manager + Let's Encrypt
# Yêu cầu: cert-manager đã cài, DNS đã trỏ về IP cluster, Kong Ingress đang chạy
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
K8S_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "=== 1. Kiểm tra cert-manager ==="
if ! kubectl get namespace cert-manager &>/dev/null; then
  echo "cert-manager namespace chưa tồn tại. Cài cert-manager..."
  kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml
  echo "Đợi cert-manager pods Running..."
  kubectl wait --for=condition=ready pod -l app.kubernetes.io/instance=cert-manager -n cert-manager --timeout=300s || true
else
  echo "cert-manager namespace tồn tại. Kiểm tra pods..."
  kubectl get pods -n cert-manager
fi
echo ""

echo "=== 2. Apply ClusterIssuer (Let's Encrypt) ==="
kubectl apply -f "$K8S_DIR/cert-manager-issuer.yaml"
kubectl get clusterissuer letsencrypt-prod
echo ""

echo "=== 3. Apply Certificate resources ==="
kubectl apply -f "$K8S_DIR/certificate-techinsight-web.yaml"
kubectl apply -f "$K8S_DIR/certificate-techinsight-api.yaml"
echo ""

echo "=== 4. Apply Ingress (đã có TLS config) ==="
kubectl apply -f "$K8S_DIR/ingress.yaml"
echo ""

echo "=== 5. Kiểm tra Certificate status ==="
echo "Đợi vài phút để Let's Encrypt issue certificate..."
sleep 5
kubectl get certificate -n techinsight
kubectl describe certificate techinsight-web-tls -n techinsight | grep -A 10 "Status\|Events" || true
echo ""

echo "=== 6. Kiểm tra Secret (certificate) ==="
kubectl get secret techinsight-web-tls -n techinsight 2>/dev/null && echo "✓ Secret techinsight-web-tls tồn tại" || echo "✗ Secret chưa có (certificate đang pending hoặc failed)"
kubectl get secret techinsight-api-tls -n techinsight 2>/dev/null && echo "✓ Secret techinsight-api-tls tồn tại" || echo "✗ Secret chưa có"
echo ""

echo "=== Hoàn tất ==="
echo "Kiểm tra certificate:"
echo "  kubectl get certificate -n techinsight"
echo "  kubectl describe certificate techinsight-web-tls -n techinsight"
echo ""
echo "Nếu certificate Pending/Failed:"
echo "  1. DNS: techinsightsworld.com phải trỏ về IP cluster (76.13.182.234)"
echo "  2. Port 80 từ internet phải tới được Kong (LB/NodePort map 80 -> Kong proxy)"
echo "  3. Kong Ingress: kubectl get ingress -n techinsight"
echo "  4. Retry: kubectl delete certificaterequest techinsight-web-tls-1 -n techinsight"
echo "  5. Log: kubectl logs -n cert-manager -l app=cert-manager"
echo ""
echo "Sau khi certificate Ready, truy cập: https://techinsightsworld.com"
