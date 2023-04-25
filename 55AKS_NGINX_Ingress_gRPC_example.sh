#!/bin/bash

## References
## Tutorial: Deploy and use Azure Container Registry
## https://learn.microsoft.com/en-us/azure/aks/tutorial-kubernetes-prepare-acr?tabs=azure-cli
## Tutorial: Deploy an Azure Kubernetes Service (AKS) cluster
## https://learn.microsoft.com/en-us/azure/aks/tutorial-kubernetes-deploy-cluster?tabs=azure-cli
## Create an ingress controller in Azure Kubernetes Service (AKS)
## https://learn.microsoft.com/en-us/azure/aks/ingress-basic?tabs=azure-cli
## kubernetes/ingress-nsing - gRPC
## https://kubernetes.github.io/ingress-nginx/examples/grpc/
## Create TLS certificate
## https://github.com/MicrosoftDocs/azure-docs.zh-tw/blob/master/articles/aks/ingress-own-tls.md
## Can't connect to pods and service in same cluster
## https://learn.microsoft.com/en-us/troubleshoot/azure/azure-kubernetes/troubleshoot-connection-pods-services-same-cluster
## Test the connection
## https://github.com/fullstorydev/grpcurl
## How to install the grpcurl binary on Linux?
## https://github.com/fullstorydev/grpcurl/issues/154

## 1. Create ACR
az group create --name testResourceGroup --location eastasia

az acr create --resource-group testResourceGroup --name myacr0308 --sku Basic

az acr login --name myacr0308

## 2. Build a gRPC service by Dockerfile and push to ACR

curl https://raw.githubusercontent.com/neolin-ms/example_Ingress_Nginx_gRPC/main/Dockerfile

docker build -t go-grpc-greeter-server:1.0.0 .

docker tag go-grpc-greeter-server:1.0.0 myacr0308.azurecr.io/go-grpc-greeter-server:1.0.0

docker push myacr0308.azurecr.io/go-grpc-greeter-server:1.0.0

az acr repository list --name myacr0308 --output table

## 3. Create an AKS cluster with ACR
az aks create \
    --resource-group testResourceGroup \
    --name testAKSCluster \
    --node-count 2 \
    --generate-ssh-keys \
    --attach-acr myacr0308

az aks get-credentials --resource-group testResourceGroup --name testAKSCluster

## 3. Create NGINX Ingress Controller on AKS cluster
REGISTRY_NAME=myacr0308
SOURCE_REGISTRY=registry.k8s.io
CONTROLLER_IMAGE=ingress-nginx/controller
CONTROLLER_TAG=v1.2.1
PATCH_IMAGE=ingress-nginx/kube-webhook-certgen
PATCH_TAG=v1.1.1
DEFAULTBACKEND_IMAGE=defaultbackend-amd64
DEFAULTBACKEND_TAG=1.5

az acr import --name $REGISTRY_NAME --source $SOURCE_REGISTRY/$CONTROLLER_IMAGE:$CONTROLLER_TAG --image $CONTROLLER_IMAGE:$CONTROLLER_TAG
az acr import --name $REGISTRY_NAME --source $SOURCE_REGISTRY/$PATCH_IMAGE:$PATCH_TAG --image $PATCH_IMAGE:$PATCH_TAG
az acr import --name $REGISTRY_NAME --source $SOURCE_REGISTRY/$DEFAULTBACKEND_IMAGE:$DEFAULTBACKEND_TAG --image $DEFAULTBACKEND_IMAGE:$DEFAULTBACKEND_TAG

helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx

ACR_URL="myacr0308.azurecr.io"

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

kubectl get pods,svc,ingress -n ingress-basic

## 4. Create a gRPC service by Ingress Controller

### Step 4.1 Create a TLS certificate
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -out aks-grpc-tls.crt \
    -keyout aks-grpc-tls.key \
    -subj "/CN=demo.azure.com/O=aks-grpc-tls" \
    -addext "subjectAltName = DNS:demo.azure.com"

### Step 4.2 Create a scret on kubernetes for TLS certificate
kubectl create secret tls aks-grpc-tls \
    --namespace ingress-basic \
    --key aks-grpc-tls.key \
    --cert aks-grpc-tls.crt

### Step 4.3 Creae pod and service for gRPC service
kubectl apply -f https://raw.githubusercontent.com/neolin-ms/example_Ingress_Nginx_gRPC/main/go-grpc-greeter-server_Pod_Service.yaml -n ingress-basic

### Step 4.4 Check the pod, svc, ingress
kubectl apply -f https://raw.githubusercontent.com/neolin-ms/example_Ingress_Nginx_gRPC/main/go-grpc-greeter-server_Ingress_Route.yaml -n ingress-basic

## Step 4.5 Check the pod/service/ingress of gRPC service
kubectl get pod,svc,ingress -n ingress-basic

## 5. Test the connection
kubectl run -it aks-ssh --namespace ingress-basic --image=debian:stable
apt-get update -y
apt-get install dnsutils -y
apt-get install curl -y
apt-get install netcat -y
apt install vim -y

kubectl cp aks-grpc-tls.crt aks-ssh:/tmp/

scp aks-grpc-tls.crt azureuser@<PUBLIC_IP>:/tmp/.
cp aks-grpc-tls.crt /usr/local/share/ca-certificates/.
sudo update-ca-certificates

curl -sSL "https://github.com/fullstorydev/grpcurl/releases/download/v1.8.7/grpcurl_1.8.7_linux_x86_64.tar.gz" | sudo tar -xz -C /usr/local/bin
grpcurl -h

grpcurl demo.azure.com:443 helloworld.Greeter/SayHello
