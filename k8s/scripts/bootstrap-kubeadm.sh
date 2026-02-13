#!/usr/bin/env bash
# Bootstrap Kubernetes single-node với kubeadm (production).
# Chạy trên VPS: sudo ./bootstrap-kubeadm.sh
# Sẽ: gỡ k3s (nếu có), tắt swap, cài containerd, kubeadm/kubelet/kubectl, init cluster, CNI Flannel.
set -e

K8S_VERSION="${K8S_VERSION:-v1.28}"
POD_CIDR="${POD_CIDR:-10.244.0.0/16}"

if [ "$(id -u)" -ne 0 ]; then
  echo "Chạy với quyền root: sudo $0"
  exit 1
fi

echo "=== 1. Gỡ k3s (nếu có) ==="
if [ -x /usr/local/bin/k3s-uninstall.sh ]; then
  /usr/local/bin/k3s-uninstall.sh || true
  rm -rf /etc/rancher/k3s /var/lib/rancher/k3s 2>/dev/null || true
  echo "  k3s đã gỡ."
else
  echo "  Không có k3s, bỏ qua."
fi

echo "=== 2. Tắt swap ==="
swapoff -a 2>/dev/null || true
if grep -q '^[^#]*swap' /etc/fstab; then
  sed -i '/^[^#]*swap/s/^/#/' /etc/fstab
  echo "  Đã comment swap trong /etc/fstab."
fi

echo "=== 3. Cài containerd ==="
if ! command -v containerd &>/dev/null; then
  apt-get update -qq
  apt-get install -y -qq ca-certificates curl gnupg
  install -m 0755 -d /etc/apt/keyrings
  . /etc/os-release
  if [ "$ID" = "debian" ]; then
    curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian ${VERSION_CODENAME:-$VERSION} stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
  else
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu ${VERSION_CODENAME:-$VERSION} stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
  fi
  chmod a+r /etc/apt/keyrings/docker.gpg
  apt-get update -qq
  apt-get install -y -qq containerd.io
  mkdir -p /etc/containerd
  containerd config default | sed 's/SystemdCgroup = false/SystemdCgroup = true/' > /etc/containerd/config.toml
  systemctl enable --now containerd
  echo "  containerd đã cài."
else
  echo "  containerd đã có, bỏ qua."
fi

echo "=== 4. Cài kubeadm, kubelet, kubectl ==="
if ! command -v kubeadm &>/dev/null; then
  curl -fsSL "https://pkgs.k8s.io/core:/stable:${K8S_VERSION}/deb/Release.key" | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
  echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:${K8S_VERSION}/deb/ /" | tee /etc/apt/sources.list.d/kubernetes.list
  apt-get update -qq
  apt-get install -y -qq kubelet kubeadm kubectl
  apt-mark hold kubelet kubeadm kubectl
  # Symlink để shell đã cache /usr/local/bin/kubectl (sau khi gỡ k3s) vẫn dùng được
  ln -sf /usr/bin/kubectl /usr/local/bin/kubectl 2>/dev/null || true
  echo "  kubeadm/kubelet/kubectl đã cài."
else
  [ -x /usr/bin/kubectl ] && ln -sf /usr/bin/kubectl /usr/local/bin/kubectl 2>/dev/null || true
  echo "  kubeadm đã có, bỏ qua."
fi

echo "=== 5. kubeadm init ==="
if [ ! -f /etc/kubernetes/admin.conf ]; then
  kubeadm init --pod-network-cidr="$POD_CIDR"
  echo "  Cluster đã init."
else
  echo "  /etc/kubernetes/admin.conf đã tồn tại, bỏ qua init (chạy 'kubeadm reset -f' nếu muốn init lại)."
fi

echo "=== 6. Kubeconfig cho user hiện tại ==="
SUDO_USER="${SUDO_USER:-}"
if [ -n "$SUDO_USER" ]; then
  HOMEDIR="$(getent passwd "$SUDO_USER" | cut -d: -f6)"
  if [ -n "$HOMEDIR" ]; then
    mkdir -p "$HOMEDIR/.kube"
    cp -i /etc/kubernetes/admin.conf "$HOMEDIR/.kube/config"
    chown -R "$SUDO_USER:$SUDO_USER" "$HOMEDIR/.kube"
    chmod 600 "$HOMEDIR/.kube/config"
    echo "  Đã copy kubeconfig vào $HOMEDIR/.kube/config"
  fi
fi
mkdir -p /root/.kube
cp -i /etc/kubernetes/admin.conf /root/.kube/config 2>/dev/null || true

echo "=== 7. Cho phép schedule lên control-plane (single node) ==="
export KUBECONFIG=/etc/kubernetes/admin.conf
kubectl taint nodes --all node-role.kubernetes.io/control-plane- 2>/dev/null || true

echo "=== 8. Cài CNI Flannel ==="
kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml

echo "=== 9. Đợi node Ready ==="
for i in $(seq 1 30); do
  if kubectl get nodes --no-headers 2>/dev/null | grep -q ' Ready'; then
    echo "  Node Ready."
    kubectl get nodes
    break
  fi
  sleep 2
done

echo ""
echo "Bootstrap xong. Nếu chạy bằng sudo từ user deploy, dùng: export KUBECONFIG=\$HOME/.kube/config && kubectl get nodes"
echo "Tiếp theo: cài Kong, Vault, Consul, rồi ./apply.sh (xem k8s/docs/DEPLOY.md)."
