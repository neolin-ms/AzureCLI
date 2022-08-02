#!/bin/sh

# Reference
## https://docs.microsoft.com/en-us/azure/aks/availability-zones
## https://kubernetes.io/docs/setup/best-practices/multiple-zones/#storage-access-for-zones
## https://github.com/Azure/AKS/issues/2659
## https://github.com/kubernetes-sigs/azuredisk-csi-driver/tree/master/deploy/example/topology#zrs-disk-support
## https://docs.microsoft.com/en-us/azure/aks/azure-disks-dynamic-pv
## https://github.com/clarenceb/aks-zrs-demo

# Create an AKS cluster across availability zones
az group create --name myResourceGroup --location  WestUS2

az aks create \
    --resource-group myResourceGroup \
    --name myAKSCluster \
    --generate-ssh-keys \
    --vm-set-type VirtualMachineScaleSets \
    --load-balancer-sku standard \
    --node-count 3 \
    --zones 1 2 3

az aks get-credentials -g myResourceGroup -n myAKSCluster

kubectl get nodes -o wide 

kubectl get nodes -o custom-columns=NAME:'{.metadata.name}',REGION:'{.metadata.labels.topology\.kubernetes\.io/region}',ZONE:'{metadata.labels.topology\.kubernetes\.io/zone}'
 
kubectl get no --show-labels | grep topo

# Create a storage class for ZRS
kubectl get sc

nano managed-cis-zrs.yaml

kubectl apply -f managed-cis-zrs.yaml

kubectl get sc

# Create a persistent volume claim
nano azure-pvc-zrs.yaml

kubectl apply -f azure-pvc-zrs.yaml

kubectl describe pvc azure-managed-disk-zrs

# Use the persistent volume
nano azure-pvc-disk-zrs.yaml

kubectl apply -f azure-pvc-disk-zrs.yaml

kubectl describe pod mypod

kubectl get pod -o wide

# Open a new termial and Monitor the pod 
kubectl get pods -o wide -w

# Delete the work node-count
az aks show -n myAKSCluster -g myResourceGroup -o tsv --query nodeResourceGroup
kubectl get nodes -o wide
az vmss list-instances -g MC_myResourceGroup_myAKSCluster_westus2 -n aks-nodepool1-31727431-vmss -o table
az vmss restart -g MC_myResourceGroup_myAKSCluster_westus2 -n aks-nodepool1-31727431-vmss --instance-ids 2

kubectl get nodes -o wide
kubectl delete node aks-nodepool1-31727431-vmss000003
az vmss list-instances -g MC_myResourceGroup_myAKSCluster_westus2 -n aks-nodepool1-31727431-vmss -o table
az vmss delete-instances -g MC_myResourceGroup_myAKSCluster_westus2 -n aks-nodepool1-31727431-vmss --instance-ids 2

# Verify the pod and PVC
kubectl get pods -o wide
kubectl exec -it <POD_NAME> -- /bin/sh


