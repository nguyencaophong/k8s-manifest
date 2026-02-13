# Xử lý lỗi thường gặp

## api, auth, worker không start (Init:Error / ImagePullBackOff / CrashLoopBackOff)

**Nguyên nhân:** be-api-service, be-auth-service, be-worker-service cần **Consul** và **Vault** chạy trong cluster. Init container của mỗi pod:

1. Nhận secret từ **Vault** (qua Vault Agent Injector).
2. Kết nối **Consul** tại `consul-server.consul.svc.cluster.local:8500` để lấy config (consul-template) và ghi ra file `config.yml`.

Nếu Consul hoặc Vault chưa cài / chưa có config → init container fail → pod không bao giờ Running.

**Cách xử lý:**

### 1. Cài Consul (nếu chưa có)

```bash
cd /home/deploy/techinsight/k8s/scripts
./install-consul.sh
```

Hoặc thủ công:

```bash
helm repo add hashicorp https://helm.releases.hashicorp.com
helm repo update
kubectl create namespace consul --dry-run=client -o yaml | kubectl apply -f -
helm install consul hashicorp/consul -n consul -f /home/deploy/techinsight/k8s/consul/values.yaml
```

### 2. Load config vào Consul KV

```bash
kubectl port-forward -n consul svc/consul-server 8500:8500 &
cd /home/deploy/techinsight/k8s/consul
CONSUL_HTTP_ADDR=http://127.0.0.1:8500 ./load-config-into-consul.sh
```

### 3. Đảm bảo Vault đã sẵn sàng

- Vault đã cài (Helm), unseal, bật KV và Kubernetes auth.
- Đã chạy `vault/setup-policies-roles.sh` và `vault/populate-secrets.sh`.

Chi tiết: [VAULT_CONSUL_SETUP.md](VAULT_CONSUL_SETUP.md)

### 4. Restart các deployment

```bash
kubectl -n techinsight rollout restart deployment be-api-service be-auth-service be-worker-service
kubectl -n techinsight get pods -w
```

---

## Không truy cập được Consul UI (404 / ring-balancer)

**Nguyên nhân:** Ingress (Kong) đã trỏ host `consul.techinsightsworld.com` vào service Consul, nhưng **Consul chưa được cài** trong cluster → Kong không có backend → lỗi "failure to get a peer from the ring-balancer" hoặc 502/503.

**Cách xử lý:** Cài Consul theo bước 1 ở trên. Sau khi pod `consul-server` Running, truy cập lại qua Kong (vd. http://consul.techinsightsworld.com:30080) hoặc port-forward:

```bash
kubectl port-forward -n consul svc/consul-server 8500:8500
# Mở http://localhost:8500
```
