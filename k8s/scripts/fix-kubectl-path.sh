#!/usr/bin/env bash
# Chạy sau khi bootstrap kubeadm (hoặc khi gặp "kubectl: No such file or directory").
# Sửa PATH và cache shell để dùng kubectl từ /usr/bin (kubeadm cài ở đây; k3s cũ cài ở /usr/local/bin).
# Chạy: source scripts/fix-kubectl-path.sh   hoặc   . scripts/fix-kubectl-path.sh
if [ -x /usr/bin/kubectl ]; then
  export PATH="/usr/bin:$PATH"
  hash -r 2>/dev/null || true
  echo "kubectl dùng từ /usr/bin/kubectl. Thử: kubectl get nodes"
else
  echo "Chưa có /usr/bin/kubectl. Chạy bootstrap trước: sudo ./scripts/bootstrap-kubeadm.sh"
fi
