eferences
## https://docs.microsoft.com/en-us/azure/aks/tutorial-kubernetes-prepare-acr?tabs=azure-cli
## https://docs.microsoft.com/en-us/azure/aks/tutorial-kubernetes-deploy-cluster?tabs=azure-cli

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
