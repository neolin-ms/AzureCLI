#!/bin/bash

## https://docs.microsoft.com/en-us/azure/aks/ingress-basic

# 0 Before you bgin
## 0.1 Helm3
## 0.2 AzureCLI version 2.0.64 or later
## 0.3 AKS Cluster and ACR

# 1. Basic configuration
nameSpace=ingress-basic


helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

helm install ingress-nginx ingress-nginx/ingress-nginx --create-namespace --namespace ${nameSpace}

# (Optional)2. Customized configuration

## 2.1 Import the images used by the Helm chart into your ACR
REGISTRY_NAME=<REGISTRY_NAME>
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

# 2.2 Create an ingress controller
## Add the ingress-nginx repository
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx

## Set variable for ACR location to use for pulling images
ACR_URL=<REGISTRY_URL>

## Use Helm to deploy an NGINX ingress controller
helm install nginx-ingress ingress-nginx/ingress-nginx \
    --namespace ingress-basic --create-namespace \
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

# 3 Check the load balancer service
kubectl --namespace ingress-basic get services -o wide -w ingress-nginx-controller

# 4 Run demo applications
nano aks-helloworld-one.yaml
nano aks-helloworld-.yaml

kubectl apply -f aks-helloworld-one.yaml --namespace ingress-basic
kubectl apply -f aks-helloworld-two.yaml --namespace ingress-basic 

# 5 Create an ingress route
nano hello-world-ingress.yaml

kubectl apply -f hello-world-ingress.yaml --namespace ingress-basic 

# 6 subscription-manager repos --enable=codeready-builder-for-rhel-8-x86_64-rpms

# 6.1 Delete the sample namespace and all resources
kubectl delete namespace ingress-basic

# 6.2 Delete resources individually
helm list --namespace ingress-basic

helm uninstall nginx-ingress --namespace ingress-basic

kubectl delete -f aks-helloworld-one.yaml --namespace ingress-basic
kubectl delete -f aks-helloworld-two.yaml --namespace ingress-basic

kubectl delete -f hello-world-ingress.yaml

kubectl delete namespace ingress-basic
