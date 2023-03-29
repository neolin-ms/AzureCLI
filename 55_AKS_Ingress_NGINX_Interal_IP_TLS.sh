#!/bin/bash

# References:
## Integrate ACR with an AKS cluster
## https://learn.microsoft.com/en-us/azure/aks/cluster-container-registry-integration?tabs=azure-cli
## Create an ingress cntroller in AKS
## https://learn.microsoft.com/en-us/azure/aks/ingress-basic?tabs=azure-cli
## Quickstart - Deploy an AKS using the Azure CLI
## https://learn.microsoft.com/en-us/azure/aks/learn/quick-kubernetes-deploy-cli
## Quick Tip - SSL Cert Expiry from K8s Secrets
## https://syvarth.com/post/ssl-cert-expiry-kubernetes-secret
## How to check TLS Cert Expiration Date
## https://managedkube.com/kubernetes/gitops/2018/09/20/kubernetes-kubectl-check-cert.html
## AKS and create TLS certificate
## https://github.com/MicrosoftDocs/azure-docs.zh-tw/blob/master/articles/aks/ingress-own-tls.md
## K8s - Ingress - TLS
## https://kubernetes.io/docs/concepts/services-networking/ingress/#tls
## How do I use SANs with openSSL instead of common name?
## https://stackoverflow.com/questions/64814173/how-do-i-use-sans-with-openssl-instead-of-common-name
## Curl - SSL certificate problem: self signed certificate
## https://ephrain.net/ubuntu-%E6%96%B0%E5%A2%9E-root-ca%EF%BC%8C%E8%A7%A3%E6%B1%BA-curl-%E5%87%BA%E7%8F%BE-unable-to-get-local-issuer-certificate-%E7%9A%84%E5%95%8F%E9%A1%8C/
## Linux - SCP
## https://blog.gtwang.org/linux/linux-scp-command-tutorial-examples/

# Step 1: Create a resource group
az group create -n testResourceGroup -l eastus

# Step 2: Create an ACR
az acr create -n testacr0329 -g testResourceGroup --sku basic

# Step 3: Create a new AKS cluster and integrate with an existing ACR
az aks create -n testAKSCluster -g testResourceGroup --node-count 2 --generate-ssh-keys --attach-acr testacr0329

# Step 4: Customized configuration - Ingress Controller - kubernetes/ingress-nginx

# Step 4.1: Import the images used by the Helm chart into ACR
REGISTRY_NAME=testacr0329
SOURCE_REGISTRY=k8s.gcr.io
CONTROLLER_IMAGE=ingress-nginx/controller
CONTROLLER_TAG=v1.2.1
PATCH_IMAGE=ingress-nginx/kube-webhook-certgen
PATCH_TAG=v1.1.1
DEFAULTBACKEND_IMAGE=defaultbackend-amd64
DEFAULTBACKEND_TAG=1.5

az acr import --name $REGISTRY_NAME --source $SOURCE_REGISTRY/$CONTROLLER_IMAGE:$CONTROLLER_TAG --image $CONTROLLER_IMAGE:$CONTROLLER_TAG
az acr import --name $REGISTRY_NAME --source $SOURCE_REGISTRY/$PATCH_IMAGE:$PATCH_TAG --image $PATCH_IMAGE:$PATCH_TAG
az acr import --name $REGISTRY_NAME --source $SOURCE_REGISTRY/$DEFAULTBACKEND_IMAGE:$DEFAULTBACKEND_TAG --image $DEFAULTBACKEND_IMAGE:$DEFAULTBACKEND_TAG

# Step 4.2: Create an ingress controller using an internal IP address
# Add the ingress-nginx repository
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx

# Set variable for ACR location to use for pulling images
ACR_URL="testacr0329.azurecr.io"

# Use Helm to deploy an NGINX ingress controller
helm install ingress-nginx ingress-nginx/ingress-nginx \
    --version 4.1.3 \
    --namespace ingress-basic \
    --create-namespace \
    --set controller.replicaCount=2 \
    --set controller.nodeSelector."kubernetes\.io/os"=linux \
    --set controller.image.registry=$ACR_URL \
    --set controller.image.image=$CONTROLLER_IMAGE \
    --set controller.image.tag=$CONTROLLER_TAG \
    --set controller.image.digest="" \
    --set controller.admissionWebhooks.patch.nodeSelector."kubernetes\.io/os"=linux \
    --set controller.service.loadBalancerIP=10.224.0.42 \
    --set controller.service.annotations."service\.beta\.kubernetes\.io/azure-load-balancer-internal"=true \
    --set controller.service.annotations."service\.beta\.kubernetes\.io/azure-load-balancer-health-probe-request-path"=/healthz \
    --set controller.admissionWebhooks.patch.image.registry=$ACR_URL \
    --set controller.admissionWebhooks.patch.image.image=$PATCH_IMAGE \
    --set controller.admissionWebhooks.patch.image.tag=$PATCH_TAG \
    --set controller.admissionWebhooks.patch.image.digest="" \
    --set defaultBackend.nodeSelector."kubernetes\.io/os"=linux \
    --set defaultBackend.image.registry=$ACR_URL \
    --set defaultBackend.image.image=$DEFAULTBACKEND_IMAGE \
    --set defaultBackend.image.tag=$DEFAULTBACKEND_TAG \
    --set defaultBackend.image.digest=""

# Check the load balancer service
kubectl get services --namespace ingress-basic -o wide -w ingress-nginx-controller

# Step 5: Run demo applications (pod, service)
kubectl apply -f aks-helloworld-one.yaml

# Step 6: Create a SSL/TLS certificate
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -out aks-ingress-tls.crt \
    -keyout aks-ingress-tls.key \
    -subj "/CN=demo.azure.com/O=aks-ingress-tls" \
    -addext "subjectAltName = DNS:demo.azure.com"

# Step 7: Create a TLS secret on cluster

# Step 7.1: Create TLS secret
kubectl create secret tls aks-ingress-tls \
    --key aks-ingress-tls.key \
    --cert aks-ingress-tls.crt
# Step 7.2: Check TLS Cert Expiration Date
kubectl get secret aks-ingress-tls -o "jsonpath={.data['tls\.crt']}" | base64 -d | openssl x509 -enddate -noout

# Step 8: Create an ingress route
# Step 8.1: Create a YAML and then deploy a ingres route
vi aks-helloworld-one-ingress-tls.yaml

apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: hello-world-ingress
  namespace: default
spec:
  ingressClassName: nginx
  rules:
    - host: demo.azure.com
      http:
        paths:
          - pathType: Prefix
            backend:
              service:
                name: aks-helloworld-one
                port:
                  number: 80
            path: /
  # This section is only required if TLS is to be enabled for the Ingress
  tls:
    - hosts:
      - demo.azure.com
      secretName: aks-ingress-tls

kubectl apply -f aks-helloworld-one-ingress-tls.yaml

# Step 8.2: Checked the pods, service, ingress
kubectl get pod,svc,ingress

# Step 9: Test an internal IP address

# Step 9.1: Copy certificate to client and update it to library of certificate.
scp aks-ingress-tls.crt azureuser@20.122.187.225:/tmp/.
cp aks-ingress-tls.crt /usr/local/share/ca-certificates/.
sudo update-ca-certificates

# Step 9.2: Install curl command on client and test connection.
sudo apt-get update && apt-get install curl -y
curl -L -v https://demo.azure.com
