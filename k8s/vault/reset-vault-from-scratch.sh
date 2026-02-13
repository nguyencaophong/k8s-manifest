#!/usr/bin/env bash
# Reset Vault hoàn toàn: xóa dữ liệu, init lại từ đầu. Sẽ MẤT TOÀN BỘ secret trong Vault.
# Sau khi chạy script này, bạn chạy vault operator init trong pod và LƯU LẠI unseal key + root token.
set -e

NAMESPACE="${VAULT_NAMESPACE:-vault}"
PVC_NAME="data-vault-0"

echo "=== Reset Vault từ đầu (xóa data, init lại) ==="
echo "Cảnh báo: Mọi secret trong Vault sẽ bị xóa. Cần chạy lại setup-policies-roles.sh và populate-secrets.sh sau khi init."
echo ""
read -p "Bạn chắc chắn? (gõ yes để tiếp tục): " confirm
if [ "$confirm" != "yes" ]; then
  echo "Đã hủy."
  exit 0
fi

echo ""
echo "Bước 1/4: Xóa pod vault-0 (giải phóng PVC)..."
kubectl delete pod -n "$NAMESPACE" vault-0 --ignore-not-found --wait=false 2>/dev/null || true
sleep 5

echo "Bước 2/4: Xóa PVC $PVC_NAME (xóa toàn bộ data Vault)..."
kubectl delete pvc -n "$NAMESPACE" "$PVC_NAME" --ignore-not-found 2>/dev/null || true
sleep 2

echo "Bước 3/4: Chờ pod vault-0 chạy lại (StatefulSet tạo pod + PVC mới, volume trống)..."
kubectl wait --for=condition=Ready pod/vault-0 -n "$NAMESPACE" --timeout=120s 2>/dev/null || true
sleep 3

echo "Bước 4/4: Kiểm tra trạng thái (phải báo Initialized = false)..."
kubectl exec -n "$NAMESPACE" vault-0 -- vault status 2>&1 || true

echo ""
echo "=== Tiếp theo BẠN LÀM TAY ==="
echo "1) Init Vault (chạy 1 lần duy nhất, LƯU NGAY output):"
echo "   kubectl exec -n $NAMESPACE -it vault-0 -- vault operator init"
echo ""
echo "   -> Lưu 1 Unseal Key và Initial Root Token vào chỗ an toàn (password manager / safe)."
echo ""
echo "2) Unseal (chỉ cần 1 key):"
echo "   kubectl exec -n $NAMESPACE -it vault-0 -- vault operator unseal <Unseal_Key_1>"
echo ""
echo "3) Bật KV + Kubernetes auth (trong pod hoặc máy có vault CLI):"
echo "   kubectl exec -n $NAMESPACE -it vault-0 -- vault login <Initial_Root_Token>"
echo "   kubectl exec -n $NAMESPACE vault-0 -- vault secrets enable -path=secret kv-v2"
echo "   kubectl exec -n $NAMESPACE vault-0 -- vault auth enable kubernetes"
echo "   (Cấu hình K8s auth: xem k8s/vault/README.md và k8s/docs/VAULT_CONSUL_SETUP.md)"
echo ""
echo "4) Tạo lại policy/role và secrets:"
echo "   export VAULT_ADDR=http://127.0.0.1:8200  # và port-forward nếu từ máy ngoài"
echo "   export VAULT_TOKEN=<Initial_Root_Token>"
echo "   cd k8s/vault && ./setup-policies-roles.sh && ./populate-secrets.sh"
echo ""
