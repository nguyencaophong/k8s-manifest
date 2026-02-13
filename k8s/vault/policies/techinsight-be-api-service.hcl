# Policy for be-api-service. Kubernetes SA techinsight/be-api-service can read only this path.
path "secret/data/techinsight/be-api-service" {
  capabilities = ["read"]
}

path "secret/metadata/techinsight/be-api-service" {
  capabilities = ["read"]
}
