#!/bin/bash

## Tutorial: Create and Manage Linux VMs with the Azure CLI
## https://docs.microsoft.com/en-us/azure/virtual-machines/linux/tutorial-manage-vm

##　Create resource group
az group create --name myResourceGroupVM --location eastus

## Create virtual machine
az vm create \
    --resource-group myResourceGroupVM \
    --name myVM \
    --image UbuntuLTS \
    --admin-username azureuser \
    --generate-ssh-keys

## Connect to VM
#ssh azureuser@52.174.34.95

## Understand VM images
# To see a list of the most commonly used images
#az vm image list --output table

# A full list can be seen by adding the --all argument. The image list can also be filtered by --publisher or –-offer. In this example, the list is filtered for all images with an offer that matches CentOS.
#az vm image list --offer CentOS --all --output table

#  In this example, the --image argument is used to specify the latest version of a CentOS 6.5 image.
#az vm create --resource-group myResourceGroupVM --name myVM2 --image OpenLogic:CentOS:8.0:latest --generate-ssh-keys

## Understand VM sizes
#To see a list of VM sizes available in a particular region
az vm list-sizes --location eastus --output table

# Create VM with specific size
#az vm create \
#    --resource-group myResourceGroupVM \
#    --name myVM3 \
#    --image UbuntuLTS \
#    --size Standard_F4s \
#    --generate-ssh-keys

## Resize a VM
# After a VM has been deployed, it can be resized to increase or decrease resource allocation. You can view the current of size of a VM
az vm show --resource-group myResourceGroupVM --name myVM --query hardwareProfile.vmSize

# Before resizing a VM, check if the desired size is available on the current Azure cluster.
az vm list-vm-resize-options --resource-group myResourceGroupVM --name myVM --query [].name

# If the desired size is available, the VM can be resized from a powered-on state, however it is rebooted during the operation.
#az vm resize --resource-group myResourceGroupVM --name myVM --size Standard_DS4_v2

# If the desired size is not on the current cluster, the VM needs to be deallocated before the resize operation can occur. Use the az vm deallocate command to stop and deallocate the VM. Note, when the VM is powered back on, any data on the temp disk may be removed. The public IP address also changes unless a static IP address is being used.
#az vm deallocate --resource-group myResourceGroupVM --name myVM

# Once deallocated, the resize can occur.
#az vm resize --resource-group myResourceGroupVM --name myVM --size Standard_GS1

# After the resize, the VM can be started.
#az vm start --resource-group myResourceGroupVM --name myVM

## VM power states
# Find the power state
az vm get-instance-view \
    --name myVM \
    --resource-group myResourceGroupVM \
    --query instanceView.statuses[1] --output table

## Management tasks
# Get IP address
az vm list-ip-addresses --resource-group myResourceGroupVM --name myVM --output table

## Stop virtual machine
#az vm stop --resource-group myResourceGroupVM --name myVM

## Start virtual machine
#az vm start --resource-group myResourceGroupVM --name myVM

# Delete resource group
#az group delete --name myResourceGroupVM --no-wait --yes
