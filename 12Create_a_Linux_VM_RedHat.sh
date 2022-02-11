#!/bin/bash

## Tutorial: Create and Manage Linux VMs with the Azure CLI
## https://docs.microsoft.com/en-us/azure/virtual-machines/linux/tutorial-manage-vm
## Find Linux VM images in the Azure Marketplace with the AzureCLI                                                                                                                                        ## https://docs.microsoft.com/en-us/azure/virtual-machines/linux/cli-ps-findimage 

# Create resource group
az group create --name testRedHatRg --location southeastasia

# Create virtual machine
az vm create \
    --resource-group testRedHatRg \
    --name testRedHat77raw0125 \
    --image RedHat:RHEL:7-RAW:7.7.2019090418 \
    --size Standard_D4s_v3 \
    --admin-username azureuser \
    --generate-ssh-keys

# Image version
#--image RedHat:RHEL:8.2:8.2.2021040911 \
#--image RedHat:RHEL:7.6:7.6.2021051101 \
#--image RedHat:RHEL:7.8:7.8.2021051701 \
#--image RedHat:RHEL:8_3:8.3.2021091101 \
#--image RedHat:RHEL:8_3:8.3.2021041912 \
#--image RedHat:RHEL:8-LVM:8.3.2021040401 \ 
#--image RedHat:RHEL:8-LVM:8.3.2021091103 \
#--image RedHat:RHEL:8.2:8.2.2020270811 \
#--image RedHat:RHEL:6.10:6.10.2019061919 \
#--image RedHat:RHEL:7-RAW:7.7.2019090418 \
#--image RedHat:rhel-raw:7-raw:7.7.2021062301 \
#--image RedHat:rhel-raw:7-raw:7.9.2021062301 \
#--image RedHat:rhel-raw:8_3:8.3.2021040901 \

#VM size example
#--size Standard_D4s_v3 \

# Connect to VM
#ssh azureuser@52.174.34.95

# Stop virtual machine
#az vm stop --resource-group testRedHatRg --name myVM

# Start virtual machine
#az vm start --resource-group testRedHatRg --name myVM

# Show the ResourceGroup
#az group --output table 

# Get IP address
az vm list-ip-addresses --resource-group testredhatrg --name myRedHatVM --output table

# Delete resource group
#az group delete --name testRedHatRg --no-wait --yes
