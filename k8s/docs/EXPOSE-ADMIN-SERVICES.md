# Truy cập Vault, Consul, Argo CD qua browser (IP 76.13.182.234)

Hai cách: **NodePort** (dùng IP + port) hoặc **Ingress** (dùng path hoặc hostname).

---

## Cách 1: NodePort (đơn giản, dùng IP)

Mỗi service lộ ra một port trên node. Truy cập: `http(s)://76.13.182.234:<PORT>`.

### Bước 1: Expose các service

Chạy script (hoặc từng lệnh bên dưới):

```bash
cd /home/deploy/techinsight/k8s
./expose-admin-services.sh
```

Hoặc thủ công:

```bash
# Argo CD (HTTPS) -> NodePort 30443
kubectl patch svc argocd-server -n argocd -p '{"spec":{"type":"NodePort","ports":[{"port":443,"nodePort":30443}]}}'

# Vault (HTTP) -> NodePort 30820
kubectl patch svc vault -n vault -p '{"spec":{"type":"NodePort","ports":[{"port":8200,"nodePort":30820}]}}'

# Consul UI (HTTP) -> NodePort 30850
kubectl patch svc consul-server -n consul -p '{"spec":{"type":"NodePort","ports":[{"name":"http","port":8500,"nodePort":30850}]}}'
```

**Lưu ý:** Tên service Vault/Consul có thể khác tùy Helm release (ví dụ `vault-active`, `consul-ui`). Nếu lỗi, kiểm tra:

```bash
kubectl -n vault get svc
kubectl -n consul get svc
```

### Bước 2: Mở firewall (trên máy 76.13.182.234)

```bash
# Nếu dùng ufw
sudo ufw allow 30443/tcp   # Argo CD
sudo ufw allow 30820/tcp   # Vault
sudo ufw allow 30850/tcp   # Consul
sudo ufw reload
```

### Bước 3: Truy cập trên browser

| Service   | URL                              | Ghi chú                    |
|----------|-----------------------------------|----------------------------|
| Argo CD  | **https://76.13.182.234:30443**   | Chấp nhận cảnh báo SSL     |
| Vault    | **http://76.13.182.234:30820**    | UI Vault                   |
| Consul   | **http://76.13.182.234:30850**    | UI Consul                  |

Mật khẩu Argo CD admin: `kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d`

---

## Cách 2: Ingress (Kong) – dùng hostname

Truy cập qua cùng port 80/443, Kong terminate TLS và route theo hostname:

- **https://argocd.techinsightsworld.com** → Argo CD  
- **https://vault.techinsightsworld.com** → Vault  
- **https://consul.techinsightsworld.com** → Consul  

### Điều kiện

- DNS: `argocd.techinsightsworld.com`, `vault.techinsightsworld.com`, `consul.techinsightsworld.com` trỏ A record về IP 76.13.182.234.
- Kong Ingress Controller đã cài trong cluster (vd. `ingressClassName: kong`).
- (Khuyến nghị) Cert-manager hoặc certificate để Kong phục vụ HTTPS.

### Bước 1: Cấu hình Argo CD chạy sau reverse proxy (HTTP)

Kong sẽ terminate TLS và forward **HTTP** tới Argo CD. Cần bật chế độ insecure cho Argo CD:

```bash
kubectl patch configmap argocd-cmd-params-cm -n argocd --type merge -p '{"data":{"server.insecure":"true"}}'
kubectl rollout restart deployment argocd-server -n argocd
```

Sau đó Argo CD phục vụ HTTP trên port **80**; Ingress trỏ backend vào port 80.

### Bước 2: TLS cho Kong (tùy chọn)

Nếu dùng **cert-manager** và cluster issuer, bỏ comment block `tls` trong `ingress-admin-services.yaml` (đã có sẵn trong file) rồi apply. Nếu chưa có cert-manager, truy cập tạm bằng **http://** (port 80) hoặc dùng certificate thủ công trong Kong.

### Bước 3: Apply Ingress

```bash
kubectl apply -f k8s/ingress-admin-services.yaml
```

### Bước 4: Truy cập

| Service   | URL (HTTPS)                              |
|-----------|------------------------------------------|
| Argo CD   | https://argocd.techinsightsworld.com     |
| Vault     | https://vault.techinsightsworld.com      |
| Consul    | https://consul.techinsightsworld.com     |

Nếu chưa cấu hình TLS tại Kong, dùng **http://** thay vì https.

### Chạy Argo CD dưới subpath (vd. /argocd)

Nếu muốn dùng một path chung (vd. `https://admin.techinsightsworld.com/argocd`) thay vì hostname riêng, cần thêm cấu hình rootpath cho Argo CD:

```bash
kubectl patch configmap argocd-cmd-params-cm -n argocd --type merge -p '{"data":{"server.rootpath":"/argocd","server.basehref":"/argocd"}}'
kubectl rollout restart deployment argocd-server -n argocd
```

Rồi tạo Ingress với `path: /argocd`, pathType Prefix; Kong strip-path tùy cách bạn cấu hình.

---

## Rollback (bỏ NodePort)

Để đưa service về ClusterIP:

```bash
kubectl patch svc argocd-server -n argocd -p '{"spec":{"type":"ClusterIP"}}'
kubectl patch svc vault -n vault -p '{"spec":{"type":"ClusterIP"}}'
kubectl patch svc consul-server -n consul -p '{"spec":{"type":"ClusterIP"}}'
```
