# Policy for centrifugo. Read centrifugo secrets from Vault.
path "secret/data/modami/centrifugo" {
  capabilities = ["read"]
}
path "secret/metadata/modami/centrifugo" {
  capabilities = ["read"]
}
