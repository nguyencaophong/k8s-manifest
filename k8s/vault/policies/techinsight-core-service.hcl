# Policy for core-service. Reads same secret path as legacy be-api-service (no re-populate needed).
path "secret/data/techinsight/be-api-service" {
  capabilities = ["read"]
}
path "secret/metadata/techinsight/be-api-service" {
  capabilities = ["read"]
}
