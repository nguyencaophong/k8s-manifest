# Policy for auth-service. Reads same secret path as legacy be-auth-service (no re-populate needed).
path "secret/data/techinsight/be-auth-service" {
  capabilities = ["read"]
}
path "secret/metadata/techinsight/be-auth-service" {
  capabilities = ["read"]
}
