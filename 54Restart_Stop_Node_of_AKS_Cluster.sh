#!/bin/bash

## Lisk the AKS resources
az aks list -o table

## Get the Resource Group name of node pool
rgName=myResourceGroup
aksName=myAKSCluster

az aks show -g ${rgName} -n ${aksName} --query nodeResourceGroup -o tsv

## Get the VMSS name
az vmss list -o table

## Show the instance-ids of node of AKS  
kubectl get nodes -o wide

## Get the instance Id of VMSS
az vmss list-instances -g MC_neoResourceGroup_neoAKSCluster_eastasia -n aks-nodepool1-28706398-vmss

## Restart a node in VMSS of AKS
vmssRGname=MC_myResourceGroup_myAKSCluster_eastus
vmssName=aks-nodepool1-22208758-vmss
instanceIds=2

az vmss restart --instance-ids ${instanceIds} --name ${vmssName} --resource-group ${vmssRGname} 

## Show newwork info of VMSS of AKS
az vmss show -n ${vmssName} -g ${vmssRGname} --query virtualMachineProfile.networkProfile.networkInterfaceConfigurations[].ipConfigurations[].subnet

## Show subnet info of VNET of VMSS/AKS 
vmssSubnetname=aks-subnet
vmssVNetname=aks-vnet-22208758

az network vnet subnet show -g {vmssRGname} -n ${vmssSubnetname} --vnet-name ${vmssVNetname}
