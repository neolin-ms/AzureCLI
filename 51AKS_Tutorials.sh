#!/bin/bash

#References
## 1, https://docs.microsoft.com/en-us/azure/aks/tutorial-kubernetes-prepare-app
## 2, https://docs.microsoft.com/en-us/azure/aks/tutorial-kubernetes-prepare-acr?tabs=azure-cli
## 3, https://docs.microsoft.com/en-us/azure/aks/tutorial-kubernetes-deploy-cluster?tabs=azure-cli
## 4, https://docs.microsoft.com/en-us/azure/aks/tutorial-kubernetes-deploy-cluster?tabs=azure-cli

# 1.1 Get application code
git clone https://github.com/Azure-Samples/azure-voting-app-redis.git
cd azure-voting-app-redis
tree

# 1.2 Create container images
docker-compose up -d
docker images
docker ps

# 1.3 Clean up resources
docker-compose down

# 2.1 Create an Azure Container Registry

rgname=myResourceGroup
az group create --name ${rgname} --location eastus

acrName=mytestacr1130
az acr create --resource-group ${rgname} --name ${acrName} --sku Basic

# 2.2 Log in to the container registry

az acr login --name ${acrName}

# 2.3 Tag a container image

docker images

az acr list --resource-group ${rgname} --query "[].{acrLoginServer:loginServer}" --output table

mytestacr1130.azurecr.io

docker tag mcr.microsoft.com/azuredocs/azure-vote-front:v1 mytestacr1130.azurecr.io/azure-vote-front:v1

# 2.4 Push images to registry

docker push mytestacr1130.azurecr.io/azure-vote-front:v1

# 2.5 List images in registry

az acr repository list --name ${acrName} --output table

az acr repository show-tags --name ${acrName} --repository azure-vote-front --output table

# 3.1 Create a Kubernetes cluster
