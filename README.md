export VAULT_ROOT_TOKEN="root"
vault server -dev -dev-listen-address=0.0.0.0:8200 --dev-root-token-id="${VAULT_ROOT_TOKEN}"

export VAULT_ADDR='http://127.0.0.1:8200'
vault login token=root
vault auth enable kubernetes
vault secrets enable -version=2 kv

minikube start

# https://www.vaultproject.io/docs/auth/kubernetes.html
kubectl create serviceaccount vault-tokenreview
kubectl create serviceaccount phil
kubectl create serviceaccount phil-secret-writer
kubectl apply -f vault-binding.yml

VTKN="$(kubectl get secrets | grep vault-tokenreview | awk '{print $1}')"
JWT="$(kubectl get secret ${VTKN} -o jsonpath='{.data.token}' | base64 -d | tr -d '\n')"
K8S_HOST="$(echo -n 'https://'; minikube ip | tr -d '\n'; echo ':8443')"

vault write auth/kubernetes/config \
    token_reviewer_jwt="${JWT}" \
    kubernetes_host="${K8S_HOST}" \
    kubernetes_ca_cert=@/home/phil/.minikube/ca.crt

# Create policies
vault write sys/policy/demo-policy policy=@policies/demo-policy.hcl
vault write sys/policy/secret-writer-policy policy=@policies/secret-writer-policy.hcl

# Bind a kubernetes role to a vault role and policy
vault write auth/kubernetes/role/demo-role \
    bound_service_account_names=phil \
    bound_service_account_namespaces=default \
    policies=demo-policy \
    ttl=1h

vault write auth/kubernetes/role/secret-writer-role \
    bound_service_account_names=phil-secret-writer \
    bound_service_account_namespaces=default \
    policies=secret-writer-policy \
    ttl=1h

# Show vault role output to verify that the specified policies have been applied
vault read auth/kubernetes/role/demo-role
vault read auth/kubernetes/role/secret-writer-role

# Put arbitrary data into a secrets engine from your current machine
vault kv put kv/demo phil=hungry foo=bar

# Read the secrets from a client container
kubectl run --image=fedora --serviceaccount=phil --restart=Never fedora -- sh -c 'while true; do sleep 300; done'
kubectl exec -it fedora -- /bin/bash
dnf install -y curl jq
export VAULT_TOKEN=$(curl -sk -XPOST -d "{\"jwt\": \"$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)\", \"role\": \"demo-role\"}" http://192.168.1.142:8200/v1/auth/kubernetes/login | jq -r '.auth.client_token')
curl -s -H "X-Vault-Token: ${VAULT_TOKEN}" http://192.168.1.142:8200/v1/kv/data/demo | jq -r '.data.data'

# Write a new secret from a different client container
kubectl run --image=centos --serviceaccount=phil-secret-writer --restart=Never centos -- sh -c 'while true; do sleep 300; done'
kubectl exec -it centos -- /bin/bash
yum install -y curl wget epel-release unzip
yum install -y jq
wget https://releases.hashicorp.com/vault/1.1.0/vault_1.1.0_linux_amd64.zip
unzip vault_1.1.0_linux_amd64.zip && rm -f vault_1.1.0_linux_amd64.zip && mv vault /bin/vault
export VAULT_TOKEN=$(curl -sk -XPOST -d "{\"jwt\": \"$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)\", \"role\": \"secret-writer-role\"}" http://192.168.1.142:8200/v1/auth/kubernetes/login | jq -r '.auth.client_token')
export VAULT_ADDR='http://192.168.1.142:8200'
vault kv put kv/demo phil=hungry
vault kv patch kv/demo phil=hungry cats=also_hungry

### This is having some sort of issue https://github.com/hashicorp/vault/pull/5935
### Instead we'll use the vault binary
#curl -s -H "X-Vault-Token: ${VAULT_TOKEN}" -X POST -d "{\"phil\": \"hungry\", \"foo\": \"bar\", \"shopping_cart\": \"full of cats\"}" http://192.168.1.142:8200/v1/kv/data/demo
