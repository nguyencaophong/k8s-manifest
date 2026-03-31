# Policy cho be-modami-user-service. Thêm vào Vault hiện có của techinsight.
path "secret/data/modami/be-modami-user-service" {
  capabilities = ["read"]
}
path "secret/metadata/modami/be-modami-user-service" {
  capabilities = ["read"]
}
