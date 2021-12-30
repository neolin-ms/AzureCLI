#!/bin/bash

==Step.1 Prepare application for AKS (https://docs.microsoft.com/en-us/azure/aks/tutorial-kubernetes-prepare-app)

git clone https://github.com/Azure-Samples/azure-voting-app-redis.git

cd azure-voting-app-redis

docker-compose up -d

docker images
 
docker ps

docker-compose down

==Step.2 Create continer registry (https://docs.microsoft.com/en-us/azure/aks/tutorial-kubernetes-prepare-acr?tabs=azure-cli)

az group create --name myResourceGroup --location eastus

az acr create --resource-group myResourceGroup --name neotestacr20211230 --sku Basic

az acr login --name neotestacr20211230

az acr list --resource-group myResourceGroup --query "[].{acrLoginServer:loginServer}" --output table

docker tag mcr.microsoft.com/azuredocs/azure-vote-front:v1 neotestacr20211230.azurecr.io/azure-vote-front:v1

docker images

docker push neotestacr20211230.azurecr.io/azure-vote-front:v1

az acr repository list --name neotestacr20211230 --output table

az acr repository show-tags --name neotestacr20211230 --repository azure-vote-front --output table

==Step.3 Create Kubernetes cluster (https://docs.microsoft.com/en-us/azure/aks/tutorial-kubernetes-deploy-cluster?tabs=azure-cli)

az aks create \
    --resource-group myResourceGroup \
    --name myAKSCluster \
    --node-count 2 \
    --generate-ssh-keys \
    --attach-acr neotestacr20211230

az aks install-cli

az aks get-credentials --resource-group myResourceGroup --name myAKSCluster

kubectl get nodes

==Step.4 Run application (for test)

az acr list --resource-group myResourceGroup --query "[].{acrLoginServer:loginServer}" --output table

cd azure-voting-app-redis
vi azure-vote-all-in-one-redis.yaml

>> containers:
>> - name: azure-vote-front
>>   image: neotestacr20211230.azurecr.io/azure-vote-front:v1

kubectl apply -f azure-vote-all-in-one-redis.yaml

kubectl get service azure-vote-front --watch

>> open a web browser to the external IP address of your service

kubectl delete -f azure-vote-all-in-one-redis.yaml

==Step.5 Ingress Controller Add-on for AKS (Brownfield)(https://docs.microsoft.com/en-us/azure/application-gateway/tutorial-ingress-controller-add-on-existing)

Step.5.1 Deploy a new Application Gateway

az network public-ip create -n myPublicIp -g myResourceGroup --allocation-method Static --sku Standard
az network vnet create -n myVnet -g myResourceGroup --address-prefix 11.0.0.0/8 --subnet-name mySubnet --subnet-prefix 11.1.0.0/16 
az network application-gateway create -n myApplicationGateway -l eastus -g myResourceGroup --sku Standard_v2 --public-ip-address myPublicIp --vnet-name myVnet --subnet mySubnet

Step.5.2 Enable the AGIC add-on in existing AKS cluster through Azure CLI

appgwId=$(az network application-gateway show -n myApplicationGateway -g myResourceGroup -o tsv --query "id") 
az aks enable-addons -n myAKSCluster -g myResourceGroup -a ingress-appgw --appgw-id $appgwId

Step.5.3 Peer the two virtual networks together

nodeResourceGroup=$(az aks show -n myAKSCluster -g myResourceGroup -o tsv --query "nodeResourceGroup")
aksVnetName=$(az network vnet list -g $nodeResourceGroup -o tsv --query "[0].name")
aksVnetId=$(az network vnet show -n $aksVnetName -g $nodeResourceGroup -o tsv --query "id")

az network vnet peering create -n AppGWtoAKSVnetPeering -g myResourceGroup --vnet-name myVnet --remote-vnet $aksVnetId --allow-vnet-access

appGWVnetId=$(az network vnet show -n myVnet -g myResourceGroup -o tsv --query "id")
az network vnet peering create -n AKStoAppGWVnetPeering -g $nodeResourceGroup --vnet-name $aksVnetName --remote-vnet $appGWVnetId --allow-vnet-access

Step.5.4 Deploy a sample application using AGIC

kubectl apply -f https://raw.githubusercontent.com/Azure/application-gateway-kubernetes-ingress/master/docs/examples/aspnetapp.yaml

kubectl get ingress

kubectl delete -f https://raw.githubusercontent.com/Azure/application-gateway-kubernetes-ingress/master/docs/examples/aspnetapp.yaml
