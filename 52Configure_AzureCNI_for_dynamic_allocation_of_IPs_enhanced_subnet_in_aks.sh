#!/bin/bash

## https://learn.microsoft.com/en-us/azure/aks/configure-azure-cni-dynamic-ip-allocation
## https://learn.microsoft.com/en-us/azure/aks/tutorial-kubernetes-deploy-cluster?tabs=azure-cli
## https://learn.microsoft.com/en-us/azure/aks/configure-azure-cni
## https://phoenixnap.com/kb/linux-dig-command-examples
## https://learn.microsoft.com/en-us/azure/aks/resize-node-pool?tabs=azure-cli
## https://learn.microsoft.com/en-us/azure/aks/node-access
## https://learn.microsoft.com/en-us/troubleshoot/azure/azure-kubernetes/troubleshoot-connection-pods-services-same-cluster

export rg_name=testResourceGroup
export region_name=eastasia

az group create -n $rg_name -l $region_name

export vnet_name=aksVnet
az network vnet create \
   --resource-group $rg_name \
   --name $vnet_name \
   --address-prefixes 10.0.0.0/22

export subnet_name=aksNodeSubnet   
az network vnet subnet create \
  --resource-group $rg_name \
  --vnet-name $vnet_name \
  --name $subnet_name \
  --address-prefixes 10.0.0.0/23   
  
subnet_id=$(az network vnet subnet list --resource-group $rg_name --vnet-name $vnet_name --query "[0].id" --output tsv)

export aks_name=neoAKSCluster
az aks create \
    --resource-group $rg_name \
    --name $aks_name \
    --node-count 2 \
    --node-vm-size Standard_D2as_v4 \
    --network-plugin azure \
    --vnet-subnet-id $subnet_id \
    --dns-service-ip 10.2.0.10 \
    --service-cidr 10.2.0.0/24 \
    --generate-ssh-keys	

az aks get-credentials -n $aks_name -g $rg_name

az aks scale --node-count 2 -n $aks_name -g $rg_name

kubectl debug node/aks-nodepool1-92155434-vmss000000 -it --image=mcr.microsoft.com/dotnet/runtime-deps:6.0
kubectl debug node/aks-nodepool1-92155434-vmss000001 -it --image=mcr.microsoft.com/dotnet/runtime-deps:6.0

apt-get update && apt-get install dnsutils
dig @168.63.129.16 google.com
dig @8.8.8.8 google.com
dig @10.164.152.100 saint-eswriter-kv.vault.azure.net
dig @10.164.145.100 saint-eswriter-kv.vault.azure.net

kubectl run -it aks-ssh --image=debian:stable

kubectl attach aks-ssh -c aks-ssh -i -t

vi /run/systemd/resolve/resolv.conf

node_subnetid="/subscriptions/60796668-979e-4d0a-b3cd-74f9e7dba880/resourceGroups/$resourceGroup/providers/Microsoft.Network/virtualNetworks/$vnet/subnets/nodesubnet"
pod_subnetid="/subscriptions/60796668-979e-4d0a-b3cd-74f9e7dba880/resourceGroups/$resourceGroup/providers/Microsoft.Network/virtualNetworks/$vnet/subnets/podsubnet"
az aks create \
  -n $clusterName \
  -g $resourceGroup \
  -l $location \
  --node-count 2 \
  --max-pods 250 \
  --node-count 2 \
  --network-plugin azure \
  --vnet-subnet-id $node_subnetid \
  --pod-subnet-id $pod_subnetid  
  
az aks nodepool add --cluster-name $clusterName -g $resourceGroup  -n newnodepool \
    --max-pods 250 \
    --node-count 2 \
    --vnet-subnet-id $node_subnetid \
    --pod-subnet-id $pod_subnetid

## https://learn.microsoft.com/en-us/azure/aks/configure-azure-cni-dynamic-ip-allocation#dynamic-allocation-of-ip-addresses-and-enhanced-subnet-support-faqs
	
az aks nodepool show -g myResourceGroup --cluster-name myAKSCluster -n newnodepool -o json --query mode	
az aks nodepool show -g myResourceGroup --cluster-name myAKSCluster -n nodepool1 -o json --query mode
