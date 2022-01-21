#!/bin/bash

# References
## kubectl Cheat Sheet, https://kubernetes.io/docs/reference/kubectl/cheatsheet/
## Step.1 Prepare application for AKS, https://docs.microsoft.com/en-us/azure/aks/tutorial-kubernetes-prepare-app
## Step.2 Create container registry, https://docs.microsoft.com/en-us/azure/aks/tutorial-kubernetes-prepare-acr?tabs=azure-cli
## Step.3 Create Kubernetes cluster, https://docs.microsoft.com/en-us/azure/aks/tutorial-kubernetes-deploy-cluster?tabs=azure-cli
## Step.4 Run application, https://docs.microsoft.com/en-us/azure/aks/tutorial-kubernetes-deploy-application?tabs=azure-cli 
## Step.5 Ingress Controller Add-on for AKS (Brownfield), https://docs.microsoft.com/en-us/azure/application-gateway/tutorial-ingress-controller-add-on-existing
## Step.5 Generate TLS certificates, https://docs.microsoft.com/en-us/azure/aks/ingress-own-tls#generate-tls-certificates
## Step.5 Expose an AKS service over HTTP or HTTPS using Application Gateway, https://docs.microsoft.com/en-us/azure/application-gateway/ingress-controller-expose-service-over-http-https

# Step.1 Prepare application for AKS
git clone https://github.com/Azure-Samples/azure-voting-app-redis.git
cd azure-voting-app-redis
docker-compose up -d
docker images
docker ps
docker-compose down

# Step.2 Create continer registry
az group create --name myResourceGroup --location eastus
az acr create --resource-group myResourceGroup --name neotestacr20211230 --sku Basic
az acr login --name neotestacr20211230
az acr list --resource-group myResourceGroup --query "[].{acrLoginServer:loginServer}" --output table
docker tag mcr.microsoft.com/azuredocs/azure-vote-front:v1 neotestacr20211230.azurecr.io/azure-vote-front:v1
docker images
docker push neotestacr20211230.azurecr.io/azure-vote-front:v1
az acr repository list --name neotestacr20211230 --output table
az acr repository show-tags --name neotestacr20211230 --repository azure-vote-front --output table

# Step.3 Create Kubernetes cluster
az aks create \
    --resource-group myResourceGroup \
    --name myAKSCluster \
    --node-count 2 \
    --generate-ssh-keys \
    --attach-acr neotestacr20211230
az aks install-cli
az aks get-credentials --resource-group myResourceGroup --name myAKSCluster
kubectl get nodes

# Step.4 Run application (for test)
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

# Step.5 Ingress Controller Add-on for AKS (Brownfield)

## Step.5.1 Deploy a new Application Gateway
az network public-ip create -n myPublicIp -g myResourceGroup --allocation-method Static --sku Standard
az network vnet create -n myVnet -g myResourceGroup --address-prefix 11.0.0.0/8 --subnet-name mySubnet --subnet-prefix 11.1.0.0/16 
az network application-gateway create -n myApplicationGateway -l eastus -g myResourceGroup --sku Standard_v2 --public-ip-address myPublicIp --vnet-name myVnet --subnet mySubnet

## Step.5.2 Enable the AGIC add-on in existing AKS cluster through Azure CLI
appgwId=$(az network application-gateway show -n myApplicationGateway -g myResourceGroup -o tsv --query "id") 
az aks enable-addons -n myAKSCluster -g myResourceGroup -a ingress-appgw --appgw-id $appgwId

## Step.5.3 Peer the two virtual networks together
nodeResourceGroup=$(az aks show -n myAKSCluster -g myResourceGroup -o tsv --query "nodeResourceGroup")
aksVnetName=$(az network vnet list -g $nodeResourceGroup -o tsv --query "[0].name")
aksVnetId=$(az network vnet show -n $aksVnetName -g $nodeResourceGroup -o tsv --query "id")
az network vnet peering create -n AppGWtoAKSVnetPeering -g myResourceGroup --vnet-name myVnet --remote-vnet $aksVnetId --allow-vnet-access
appGWVnetId=$(az network vnet show -n myVnet -g myResourceGroup -o tsv --query "id")
az network vnet peering create -n AKStoAppGWVnetPeering -g $nodeResourceGroup --vnet-name $aksVnetName --remote-vnet $appGWVnetId --allow-vnet-access

## Step.5.4 Deploy a sample application using AGIC for test
kubectl apply -f https://raw.githubusercontent.com/Azure/application-gateway-kubernetes-ingress/master/docs/examples/aspnetapp.yaml
kubectl get ingress
kubectl delete -f https://raw.githubusercontent.com/Azure/application-gateway-kubernetes-ingress/master/docs/examples/aspnetapp.yaml

## Step.5.5 Generate TLS certificates (or check references 6 for more details), and expose an AKS service over HTTPS using Application Gateway (or check references 7 for more details)
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -out aks-ingress-tls.crt \
    -keyout aks-ingress-tls.key \
    -subj "/CN=demo.azure.com/O=aks-ingress-tls"

kubectl create secret tls aks-ingress-tls \
    --key aks-ingress-tls.key \
    --cert aks-ingress-tls.crt

kubectl get secrets

curl https://raw.githubusercontent.com/Azure/application-gateway-kubernetes-ingress/master/docs/examples/aspnetapp.yaml

mv aspnetapp.yaml aspnetapptls.yaml

vi aspnetapptls.yaml
>> metadata:
>>   name: aspnetapp
>>   annotations:
>>     kubernetes.io/ingress.class: azure/application-gateway
>> spec:
>>   tls:
>>     - secretName: aks-ingress-tls
>>   rules:
>>   - http:
>>       paths:
>>       - path: /
>>         backend:
>>           service:
>>             name: aspnetapp
>>             port:
>>               number: 80
>>         pathType: Prefix

kubectl apply -f aspnetapptls.yaml

>> Open the browser and enter the ingress public IP address

kubectl delete -f aspnetapptls.yaml
