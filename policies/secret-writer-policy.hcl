path "secret/metadata/*" {
  capabilities = ["list"]
}

path "secret/data/demo" {
  capabilities = ["create", "update", "read"]
}

###

path "kv/metadata/*" {
  capabilities = ["list"]
}

path "kv/data/ct_key" {
  capabilities = ["create", "update", "read", "list"]
}
