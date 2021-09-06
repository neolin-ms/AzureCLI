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
    --name mypanetworkVM0830 \
    --image paloaltonetworks:vmseries1:bundle1:9.1.0 \
    --size Standard_D4_v3 \
    --admin-username azureuser \
    --generate-ssh-keys

# Image version example
#--image paloaltonetworks:vmseries1:bundle1:9.1.0 \
#paloaltonetworks|vmseries1|bundle1|9.1.0

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
