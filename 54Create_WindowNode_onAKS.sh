#!/bin/sh

# References
## https://docs.microsoft.com/en-us/azure/aks/tutorial-kubernetes-prepare-acr?tabs=azure-cli
## https://docs.microsoft.com/en-us/azure/aks/configure-azure-cni
## https://docs.microsoft.com/en-us/azure/aks/learn/quick-windows-container-deploy-cli
## https://stackoverflow.com/questions/51161647/kubectl-run-set-nodeselector
## https://hack543.com/nmap-tutorial/
## https://www.tecmint.com/nmap-command-examples/

date
rgName=labResourceGroup
regionName=japaneast
az group create -n $rgName -l $regionName
date

date
acrName=myacr0801
az acr create --resource-group $rgName --name $acrName --sku Basic
date

date
vnetName=vnetJPEast
subnetName=firstSubnet
az network vnet create -g $rgName --location $regionName --name $vnetName --address-prefixes 172.23.44.0/22 -o none 
az network vnet subnet create -g $rgName --vnet-name $vnetName --name $subnetName --address-prefixes 172.23.46.0/23 -o none 
date

date
az network vnet subnet show -g $rgName -n $subnetName --vnet-name $vnetName --query id
date

date
aksName=labAKSCluster
winuserName=azureuser
az aks create \
  --resource-group $rgName \
   --name $aksName \
   --network-plugin azure \
   --vnet-subnet-id "/subscriptions/60796668-979e-4d0a-b3cd-74f9e7dba880/resourceGroups/labResourceGroup/providers/Microsoft.Network/virtualNetworks/vnetJPEast/subnets/firstSubnet" \
   --docker-bridge-address 172.17.0.1/16 \
   --node-count 1 \
   --enable-cluster-autoscaler \
   --min-count 1 \
   --max-count 3 \
   --nodepool-name linuxnode \
   --attach-acr $acrName \
   --generate-ssh-keys \
   --windows-admin-username $winuserName \
   --vm-set-type VirtualMachineScaleSets \
   --enable-addons monitoring
date

az aks get-credentials -n labAKSCluster -g labResourceGroup

date
winnodeName=winode
az aks nodepool add \
  -g $rgName \
  --cluster-name $aksName \
  --name $winnodeName \
  --os-type Windows \
  --node-vm-size Standard_B4ms \
  --enable-cluster-autoscaler \
  --min-count 1 \
  --max-count 3 \
  --max-pods 50 \
  --node-count 1
date  

date
kubectl get nodes -o wide
kubectl apply -f win_example.yaml
kubectl get pods,svc -o wide
pod/sample-5599975b64-hmxv4   1/1     Running   0          6m44s   172.23.46.40

kubectl run -it --rm aks-test --image=mcr.microsoft.com/dotnet/runtime-deps:6.0 --overrides='{"spec": { "nodeSelector": {"kubernetes.io/os": "linux"}}}'
kubectl run -it --rm aks-test --image=mcr.microsoft.com/dotnet/runtime-deps:6.0 --overrides='{"spec": { "nodeSelector": {"kubernetes.io/hostname": "aks-linuxnode-22258962-vmss000000"}}}'
kubectl run -it --rm aks-test --image=mcr.microsoft.com/dotnet/runtime-deps:6.0 --overrides='{"spec": { "nodeSelector": {"kubernetes.io/hostname": "aks-linuxnode2-28476889-vmss000000"}}}'

apt-get update && apt-get install nmap -y && apt-get install iputils-ping -y && apt install iproute2 -y && apt install curl -y


--> To Add a address space in Vnet-JP-East named NAKKSSubnet2
subnetName2=secondSubnet
az network vnet subnet show -g $rgName -n $subnetName2 --vnet-name $vnetName --query id

az aks update -g $rgName -n $aksName

date
az aks nodepool add \
  -g $rgName \
  --cluster-name $aksName \
  --name linuxnode2 \
  --os-type Linux \
  --enable-cluster-autoscaler \
  --min-count 1 \
  --max-count 3 \
  --max-pods 20 \
  --vnet-subnet-id "/subscriptions/60796668-979e-4d0a-b3cd-74f9e7dba880/resourceGroups/labresourcegroup/providers/Microsoft.Network/virtualNetworks/vnetJPEast/subnets/secondSubnet" \
  --node-count 1
date


winnodeName2=winod2
az aks nodepool add \
  -g $rgName \
  --cluster-name $aksName \
  --name $winnodeName2 \
  --os-type Windows \
  --enable-cluster-autoscaler \
  --min-count 1 \
  --max-count 3 \
  --max-pods 50 \
  --vnet-subnet-id "/subscriptions/60796668-979e-4d0a-b3cd-74f9e7dba880/resourceGroups/labresourcegroup/providers/Microsoft.Network/virtualNetworks/vnetJPEast/subnets/secondSubnet" \
  --node-count 1
