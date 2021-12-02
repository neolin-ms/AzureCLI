#!/bin/bash

#References
## 1, https://docs.microsoft.com/en-us/azure/aks/tutorial-kubernetes-prepare-app
## 2, https://docs.microsoft.com/en-us/azure/aks/tutorial-kubernetes-prepare-acr?tabs=azure-cli
## 3, https://docs.microsoft.com/en-us/azure/aks/tutorial-kubernetes-deploy-cluster?tabs=azure-cli
## 4, https://docs.microsoft.com/en-us/azure/aks/tutorial-kubernetes-deploy-cluster?tabs=azure-cli
## 5, https://docs.microsoft.com/en-us/azure/aks/tutorial-kubernetes-scale?tabs=azure-cli

# 1.1 Get application code
git clone https://github.com/Azure-Samples/azure-voting-app-redis.git
cd azure-voting-app-redis
tree

# 1.2 Create container images
docker-compose up -d
docker images
docker ps
curl http://localhost:8080

# 1.3 Clean up resources
docker-compose down

# 2.1 Create an Azure Container Registry

rgName=myResourceGroup
regionName=eastus
az group create --name ${rgName} --location ${regionName}

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
##Example commandes: $ echo '<Access-Token>' | sudo docker login neomyacrtest.azurecr.io --username 00000000-0000-0000-0000-000000000000 --password-stdin 

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
aksName=myAKSCluster
az aks create \
    --resource-group ${rgName} \
    --name ${aksName} \
    --node-count 2 \
    --generate-ssh-keys \

az aks update -n ${aksName} -g ${rgName} --attach-acr ${acrName}

# 3.2 Install the Kubernetes CLI
az aks install-cli

# 3.3 Connect to cluster using kubectl
az aks get-credentials --resource-group ${rgName} --name ${aksName}

# 3.4 Verify the connection to your cluster
kubectl get nodes -o wide
kubectl get pods -n kube-system -o wide

# 4.1 Update the manifest file
az acr list --resource-group ${rgName} --query "[].{acrLoginServer:loginServer}" --output table

neomyacrlab.azurecr.io

vi azure-vote-all-in-one-redis.yaml
## containers:
## - name: azure-vote-front
  image: <acrName>.azurecr.io/azure-vote-front:v1

# 4.1 Deploy the application
kubectl apply -f azure-vote-all-in-one-redis.yaml

# 4.1 Test the application
kubectl get service azure-vote-front --watch 

# 5.1 Manually scale pods
kubectl get pods -n wide

kubectl scale --replicas=5 deployment/azure-vote-front

kubectl get pods -n wide

# 5.2 Autoscale pods
z aks show --resource-group ${rgName} --name ${aksName} --query kubernetesVersion --output table
