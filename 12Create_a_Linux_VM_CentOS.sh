#!/bin/bash

## Tutorial: Create and Manage Linux VMs with the Azure CLI
## https://docs.microsoft.com/en-us/azure/virtual-machines/linux/tutorial-manage-vm
## Find Linux VM images in the Azure Marketplace with the AzureCLI
## https://docs.microsoft.com/en-us/azure/virtual-machines/linux/cli-ps-findimage

# Create resource group
az group create --name testCentOSRg --location uaenorth 

# Create virtual machine
az vm create \
    --resource-group testCentOSRg \
    --name myCentOS77vm0810dv4 \
    --image OpenLogic:CentOS:7.7:7.7.2020111300 \
    --size Standard_D8_v4 \
    --admin-username azureuser \
    --generate-ssh-keys

# Image version example
#--image OpenLogic:CentOS:7.5:7.5.201808150 \
#--image OpenLogic:CentOS:7.6:7.6.20190708 \
#--image OpenLogic:CentOS:8_2:8.2.2020111800 \ 
#--image OpenLogic:CentOS:8.0:8.0.201912060 \ 
#--image OpenLogic:CentOS:7.7:latest \
#--image OpenLogic:CentOS:7.7:7.7.2020111300 \

# Connect to VM
#ssh azureuser@52.174.34.95

# Stop virtual machine
#az vm stop --resource-group testCentOSRg --name myVM

# Start virtual machine
#az vm start --resource-group testCentOSRg --name myVM

# Show the ResourceGroup
#az group --output table 

# Get IP address
#az vm list-ip-addresses --resource-group testcentosrg --name myCentOSVM --output table

# Delete resource group
#az group delete --name testCentOSRg --no-wait --yes
