## Quickstart: Create a Windows virtual machine with the Azure CLI
## https://docs.microsoft.com/en-us/azure/virtual-machines/windows/quick-create-cli

# Create resource group
az group create --name testWindowsRg --location eastus

# Create a Virtual machine
az vm create \
    --resource-group testWindowsRg \
    --name myWin2019VM \
    --image win2019datacenter \
    --admin-username azureuser

# Open port 80 for web trffic 
#az vm open-port --port 80 --resource-group myResourceGroup --name myVM

# Stop virtual machine
#az vm stop --resource-group testWindowsRg --name myWindows2016VM 

# Start virtual machine
#az vm start --resource-group testWindowsRg --name myWindows2016VM

# Show the ResourceGroup
#az group --output table 

# PowerShell, Connect to virtual machine via RDP
#mstsc /v:publicIpAddress

# Clean up resources
#az group delete --name testWindowsRg --no-wait --yes
