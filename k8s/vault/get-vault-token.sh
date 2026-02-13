#!/usr/bin/env bash
# Vault: in cluster đã init + unseal, root token KHÔNG lưu trong K8s.
# Script này: port-forward Vault, hướng dẫn lấy token (nếu có unseal key) hoặc dùng token đã lưu.
set -e

NAMESPACE="${VAULT_NAMESPACE:-vault}"
VAULT_ADDR_LOCAL="${VAULT_ADDR:-http://127.0.0.1:8200}"

echo "=== Vault pod & status ==="
kubectl get pods -n "$NAMESPACE" -l app.kubernetes.io/name=vault 2>/dev/null || true
echo ""
if ! kubectl exec -n "$NAMESPACE" vault-0 -- vault status 2>/dev/null; then
  echo "Không kết nối được vault-0. Kiểm tra namespace và pod."
  exit 1
fi

echo ""
echo "=== Cách lấy token để login ==="
echo "1) Nếu bạn CÒN LƯU root token từ lần chạy 'vault operator init' trước đây:"
echo "   export VAULT_ADDR=$VAULT_ADDR_LOCAL"
echo "   export VAULT_TOKEN=<root_token_da_luu>"
echo "   vault login"
echo ""
echo "2) Nếu bạn CÒN LƯU unseal key (1 key, vì cluster dùng 1 share):"
echo "   Port-forward: kubectl port-forward -n $NAMESPACE svc/vault 8200:8200 &"
echo "   export VAULT_ADDR=$VAULT_ADDR_LOCAL"
echo "   vault operator generate-root"
echo "   Nhập unseal key khi được hỏi -> sẽ tạo root token mới."
echo ""
echo "3) Chạy port-forward ngay (để dùng vault CLI từ máy bạn):"
echo "   kubectl port-forward -n $NAMESPACE svc/vault 8200:8200"
echo "   Sau đó: export VAULT_ADDR=$VAULT_ADDR_LOCAL và vault login <token>"
echo ""
echo "4) Chưa cài Vault CLI? Chạy vault TRONG pod:"
echo "   kubectl exec -n $NAMESPACE -it vault-0 -- vault login"
echo "   (Nhập token khi được hỏi. VAULT_ADDR trong pod đã trỏ 127.0.0.1:8200.)"
echo ""

# Optional: start port-forward in background (user can kill with fg then Ctrl+C)
if [ "${START_PORT_FORWARD:-0}" = "1" ]; then
  echo "Đang chạy port-forward (background)..."
  kubectl port-forward -n "$NAMESPACE" svc/vault 8200:8200 &
  sleep 2
  echo "Port-forward đang chạy. VAULT_ADDR=$VAULT_ADDR_LOCAL"
fi
