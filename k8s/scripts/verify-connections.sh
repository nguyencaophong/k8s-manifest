#!/usr/bin/env bash
# Verify TechInsight K8s: pods, services, and in-cluster health (API, FE, FE-Admin).
# Run after apply.sh. Requires kubectl and cluster access.
# Exit 0 = all checks pass, 1 = some failed.
NS="${NAMESPACE:-techinsight}"
FAIL=0

echo "=== 1. Pods (namespace: $NS) ==="
kubectl -n "$NS" get pods -o wide
echo ""

echo "=== 2. Status theo từng service (Ready/Desired) ==="
for app in core-service auth-service be-worker-service fe-service fe-admin-service; do
  DESIRED=$(kubectl -n "$NS" get deployment "$app" -o jsonpath='{.spec.replicas}' 2>/dev/null || echo "0")
  READY=$(kubectl -n "$NS" get deployment "$app" -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo "0")
  if [ -z "$DESIRED" ] || [ "$DESIRED" = "0" ]; then
    echo "  $app: deployment không tìm thấy hoặc 0 replicas"
    FAIL=1
  elif [ "${READY:-0}" -lt "$DESIRED" ]; then
    echo "  $app: ${READY:-0}/$DESIRED Ready (một số pod chưa Ready/Running)"
    FAIL=1
  else
    echo "  $app: $READY/$DESIRED Ready"
  fi
done
echo ""

echo "=== 3. Services ==="
kubectl -n "$NS" get svc
echo ""

echo "=== 4. Ingress ==="
kubectl -n "$NS" get ingress 2>/dev/null || true
echo ""

echo "=== 5. Kiểm tra kết nối trong cluster ==="
API_POD=$(kubectl -n "$NS" get pods -l app=core-service -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || true)
if [ -n "$API_POD" ]; then
  if kubectl -n "$NS" exec "$API_POD" -c api -- wget -qO- --timeout=3 http://core-service:8080/metrics/health 2>/dev/null | grep -q .; then
    echo "  core-service (health): OK"
  else
    echo "  core-service (health): FAIL (pod có thể đang start hoặc lỗi)"
    FAIL=1
  fi
else
  echo "  core-service: không có pod để kiểm tra"
  FAIL=1
fi

FE_POD=$(kubectl -n "$NS" get pods -l app=fe-service -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || true)
if [ -n "$FE_POD" ]; then
  if kubectl -n "$NS" exec "$FE_POD" -c web -- wget -qO- -T 3 http://fe-service:3000/ 2>/dev/null | head -c 1 | grep -q .; then
    echo "  fe-service: OK"
  else
    echo "  fe-service: FAIL"
    FAIL=1
  fi
else
  echo "  fe-service: không có pod để kiểm tra"
  FAIL=1
fi

FE_ADMIN_POD=$(kubectl -n "$NS" get pods -l app=fe-admin-service -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || true)
if [ -n "$FE_ADMIN_POD" ]; then
  if kubectl -n "$NS" exec "$FE_ADMIN_POD" -c admin -- wget -qO- -T 3 http://fe-admin-service:3000/ 2>/dev/null | head -c 1 | grep -q .; then
    echo "  fe-admin-service: OK"
  else
    echo "  fe-admin-service: FAIL"
    FAIL=1
  fi
else
  echo "  fe-admin-service: không có pod để kiểm tra"
  FAIL=1
fi

echo ""
echo "=== 6. Kết luận ==="
if [ "$FAIL" -eq 0 ]; then
  echo "  Tất cả kiểm tra PASS. Các service trong cụm K8s đang hoạt động."
  exit 0
else
  echo "  Một số kiểm tra FAIL. Xem chi tiết trên; sửa lỗi (image, Vault/Consul, infra ngoài) rồi chạy lại."
  exit 1
fi
