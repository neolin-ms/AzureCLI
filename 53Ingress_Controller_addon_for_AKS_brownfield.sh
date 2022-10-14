#!/bin/bash
# https://learn.microsoft.com/en-us/azure/application-gateway/tutorial-ingress-controller-add-on-existing
# https://learn.microsoft.com/en-us/azure/aks/csi-secrets-store-nginx-tls#generate-a-tls-certificate
# https://azure.github.io/application-gateway-kubernetes-ingress/tutorials/tutorial.e2e-ssl/

az group create --name neoResourceGroup --location eastus

az aks create -n neoCluster -g neoResourceGroup --network-plugin azure --enable-managed-identity --generate-ssh-keys

az network public-ip create -n neoPublicIp -g neoResourceGroup --allocation-method Static --sku Standard
az network vnet create -n neoVnet -g neoResourceGroup --address-prefix 10.0.0.0/16 --subnet-name neoSubnet --subnet-prefix 10.0.0.0/24 
az network application-gateway create -n neoApplicationGateway -l eastus -g neoResourceGroup --sku Standard_v2 --public-ip-address neoPublicIp --vnet-name neoVnet --subnet neoSubnet --priority 100

appgwId=$(az network application-gateway show -n neoApplicationGateway -g neoResourceGroup -o tsv --query "id") 
az aks enable-addons -n neoCluster -g neoResourceGroup -a ingress-appgw --appgw-id $appgwId

nodeResourceGroup=$(az aks show -n neoCluster -g neoResourceGroup -o tsv --query "nodeResourceGroup")
aksVnetName=$(az network vnet list -g $nodeResourceGroup -o tsv --query "[0].name")

aksVnetId=$(az network vnet show -n $aksVnetName -g $nodeResourceGroup -o tsv --query "id")
az network vnet peering create -n AppGWtoAKSVnetPeering -g neoResourceGroup --vnet-name neoVnet --remote-vnet $aksVnetId --allow-vnet-access

appGWVnetId=$(az network vnet show -n neoVnet -g neoResourceGroup -o tsv --query "id")
az network vnet peering create -n AKStoAppGWVnetPeering -g $nodeResourceGroup --vnet-name $aksVnetName --remote-vnet $appGWVnetId --allow-vnet-access

az aks get-credentials -n neoCluster -g neoResourceGroup

export CERT_NAME=aks-ingress-cert
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -out aks-ingress-tls.crt \
    -keyout aks-ingress-tls.key \
    -subj "/CN=demo.azure.com/O=aks-ingress-tls"

kubectl create secret tls guestbooksecret --key ~/certificate/aks-ingress-tls.key --cert ~/certificate/aks-ingress-tls.crt

//Tutorial: Setting up E2E SSL

kubectl exec -it website-deployment-757b588556-ghwj9 -- curl -k https://localhost:8443

applicationGatewayName="neoApplicationGateway "
resourceGroup="neoResourceGroup"
az network application-gateway root-cert create \
    --gateway-name $applicationGatewayName  \
    --resource-group $resourceGroup \
    --name backend-tls \
    --cert-file backend.crt
