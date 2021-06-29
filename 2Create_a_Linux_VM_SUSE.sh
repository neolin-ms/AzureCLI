#!/bin/bash

## Tutorial: Create and Manage Linux VMs with the Azure CLI
## https://docs.microsoft.com/en-us/azure/virtual-machines/linux/tutorial-manage-vm

# Create resource group
az group create --name testSUSERg --location westus2 

# Create virtual machine
az vm create \
    --resource-group testSUSERg \
    --name mySUSEVM15sp2westus2 \
    --image SUSE:sles-15-sp2:gen2:2021.03.03 \
    --size Standard_D4s_v3 \
    --admin-username azureuser \
    --generate-ssh-keys

# Image version example
#--image SUSE:sles-15-sp2:gen2:2021.03.03 \

# VM size example
#--size Standard_D4s_v3 \

# Connect to VM
#ssh azureuser@52.174.34.95

# Stop virtual machine
#az vm stop --resource-group testSUSERg --name myVM

# Start virtual machine
#az vm start --resource-group testSUSERg --name myVM

# Show the ResourceGroup
#az group --output table 

# Get IP address
#az vm list-ip-addresses --resource-group testsuserg --name mySUSEVM --output table

# Delete resource group
#az group delete --name testCentOSRg --no-wait --yes
    
# Example for image version 
## --image SUSE:sles-15-sp2:gen1:2020.12.10 \
