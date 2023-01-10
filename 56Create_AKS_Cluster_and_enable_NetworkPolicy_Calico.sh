#!/bin/bash

## Create an AKS cluster and enable Network Policy
## https://learn.microsoft.com/en-us/azure/aks/use-network-policies
## calicoctl version
## https://projectcalico.docs.tigera.io/reference/calicoctl/version
## Host Endpoints
## https://projectcalico.docs.tigera.io/maintenance/kubernetes-upgrade

## Create cluster and enable network policy Calico
az group create -n mycalicoResourceGroup -l eastasia

az aks create \
    --resource-group mycalicoResourceGroup \
    --name mycalicoAKSCluster \
    --node-count 2 \
    --network-plugin azure \
    --network-policy calico

## Check Calico version
./calicoctl get hep -owide | grep '*' | awk '{print $1}'

kubectl describe pod $(kubectl get pod -n tigera-operator | awk 'NR!=1{print $1}') -n tigera-operator | grep "Image:"
kubectl describe pod $(kubectl get pod -n calico-system | awk 'NR!=1{print $1}') -n calico-system | grep "Image:"
