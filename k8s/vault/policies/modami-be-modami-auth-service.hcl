# Policy cho be-modami-auth-service. Thêm vào Vault hiện có của techinsight.
path "secret/data/modami/be-modami-auth-service" {
  capabilities = ["read"]
}
path "secret/metadata/modami/be-modami-auth-service" {
  capabilities = ["read"]
}
