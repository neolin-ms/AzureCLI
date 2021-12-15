#!/bin/bash

## Lisk the AKS resources
az aks list -o table

## Show the VMSS name of AKS
rgName=myResourceGroup
aksName=myAKSCluster

az aks show -g ${rgName} -n ${aksName} -o tsv --query nodeResourceGroup

## Show the instance-ids of node of AKS  
kubectl get nodes -o wide

## Restart a node in VMSS of AKS
vmssRGname=MC_myResourceGroup_myAKSCluster_eastus
instanceIds=0
vmssName=aks-nodepool1-22208758-vmss

az vmss restart --instance-ids 0 --name ${vmssName} --resource-group ${vmssRGname} 
