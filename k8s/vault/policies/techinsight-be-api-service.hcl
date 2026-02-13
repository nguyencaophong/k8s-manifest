# Policy for be-api-service. Read own secrets + shared db credentials.
path "secret/data/techinsight/be-api-service" {
  capabilities = ["read"]
}
path "secret/metadata/techinsight/be-api-service" {
  capabilities = ["read"]
}
path "secret/data/techinsight/db" {
  capabilities = ["read"]
}
path "secret/metadata/techinsight/db" {
  capabilities = ["read"]
}