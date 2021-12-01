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

rgName=myResourceGroup
az group create --name ${rgName} --location eastus

acrName=neomyacrtest
az acr create --resource-group ${rgName} --name ${acrName} --sku Basic

# 2.2 Log in to the container registry

az acr login --name ${acrName}

##2.2.1 When login acr, and get the error messages below, please check the link. 
##https://stackoverflow.com/questions/51222996/docker-login-fails-on-a-server-with-no-x11-installed
##Error Messages:
##You may want to use 'az acr login -n neomyacrtest --expose-token' to get an access token, which does not require Docker to be installed.
##An error occurred: DOCKER_COMMAND_ERROR
##Got permission denied while trying to connect to the Docker daemon socket at unix:///var/run/docker.sock: Get http://%2Fvar%2Frun%2Fdocker.sock/v1.24/containers/json: dial unix /var/run/docker.sock: connect: permission denied 

# 2.3 Tag a container image

docker images

az acr list --resource-group ${rgName} --query "[].{acrLoginServer:loginServer}" --output table

neomyacrtest.azurecr.io

docker tag mcr.microsoft.com/azuredocs/azure-vote-front:v1 neomyacrtest.azurecr.io/azure-vote-front:v1

# 2.4 Push images to registry

docker push neomyacrtest.azurecr.io/azure-vote-front:v1

# 2.5 List images in registry

az acr repository list --name ${acrName} --output table

az acr repository show-tags --name ${acrName} --repository azure-vote-front --output table

# 3.1 Create a Kubernetes cluster
