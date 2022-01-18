#!/bin/bash

# Create a new AKS cluster with ACR integration 
# https://docs.microsoft.com/en-us/azure/aks/cluster-container-registry-integration?tabs=azure-cli#create-a-new-aks-cluster-with-acr-integration

## set this to the name of your Azure Container Registry.  It must be globally unique
MYACR=testmyacr0117

## Create a resource group
az group create --name myResourceGroup --location eastus

## Run the following line to create an Azure Container Registry if you do not already have one
az acr create -n $MYACR -g myResourceGroup --sku basic

## Create an AKS cluster with ACR integration
az aks create -n myAKSCluster \
  --resource-group myResourceGroup \
  --node-count 2 \
  --generate-ssh-keys --attach-acr $MYACR

## Connect to cluster using kubectl
az aks get-credentials --resource-group myResourceGroup --name myAKSCluster
kubectl get nodes -o wide

# Use TLS with your own certificates (https://docs.microsoft.com/en-us/azure/aks/ingress-own-tls?tabs=azure-cli)

## Import the images used by the Helm chart into your ACR
REGISTRY_NAME=testmyacr0117
SOURCE_REGISTRY=k8s.gcr.io
CONTROLLER_IMAGE=ingress-nginx/controller
CONTROLLER_TAG=v1.0.4
PATCH_IMAGE=ingress-nginx/kube-webhook-certgen
PATCH_TAG=v1.1.1
DEFAULTBACKEND_IMAGE=defaultbackend-amd64
DEFAULTBACKEND_TAG=1.5

az acr import --name $REGISTRY_NAME --source $SOURCE_REGISTRY/$CONTROLLER_IMAGE:$CONTROLLER_TAG --image $CONTROLLER_IMAGE:$CONTROLLER_TAG
az acr import --name $REGISTRY_NAME --source $SOURCE_REGISTRY/$PATCH_IMAGE:$PATCH_TAG --image $PATCH_IMAGE:$PATCH_TAG
az acr import --name $REGISTRY_NAME --source $SOURCE_REGISTRY/$DEFAULTBACKEND_IMAGE:$DEFAULTBACKEND_TAG --image $DEFAULTBACKEND_IMAGE:$DEFAULTBACKEND_TAG

# List container images (https://docs.microsoft.com/en-us/azure/container-registry/container-registry-get-started-azure-cli#list-container-images)
## Get the login server address
az acr list --resource-group myResourceGroup --query "[].{acrLoginServer:loginServer}" --output table

## List images in registry
az acr repository list --name $MYACR --output table

# Create an ingress controller

## Add the ingress-nginx repository
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx

## Set variable for ACR location to use for pulling images
ACR_URL=testmyacr0117.azurecr.io

## Use Helm to deploy an NGINX ingress controller
helm install nginx-ingress ingress-nginx/ingress-nginx \
    --version 4.0.13 \
    --namespace dotapi --create-namespace \
    --set controller.replicaCount=2 \
    --set controller.nodeSelector."kubernetes\.io/os"=linux \
    --set controller.image.registry=$ACR_URL \
    --set controller.image.image=$CONTROLLER_IMAGE \
    --set controller.image.tag=$CONTROLLER_TAG \
    --set controller.image.digest="" \
    --set controller.admissionWebhooks.patch.nodeSelector."kubernetes\.io/os"=linux \
    --set controller.admissionWebhooks.patch.image.registry=$ACR_URL \
    --set controller.admissionWebhooks.patch.image.image=$PATCH_IMAGE \
    --set controller.admissionWebhooks.patch.image.tag=$PATCH_TAG \
    --set controller.admissionWebhooks.patch.image.digest="" \
    --set defaultBackend.nodeSelector."kubernetes\.io/os"=linux \
    --set defaultBackend.image.registry=$ACR_URL \
    --set defaultBackend.image.image=$DEFAULTBACKEND_IMAGE \
    --set defaultBackend.image.tag=$DEFAULTBACKEND_TAG \
    --set defaultBackend.image.digest=""

# Create Kubernetes secret for the TLS certificate
kubectl create secret tls aks-ingress-tls \
    --namespace dotapi \
    --key aks-ingress-tls.key \
    --cert aks-ingress-tls.crt
	
kubectl get secret -n dotapi

###==Run only one demo application(https://docs.microsoft.com/en-us/azure/aks/ingress-own-tls?tabs=azure-cli#run-demo-applications)==##

#Run demo application 
kubectl apply -f aks-helloworld.yaml --namespace dotapi

# Create an ingress route for one demo application
kubectl apply -f hello-world-ingress-1.yaml --namespace dotapi

# Test the ingress configuration
curl -v -k --resolve demo.azure.com:443:52.224.145.250 https://demo.azure.com

###==Run two demo applications(https://docs.microsoft.com/en-us/azure/aks/ingress-own-tls?tabs=azure-cli#run-demo-applications)==##

# Run demo applications
kubectl apply -f aks-helloworld.yaml --namespace dotapi
kubectl apply -f ingress-demo.yaml --namespace dotapi	

kubectl get pods -n dotapi

# Create an ingress route
kubectl apply -f hello-world-ingress.yaml

# Test the ingress configuration
curl -v -k --resolve demo.azure.com:443:52.224.145.250 https://demo.azure.com

curl -v -k --resolve demo.azure.com:443:52.224.145.250 https://demo.azure.com/hello-world-two
