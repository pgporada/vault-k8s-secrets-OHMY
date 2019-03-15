# Overview

Install `minikube` and `kubectl`

    cd ../
    vagrant up
    cd minikube-manifests
    minikube start
    minikube addons enable ingress
    watch kubectl get pods -n kube-system

Troubleshooting

    kubectl run --image=fedora --restart=Never fedora -- sh -c 'while true; do sleep 300;done'
    kubectl exec -it fedora -- /bin/bash
    dnf install -y iputils telnet curl
    # Test connection to vault
    telnet ${LAPTOP_IP} 8200

- - - -
# References
https://www.google.com/search?client=firefox-b-1-d&q=kubernetes+vault+example

- - - -
# Music
[Lemon Demon - Cabinet Man (demo)](https://www.youtube.com/watch?v=b3sg_KRPQT4)
