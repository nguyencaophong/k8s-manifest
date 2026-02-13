# Triển khai TechInsight lên K8s (Vault + Consul)

## 1. Kubeconfig (chạy một lần sau khi cluster đã init)

Cluster cài bằng kubeadm tạo file admin tại `/etc/kubernetes/admin.conf`. Copy sang user để dùng `kubectl`:

```bash
mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config
```

Nếu chạy với user không phải root, đảm bảo file có quyền đọc (ví dụ `chmod 600 $HOME/.kube/config`). Chi tiết bootstrap cluster: [KUBEADM-BOOTSTRAP.md](KUBEADM-BOOTSTRAP.md).

**Nếu gặp lỗi `kubectl: No such file or directory`** (sau khi chuyển từ k3s): chạy `source k8s/scripts/fix-kubectl-path.sh` hoặc dùng `/usr/bin/kubectl`. Script bootstrap đã tạo symlink `/usr/local/bin/kubectl` → `/usr/bin/kubectl` nếu bạn đã chạy `sudo ./bootstrap-kubeadm.sh`.

## 2. Đảm bảo Vault và Consul đã setup

- Vault: đã enable Kubernetes auth, chạy `vault/setup-policies-roles.sh`, chạy `vault/populate-secrets.sh`.
- Consul: đã cài (Helm), chạy `consul/load-config-into-consul.sh`.

Chi tiết: [VAULT_CONSUL_SETUP.md](VAULT_CONSUL_SETUP.md)

## 3. Triển khai

```bash
cd /home/deploy/techinsight/k8s
./apply.sh
```

Hoặc apply từng bước:

```bash
kubectl apply -f namespace.yaml
kubectl apply -f serviceaccounts.yaml
kubectl apply -f consul-templates-configmap.yaml
kubectl apply -f be-auth-service-deployment.yaml
kubectl apply -f be-api-service-deployment.yaml
kubectl apply -f be-worker-service-deployment.yaml
kubectl apply -f fe-service-deployment.yaml
kubectl apply -f fe-admin-service-deployment.yaml
kubectl apply -f ingress.yaml
```

## 4. Kiểm tra

```bash
./verify-connections.sh
```

Hoặc thủ công:

```bash
kubectl -n techinsight get pods
kubectl -n techinsight get svc
```

Images được dùng (trong deployment): `lifegoeson34/techinsight-api`, `lifegoeson34/techinsight-auth-service`, `lifegoeson34/techinsight-web`, `lifegoeson34/techinsight-admin`.
