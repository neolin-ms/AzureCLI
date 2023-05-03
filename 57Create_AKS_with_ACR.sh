#!/bin/bash

# Quickstart: Create a private container registry using the Azure CLI
# https://learn.microsoft.com/en-us/azure/container-registry/container-registry-get-started-azure-cli

export RG="eastusResourceGroup"
export location="eastus"
az group create -n $RG -l $location

export MYACR="myacr0503"
az acr create -n $MYACR -g $RG --sku basic

export cluster="eastusCluster"
az aks create -n $cluster -g $RG --node-count 2 --generate-ssh-keys --attach-acr $MYACR

az acr login --name $MYACR

docker tag stockdata:1.0.0 myacr0503.azurecr.io/stockdata:1.0.0
docker tag stockweb:1.0.0 myacr0503.azurecr.io/stockweb:1.0.0

docker pull mcr.microsoft.com/hello-world
docker pull myacr0503.azurecr.io/stockdata:1.0.0
docker pull myacr0503.azurecr.io/stockweb:1.0.0
