path "secret/metadata/*" {
  capabilities = ["list"]
}

path "secret/data/demo/*" {
  capabilities = ["create", "update", "read"]
}

###

path "kv/metadata/*" {
  capabilities = ["list"]
}

path "kv/data/demo/*" {
  capabilities = ["create", "update", "read"]
}
