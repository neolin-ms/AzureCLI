#!/bin/bash

## Tutorial: Create and Manage Linux VMs with the Azure CLI
## https://docs.microsoft.com/en-us/azure/virtual-machines/linux/tutorial-manage-vm
## Find Linux VM images in the Azure Marketplace with the AzureCLI                                                                                                                                        ## https://docs.microsoft.com/en-us/azure/virtual-machines/linux/cli-ps-findimage 

# Create resource group
az group create --name testUbuntuRg --location eastus

# Create virtual machine
az vm create \
    --resource-group testUbuntuRg \
    --name myUbuntuVM \
    --image UbuntuLTS \
    --admin-username azureuser \
    --generate-ssh-keys

# Connect to VM
#ssh azureuser@52.174.34.95

# Stop virtual machine
#az vm stop --resource-group testUbuntuRg --name myVM

# Start virtual machine
#az vm start --resource-group testUbuntuRg --name myVM

# Show the ResourceGroup
#az group --output table 

# Get IP address
az vm list-ip-addresses --resource-group testubunturg --name myubuntuvm --output table

# Delete resource group
#az group delete --name testUbuntuRg --no-wait --yes
