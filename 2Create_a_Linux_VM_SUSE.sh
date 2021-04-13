#!/bin/bash

## Tutorial: Create and Manage Linux VMs with the Azure CLI
## https://docs.microsoft.com/en-us/azure/virtual-machines/linux/tutorial-manage-vm

# Create resource group
az group create --name testSUSERg --location eastasia 

# Create virtual machine
az vm create \
    --resource-group testSUSERg \
    --name mySUSEVM \
    --image SUSE:sles-15-sp2:gen2:2021.03.03 \
    --size standard_d2s_v3 \
    --admin-username azureuser \
    --generate-ssh-keys

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
