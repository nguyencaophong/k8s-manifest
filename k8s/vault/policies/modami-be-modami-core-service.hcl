# Policy cho be-modami-core-service. Thêm vào Vault hiện có của techinsight.
path "secret/data/modami/be-modami-core-service" {
  capabilities = ["read"]
}
path "secret/metadata/modami/be-modami-core-service" {
  capabilities = ["read"]
}
