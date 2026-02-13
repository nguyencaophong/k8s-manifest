# Bootstrap Kubernetes single-node với kubeadm (production)

Tài liệu cài Kubernetes 1 node từ đầu bằng kubeadm, dùng containerd làm runtime. Sau khi xong, triển khai TechInsight theo [DEPLOY.md](DEPLOY.md).

**Cách nhanh (chạy trên VPS):** từ thư mục repo, chạy một lệnh (sẽ nhắc sudo):

```bash
cd /home/deploy/techinsight/k8s/scripts
sudo ./bootstrap-kubeadm.sh
```

Script sẽ: gỡ k3s (nếu có), tắt swap, cài containerd, kubeadm/kubelet/kubectl, `kubeadm init`, copy kubeconfig, bỏ taint control-plane, cài Flannel. Nếu cần làm tay từng bước, xem các mục bên dưới.

## Điều kiện

- OS: Debian hoặc Ubuntu (đã test trên 22.04 / 24.04).
- Quyền root (sudo).
- Tắt swap: `sudo swapoff -a`; xóa hoặc comment dòng swap trong `/etc/fstab` nếu cần persist.
- Đủ tài nguyên: tối thiểu 2 CPU, 2 GB RAM (production nên 4+ CPU, 8+ GB RAM).
- Cổng 6443 (API server) và các port dịch vụ (80, 443, NodePort) không bị chặn bởi firewall.

---

## 1. Gỡ k3s (nếu đang chạy)

Nếu node hiện dùng k3s, gỡ trước khi cài kubeadm (sẽ xóa toàn bộ workload và dữ liệu cluster).

```bash
/usr/local/bin/k3s-uninstall.sh
# Hoặc nếu là agent: /usr/local/bin/k3s-agent-uninstall.sh
```

Tùy chọn xóa dữ liệu cũ:

```bash
sudo rm -rf /etc/rancher/k3s /var/lib/rancher/k3s
```

Reboot hoặc đảm bảo không còn process k3s/containerd cũ trước khi cài containerd bên dưới.

---

## 2. Cài container runtime (containerd)

Cài và cấu hình containerd theo [tài liệu Kubernetes](https://kubernetes.io/docs/setup/production-environment/container-runtimes/#containerd):

- Cài gói `containerd.io` (từ repo Docker hoặc distro).
- Tạo `/etc/containerd/config.toml` với `SystemdCgroup = true` (hoặc chạy `containerd config default` rồi sửa).
- Restart và enable: `sudo systemctl enable --now containerd`.

---

## 3. Cài kubeadm, kubelet, kubectl

Thêm repo Kubernetes (apt), cài phiên bản ổn định (ví dụ 1.28 hoặc 1.29):

```bash
# Ví dụ Ubuntu/Debian
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt update
sudo apt install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
```

Kubelet có thể báo lỗi cho đến khi chạy `kubeadm init` xong.

---

## 4. kubeadm init (single control-plane)

Chạy trên node duy nhất (control-plane kiêm worker):

```bash
sudo kubeadm init --pod-network-cidr=10.244.0.0/16
```

Nếu dùng CNI khác (ví dụ Calico), đổi `--pod-network-cidr` theo tài liệu CNI đó. Sau khi xong, copy kubeconfig:

```bash
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

Cho phép schedule workload lên control-plane (single node):

```bash
kubectl taint nodes --all node-role.kubernetes.io/control-plane-
```

---

## 5. Cài CNI

Chọn một plugin. Ví dụ **Flannel**:

```bash
kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml
```

Hoặc **Calico**: dùng manifest từ [Calico docs](https://docs.tigera.io/calico/latest/getting-started/kubernetes/self-managed-onprem/onpremise) (có thể cần chỉnh `pod-network-cidr` cho đúng).

Đợi node Ready:

```bash
kubectl get nodes
```

---

## 6. Gợi ý production

- **etcd backup**: lên lịch snapshot (cron) với `etcdctl snapshot save` (cần `ETCDCTL_API=3`, endpoint và cert từ `/etc/kubernetes/pki`).
- **Kubeconfig**: `chmod 600 $HOME/.kube/config`; không commit file này lên Git.
- **Firewall**: mở 6443 (API server), 2379/2380 (etcd, nếu sau này thêm control-plane), 80/443 và các NodePort cần dùng (ví dụ 30080 cho Kong).

---

## Bước tiếp theo

Cluster đã sẵn sàng. Cài Kong (Ingress), Vault, Consul, rồi triển khai TechInsight theo [DEPLOY.md](DEPLOY.md) và [VAULT_CONSUL_SETUP.md](VAULT_CONSUL_SETUP.md).
