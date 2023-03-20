#!/bin/bash

## References
## Tutorial: Deploy and use Azure Container Registry
## https://learn.microsoft.com/en-us/azure/aks/tutorial-kubernetes-prepare-acr?tabs=azure-cli
## Tutorial: Deploy an Azure Kubernetes Service (AKS) cluster
## https://learn.microsoft.com/en-us/azure/aks/tutorial-kubernetes-deploy-cluster?tabs=azure-cli
## Create an ingress controller in Azure Kubernetes Service (AKS)
## https://learn.microsoft.com/en-us/azure/aks/ingress-basic?tabs=azure-cli
## Create a gRPC service by Ingress Controller
## https://help.aliyun.com/document_detail/313328.html
## Test the connection
## https://github.com/fullstorydev/grpcurl
## test

## 1. Create ACR
az group create --name testResourceGroup --location eastasia

az acr create --resource-group testResourceGroup --name acr221108 --sku Basic

az acr login --name acr221108

docker tag myacr0621.azurecr.io/aci-tutorial-app:v1 acr221108.azurecr.io/aci-tutorial-app:v1

docker push acr221108.azurecr.io/aci-tutorial-app:v1

az acr repository list --name acr221108 --output table

## 2. Create an AKS cluster with ACR
az aks create \
    --resource-group testResourceGroup \
    --name testAKSCluster \
    --node-count 3 \
    --generate-ssh-keys \
    --attach-acr acr221108

az aks get-credentials --resource-group testResourceGroup --name testAKSCluster

## 3. Create NGINX Ingress Controller on AKS cluster
REGISTRY_NAME=acr221108
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

helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
ACR_URL="acr221108.azurecr.io"

helm install nginx-ingress ingress-nginx/ingress-nginx \
    --version 4.1.3 \
    --namespace ingress-basic \
    --create-namespace \
    --set controller.ingressClassResource.name=nginx-ingress \
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

kubectl get pod,svc,ingress -n ingress-basic

## 4. Create a gRPC service by Ingress Controller

### Step 1.1 Apply for an SSL certificate
vi /tmp/openssl.cnf

### Step 1.2 Execute the following command to sign the certificate request
openssl req -new -nodes -keyout grpc.key -out grpc.csr -config /tmp/openssl.cnf -subj "/C=CN/ST=Zhejiang/L=Hangzhou/O=AlibabaCloud/OU=ContainerService/CN=grpc.example.com"

### Step 1.3 Execute the following command to sign the certificate
openssl x509 -req -days 3650 -in grpc.csr -signkey grpc.key -out grpc.crt -extensions v3_req -extfile /tmp/openssl.cnf

### Step 1.4 Execute the following command to add the TLS Secret named grpc-secret to the cluster
kubectl create secret tls grpc-secret --key grpc.key --cert grpc.crt -n ingress-basic
kubectl get secret -n ingress-basic

### Step 2.1 Resources required to create a gRPC service
kubectl apply -f grpc-service.yaml -n ingress-basic

### Step 2.2 Check the pod, svc, ingress
kubectl get pod,svc,ingress -n ingress-basic

### Step 3. Create an Ingress route rule
kubectl apply -f grpc-ingress.yaml -n ingress-basic

## 5. Test the connection
docker pull fullstorydev/grpcurl:latest
docker run fullstorydev/grpcurl -insecure -authority grpc.example.com 20.24.115.83:443 list
