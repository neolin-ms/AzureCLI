#!/bin/bash

## Tutorial: Create and Manage Linux VMs with the Azure CLI
## https://docs.microsoft.com/en-us/azure/virtual-machines/linux/tutorial-manage-vm

# Create resource group
az group create --name testRedHatRg --location southeastasia

# Create virtual machine
az vm create \
    --resource-group testRedHatRg \
    --name myRedHatVM \
    --image RHEL \
    --admin-username azureuser \
    --generate-ssh-keys

# Connect to VM
#ssh azureuser@52.174.34.95

# Stop virtual machine
#az vm stop --resource-group testRedHatRg --name myVM

# Start virtual machine
#az vm start --resource-group testRedHatRg --name myVM

# Show the ResourceGroup
#az group --output table 

# Delete resource group
#az group delete --name testRedHatRg --no-wait --yes
