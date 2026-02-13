# Không còn root token từ lần init

## Bạn có 1 unseal key (từ lần `vault operator init`)?

- **Có** → Chạy script tạo root token mới (không mất dữ liệu trong Vault):

  ```bash
  chmod +x k8s/vault/generate-root-token.sh
  ./k8s/vault/generate-root-token.sh
  ```

  Khi được hỏi **Unseal Key**, dán 1 unseal key rồi Enter. Token in ra là root token mới; lưu lại và dùng để login / chạy `populate-secrets.sh`, `setup-policies-roles.sh`.

- **Không** (mất cả token và unseal key) → Không thể unlock Vault hiện tại. Chỉ còn cách **reset Vault từ đầu** (xóa data, init lại). Dùng script bên dưới.

---

## Reset Vault từ đầu (tạo mới key + token)

**Cách nhanh: dùng script (xóa data, sau đó bạn init/unseal tay)**

```bash
chmod +x k8s/vault/reset-vault-from-scratch.sh
./k8s/vault/reset-vault-from-scratch.sh
```

Gõ `yes` khi được hỏi. Script sẽ: xóa pod vault-0 → xóa PVC `data-vault-0` → chờ pod mới chạy (volume trống). Sau đó **bạn làm tay** theo hướng dẫn in ra:

1. **Init** (chạy 1 lần, **lưu ngay** Unseal Key và Initial Root Token):
   ```bash
   kubectl exec -n vault -it vault-0 -- vault operator init
   ```

2. **Unseal** (chỉ cần 1 key):
   ```bash
   kubectl exec -n vault -it vault-0 -- vault operator unseal <Unseal_Key_1>
   ```

3. **Bật KV + Kubernetes auth** (xem chi tiết `k8s/vault/README.md` và `k8s/docs/VAULT_CONSUL_SETUP.md`), rồi:
   ```bash
   cd k8s/vault && ./setup-policies-roles.sh && ./populate-secrets.sh
   ```
   (Cần `VAULT_ADDR` và `VAULT_TOKEN`; có thể login trong pod: `kubectl exec -n vault -it vault-0 -- vault login <token>`.)

Sau đó nhớ **backup** root token và 1 unseal key (password manager hoặc safe của team).
