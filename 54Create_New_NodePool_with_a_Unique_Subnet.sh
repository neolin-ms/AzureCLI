#/bin/sh

# References
https://docs.microsoft.com/en-us/azure/aks/use-multiple-node-pools#add-a-node-pool
https://docs.microsoft.com/en-us/azure/aks/tutorial-kubernetes-prepare-acr?tabs=azure-cli
https://docs.microsoft.com/en-us/azure/aks/configure-azure-cni
https://docs.microsoft.com/en-us/azure/aks/learn/quick-windows-container-deploy-cli
https://stackoverflow.com/questions/51161647/kubectl-run-set-nodeselector
https://hack543.com/nmap-tutorial/
https://www.tecmint.com/nmap-command-examples/
https://docs.microsoft.com/en-us/azure/aks/rdp?tabs=azure-cli

# Create vNET, 2 Subnets and AKS cluster
rgName=labResourceGroup
regionName=japaneast
az group create -n $rgName -l $regionName

vnetName=vnetJpeast
subnetName1=firstSubnet
subnetName2=secondSubnet
az network vnet create -g $rgName --location $regionName --name $vnetName --address-prefixes 172.23.44.0/22
az network vnet subnet create -g $rgName --vnet-name $vnetName --name $subnetName1 --address-prefixes 172.23.46.0/23
az network vnet subnet create -g $rgName --vnet-name $vnetName --name $subnetName2 --address-prefixes 172.23.44.0/24

firstSubnetid=$(az network vnet subnet show -g $rgName -n $subnetName1 --vnet-name $vnetName --query id -o tsv)
secondSubnetid=$(az network vnet subnet show -g $rgName -n $subnetName2 --vnet-name $vnetName --query id -o tsv)

aksName=labAKSCluster
winuserName=azureuser
az aks create \
  --resource-group $rgName \
   --name $aksName \
   --network-plugin azure \
   --vnet-subnet-id $firstSubnetid \
   --docker-bridge-address 172.17.0.1/16 \
   --node-count 1 \
   --enable-cluster-autoscaler \
   --min-count 1 \
   --max-count 3 \
   --nodepool-name linuxnode \
   --generate-ssh-keys \
   --windows-admin-username $winuserName \
   --vm-set-type VirtualMachineScaleSets

az aks get-credentials -n labAKSCluster -g labResourceGroup
kubectl get nodes -o wide

# Add a windows node pool and use the secondSubnet
winnodeName=winode
az aks nodepool add \
  -g $rgName \
  --cluster-name $aksName \
  --name $winnodeName \
  --os-type Windows \
  --enable-cluster-autoscaler \
  --vnet-subnet-id $secondSubnetid \
  --min-count 1 \
  --max-count 3 \
  --max-pods 50 \
  --node-count 1

# Deploy a windows application on windows node
kubectl get nodes -o wide
kubectl apply -f win_sample.yaml
kubectl get pods,svc -o wide

# Add a new address space in vNET from the Azure portal and update the cluster
az aks update -g $rgName -n $aksName

# Add a new thirdSubnet and the new subnet address is address range under the new address space 
subnetName3=thirdSubnet
az network vnet subnet create -g $rgName --vnet-name $vnetName --name $subnetName3 --address-prefixes 172.23.56.0/23
thirdSubnetid=$(az network vnet subnet show -g $rgName -n $subnetName3 --vnet-name $vnetName --query id -o tsv)

# Create a new linux node pool and use the thirdSubnet
az aks nodepool add \
  -g $rgName \
  --cluster-name $aksName \
  --name linuxnode2 \
  --os-type Linux \
  --enable-cluster-autoscaler \
  --vnet-subnet-id $thirdSubnetid \
  --min-count 1 \
  --max-count 3 \
  --max-pods 20 \
  --node-count 1

# Test the application
kubectl run -it --rm aks-test --image=mcr.microsoft.com/dotnet/runtime-deps:6.0 --overrides='{"spec": { "nodeSelector": {"kubernetes.io/os": "linux"}}}'
kubectl run -it --rm aks-test --image=mcr.microsoft.com/dotnet/runtime-deps:6.0 --overrides='{"spec": { "nodeSelector": {"kubernetes.io/hostname": "aks-linuxnode-35904113-vmss000000"}}}'
kubectl run -it --rm aks-test2 --image=mcr.microsoft.com/dotnet/runtime-deps:6.0 --overrides='{"spec": { "nodeSelector": {"kubernetes.io/hostname": "aks-linuxnode2-12236410-vmss000001"}}}'

apt-get update && apt-get install nmap -y && apt-get install iputils-ping -y && apt install iproute2 -y && apt install curl -y && apt-get install dnsutils -y

ping -c 3 172.23.44.29
nmap -sS -p 80 -Pn --traceroute 172.23.44.29
nmap -sV -T4 172.23.46.29
curl -L http://172.23.44.41

# Allow access to the virtual machine by RDP
CLUSTER_RG=$(az aks show -g labResourceGroup -n labAKSCluster --query nodeResourceGroup -o tsv)
NSG_NAME=$(az network nsg list -g $CLUSTER_RG --query [].name -o tsv)
az network nsg rule create \
 --name tempRDPAccess \
 --resource-group $CLUSTER_RG \
 --nsg-name $NSG_NAME \
 --priority 100 \
 --destination-port-range 3389 \
 --protocol Tcp \
 --description "Temporary RDP access to Windows nodes"

scp azureuser@172.23.46.35:/c:/k/debug/akswinode000000-20220803-061954_logs.zip .

# Troubleshooting
resourceUri=$(az aks show -n $aksName -g $rgName --query id -o tsv)
az resource update --ids $resourceUri

kubectl -n kube-system get cm azure-ip-masq-agent-config-reconciled -o yaml

kubectl delete pod -n kube-system -l k8s-app=azure-ip-masq-agent

kubectl debug node/aks-linuxnode-35904113-vmss000000 -it --image=mcr.microsoft.com/dotnet/runtime-deps:6.0
kubectl debug node/aks-linuxnode2-12236410-vmss000000 -it --image=mcr.microsoft.com/dotnet/runtime-deps:6.0

# Reimage the Windows node pool
az aks nodepool show -g labResourceGroup --cluster-name labAKSCluster --name winode --query nodeImageVersion
az aks nodepool upgrade \
  -g labResourceGroup \
  --cluster-name labAKSCluster \
  --name winode \
  --node-image-only
