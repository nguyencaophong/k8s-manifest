# Argo CD – Visualize & quản lý TechInsight trên K8s

Argo CD cung cấp UI để xem pods, deployments, services và sync ứng dụng từ Git (GitOps).

## 1. Cài đặt Argo CD lên cluster

Chạy một lần (cần `kubectl` trỏ đúng cluster):

```bash
cd /home/deploy/techinsight/k8s/argocd
./install-argocd.sh
```

Hoặc thủ công:

```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

Đợi vài phút cho Argo CD chạy xong:

```bash
kubectl -n argocd get pods -w
# Thoát khi tất cả Running (Ctrl+C)
```

## 2. Lấy mật khẩu đăng nhập UI

User mặc định: `admin`. Mật khẩu lấy từ secret:

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d
echo
```

## 3. Truy cập Argo CD UI

**Cách 1 – Port forward (nhanh, không cần Ingress):**

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

Mở trình duyệt: **https://localhost:8080** (chấp nhận cảnh báo SSL, đăng nhập `admin` + password ở bước 2).

**Cách 2 – Ingress (Kong / IngressController):**

Tạo Ingress cho `argocd-server` (ví dụ host `argocd.techinsightsworld.com`) nếu bạn dùng Kong hoặc Ingress khác.

## 4. Thêm TechInsight vào Argo CD (GitOps)

Sau khi repo TechInsight đã được đẩy lên Git (GitHub/GitLab/…):

1. Sửa `techinsight-application.yaml`: đặt `spec.source.repoURL` đúng URL repo của bạn (ví dụ `https://github.com/YOUR_ORG/techinsight.git`).
2. Apply Application:

```bash
kubectl apply -f k8s/argocd/techinsight-application.yaml
```

3. Vào Argo CD UI → ứng dụng **techinsight** → xem topology (pods, deployments, services). Có thể bấm **Sync** để đồng bộ từ Git.

**Repo private (lỗi "authentication required" / "Repository not found"):** Cần thêm credential cho Argo CD.

### Repo private – Thêm credential

**Cách 1 – Qua UI:** Settings → Repositories → Connect Repo → VIA HTTPS: điền Repository URL, Username (GitHub user), Password (dùng **Personal Access Token**, không dùng mật khẩu GitHub). Làm cho từng repo hoặc dùng token có quyền nhiều repo.

**Cách 2 – Qua Secret (kubectl):** Dùng file mẫu `repo-credentials-secret.yaml.example` → đổi tên thành `repo-credentials-secret.yaml`, thay `YOUR_GITHUB_USERNAME` và `YOUR_GITHUB_PAT`, rồi `kubectl apply -f repo-credentials-secret.yaml`. Tạo PAT tại GitHub: Settings → Developer settings → Personal access tokens (scope **repo**).

## 5. Chỉ visualize (không dùng Git)

Nếu bạn chỉ muốn xem pods trong cluster mà **không** dùng Git làm nguồn:

- Argo CD vẫn cần một Application. Có thể tạo Application **type: Directory** trỏ repo bất kỳ có chứa thư mục `k8s` (hoặc dùng repo mẫu).
- Hoặc dùng **Argo CD “in-cluster”**: sau khi cài Argo CD, vào UI → **+ NEW APP** → chọn **Edit as YAML** và tạo Application trỏ repo + path `k8s` của bạn.

Sau khi Application được tạo và sync (ít nhất một lần), toàn bộ resource trong namespace `techinsight` (pods, deployments, services) sẽ hiển thị trên UI.
