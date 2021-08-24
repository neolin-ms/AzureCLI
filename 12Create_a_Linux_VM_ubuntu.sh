#!/bin/bash

## Tutorial: Create and Manage Linux VMs with the Azure CLI
## https://docs.microsoft.com/en-us/azure/virtual-machines/linux/tutorial-manage-vm
## Find Linux VM images in the Azure Marketplace with the AzureCLI                                                                                                                                        ## https://docs.microsoft.com/en-us/azure/virtual-machines/linux/cli-ps-findimage 

# Create resource group
az group create --name testUbuntuRg --location eastasia

# Create virtual machine
az vm create \
    --resource-group testUbuntuRg \
    --name myUbuntu1804vm0824 \
    --image Canonical:UbuntuServer:18.04-LTS:18.04.202107200 \
    --size Standard_D4s_v3 \
    --admin-username azureuser \
    --generate-ssh-keys

## Image example
#Canonical|UbuntuServer|18.04-LTS|18.04.202103250
#--image Canonical:UbuntuServer:16.04-LTS:16.04.202103160 \
#--image Canonical:UbuntuServer:18_04-lts-gen2:18.04.202103250 \
#--image Canonical:UbuntuServer:18.04-LTS:18.04.202106220 \
#--image Canonical:UbuntuServer:18.04-LTS:18.04.202107200 \

# VM size example
#--size Standard_D4s_v3 \

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
