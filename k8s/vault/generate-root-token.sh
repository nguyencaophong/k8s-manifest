#!/usr/bin/env bash
# Tạo root token MỚI khi không còn lưu token cũ. Cần 1 unseal key (cluster dùng 1 share).
# Cách dùng: ./generate-root-token.sh
# Bước 1: script chạy "generate-root -init". Bước 2: khi được hỏi "Unseal Key", dán unseal key rồi Enter.
set -e

NAMESPACE="${VAULT_NAMESPACE:-vault}"

echo "=== Bước 1/2: Khởi tạo quá trình generate root (bỏ qua nếu đã có sẵn) ==="
INIT_OUT=$(kubectl exec -n "$NAMESPACE" vault-0 -- vault operator generate-root -init 2>&1) || true
echo "$INIT_OUT"
if echo "$INIT_OUT" | grep -q "root generation already in progress"; then
  echo "(Phiên generate root đã có sẵn — chuyển sang bước nhập key.)"
elif echo "$INIT_OUT" | grep -qi "Error" && ! echo "$INIT_OUT" | grep -q "already in progress"; then
  echo "Lỗi khởi tạo."
  exit 1
fi
echo ""
echo "=== Bước 2/2: Nhập unseal key (1 key từ lần 'vault operator init') ==="
echo "Khi được hỏi 'Unseal Key (will be hidden):', dán unseal key rồi Enter."
echo ""
kubectl exec -n "$NAMESPACE" -it vault-0 -- vault operator generate-root

echo ""
echo "--- Token in ra ở trên là root token MỚI. Lưu lại. Sau đó login:"
echo "  kubectl exec -n $NAMESPACE -it vault-0 -- vault login <token_mới>"
