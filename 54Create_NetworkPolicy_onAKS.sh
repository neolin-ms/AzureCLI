#!/bin/sh

# Reference
## https://docs.microsoft.com/en-us/cli/azure/install-azure-cli
## https://docs.microsoft.com/en-us/azure/aks/use-network-policies
## https://kubernetes.io/docs/concepts/services-networking/network-policies/#targeting-a-range-of-ports

# Install the Azure CLI on Linux
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

az login --use-device

# Creaet an AKS cluster for Azure network policies
RESOURCE_GROUP_NAME=myResourceGroupNP
CLUSTER_NAME=myAKSCluster
LOCATION=eastasia

az group create -n $RESOURCE_GROUP_NAME -l $LOCATION

az aks create \
  --resource-group $RESOURCE_GROUP_NAME \
  --name $CLUSTER_NAME \
  --node-count 1 \
  --network-plugin azure \
  --generate-ssh-keys \
  --network-policy azure

az aks install-cli
	
az aks get-credentials --resource-group $RESOURCE_GROUP_NAME --name $CLUSTER_NAME	

# Targeting a range of Ports and IP address
kubectl create namespace production
kubectl label namespace/production purpose=production

kubectl create namespace development
kubectl label namespace/development purpose=development

kubectl apply -f network-policy-multi-port-egress-pro.yaml --namespace production
kubectl apply -f network-policy-multi-port-egress-dev.yaml --namespace development

# Test the Azure newtork policy
kubectl run --rm -it --image=mcr.microsoft.com/dotnet/runtime-deps:6.0 aks-test-pro --namespace production
kubectl run --rm -it --image=mcr.microsoft.com/dotnet/runtime-deps:6.0 aks-test-dev --namespace development

kubectl run --rm -it --image=sturrent/debian-ssh aks-test-pro --namespace production
kubectl run --rm -it --image=sturrent/debian-ssh aks-test-dev --namespace development

apt-get update && apt-get install nmap -y && apt-get install iputils-ping -y && apt install iproute2 -y && apt install curl -y

curl -v 20.210.24.11
curl -v 20.89.26.100

nmap -sS -p 80 -Pn --traceroute 20.89.26.100
nmap -sS -p 80 -Pn --traceroute 20.210.24.11

