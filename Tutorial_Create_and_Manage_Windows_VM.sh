## Tutorial: Create and Manage Windows VMs with Azure PowerShell
## https://docs.microsoft.com/en-us/azure/virtual-machines/windows/tutorial-manage-vm

## Create resource group
# An Azure resource group is a logical container into which Azure resources are deployed and managed
New-AzResourceGroup `
   -ResourceGroupName "myResourceGroupVM" `
   -Location "EastUS"

## Create a VM
# When creating a VM, several options are available like operating system image, network configuration, and administrative credentials.
# 
$cred = Get-Credential
