#!/bin/bash

## Quickstart: Create a Windows virtual machine with the Azure CLI
## https://docs.microsoft.com/en-us/azure/virtual-machines/windows/quick-create-cli

# Create resource group
az group create --name testWindowsRg --location eastasia

# Create a Virtual machine
az vm create \
    --resource-group testWindowsRg \
    --name myWin11vm0518 \
    --image MicrosoftWindowsDesktop:windows-11:win11-22h2-pron:22621.1702.230505 \
    --size Standard_D4s_v3 \
    --admin-username azureuser

# Image version example    
#--image MicrosoftWindowsDesktop:windows-11:win11-22h2-pron:22621.1702.230505 \
#--image MicrosoftWindowsDesktop|Windows-10:20h2-pro:19042.928.2104091209 \
#--image MicrosoftWindowsDesktop:Windows-10:20h2-pro:19042.1165.2108010715 \
#--image MicrosoftWindowsDesktop:Windows-10:19h2-ent:18363.1916.2111030305 \

# VM size example
#--size Standard_D4s_v3 \

# Open port 80 for web trffic 
#az vm open-port --port 80 --resource-group myResourceGroup --name myVM

# Stop virtual machine
#az vm stop --resource-group testWindowsRg --name myWindows2016VM 

# Start virtual machine
#az vm start --resource-group testWindowsRg --name myWindows2016VM

# Show the ResourceGroup
#az group --output table 

# Check the VM status and Get public IP address
#az vm list -d -o table

# PowerShell, Connect to virtual machine via RDP
#mstsc /v:publicIpAddress

# Clean up resources
#az group delete --name testWindowsRg --no-wait --yes
