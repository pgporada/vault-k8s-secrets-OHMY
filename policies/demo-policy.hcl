# when you curl this secret, you DO NOT include /data in the path. /data is strictly a v2 secret thing
path "kv/data/demo" {
  capabilities = ["read"]
}
