# Overview

A basic setup of a single vault server and a single node kubernetes server to learn how vault secret storage and retrieval works.

# Initial setup of Vault and Kubernetes (minikube)

    vault server -dev -dev-listen-address=0.0.0.0:8200 --dev-root-token-id=root
    export VAULT_ADDR='http://127.0.0.1:8200'
    vault login token=root
    vault auth enable kubernetes
    vault secrets enable -version=2 kv
    minikube start

https://www.vaultproject.io/docs/auth/kubernetes.html

    kubectl create serviceaccount vault-tokenreview
    kubectl create serviceaccount phil
    kubectl create serviceaccount phil-secret-writer
    kubectl apply -f vault-binding.yml

### Gather a token from the kubernetes token reviewer API and extract the JWT which will be used to authenticate with Vault

    KUBE_TOKEN="$(kubectl get secrets | grep vault-tokenreview | awk '{print $1}')"
    JWT="$(kubectl get secret ${KUBE_TOKEN} -o jsonpath='{.data.token}' | base64 -d | tr -d '\n')"
    K8S_HOST="$(echo -n 'https://'; minikube ip | tr -d '\n'; echo ':8443')"

    vault write auth/kubernetes/config \
        token_reviewer_jwt="${JWT}" \
        kubernetes_host="${K8S_HOST}" \
        kubernetes_ca_cert=@/home/phil/.minikube/ca.crt

### Create policies for a "reader" container and a "writer" container

    vault write sys/policy/demo-policy policy=@policies/demo-policy.hcl
    vault write sys/policy/secret-writer-policy policy=@policies/secret-writer-policy.hcl

### Bind a kubernetes role to a vault role and policy

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

### Show vault role output to verify that the specified policies have been applied

    vault read auth/kubernetes/role/demo-role
    vault read auth/kubernetes/role/secret-writer-role

### Write a new secret from a different client container

    kubectl apply -f secret-writer.yml

### Read the secrets from a client container

    kubectl apply -f secret-reader.yml


# Music
[The Dualers - Treasure](https://www.youtube.com/watch?v=xxaazr4zlmU)
