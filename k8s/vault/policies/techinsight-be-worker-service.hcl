# Policy for be-worker-service. Read only this service's secret (single path, least privilege).
path "secret/data/techinsight/be-worker-service" {
  capabilities = ["read"]
}
path "secret/metadata/techinsight/be-worker-service" {
  capabilities = ["read"]
}
