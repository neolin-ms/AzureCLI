#!/bin/bash

## Tutorial: Create and Manage Linux VMs with the Azure CLI
## https://docs.microsoft.com/en-us/azure/virtual-machines/linux/tutorial-manage-vm
## Find Linux VM images in the Azure Marketplace with the AzureCLI
## https://docs.microsoft.com/en-us/azure/virtual-machines/linux/cli-ps-findimage

# Create resource group
az group create --name testDebianRg --location eastasia 

# Create virtual machine
az vm create \
    --resource-group testDebianRg \
    --name myDebianVM92 \
    --image credativ:Debian:9:9.20190221.0 \
    --size Standard_D4s_v3 \
    --admin-username azureuser \
    --generate-ssh-keys

#Image version example
#--image Publisher:Offer:Sku:Version \

#VM size example
#--size Standard_D4s_v3 \

# Connect to VM
#ssh azureuser@52.174.34.95

# Stop virtual machine
#az vm stop --resource-group testDebianSRg --name myVM

# Start virtual machine
#az vm start --resource-group testDebianRg --name myVM

# Show the ResourceGroup
#az group --output table 

# Get IP address
#az vm list-ip-addresses --resource-group testDebianRg --name myDebianVM --output table

# Delete resource group
#az group delete --name testDebianRg --no-wait --yes
