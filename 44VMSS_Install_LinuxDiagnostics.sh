#!/bin/bash

#References
##https://docs.microsoft.com/en-us/azure/azure-monitor/agents/diagnostics-extension-overview
##https://docs.microsoft.com/en-us/cli/azure/storage/account?view=azure-cli-latest#az_storage_account_generate_sas 
##https://docs.microsoft.com/en-us/azure/virtual-machines/extensions/diagnostics-linux-v3?context=/azure/virtual-machines/context/context#install-the-extension-on-a-vm 

# Login to Azure before you do anything else.
az login

# Select the subscription that contains the storage account.
subscription_id=<Azure Subscription ID>
az account set --subscription ${subscription_id}

# Creaet a new resource group and VMSS
rg_name=testcentosrg
region_name=eastus
vmss_name=myScaleSet

az group create --name ${rg_name} --location ${region_name}

az vmss create \
  --resource-group ${rg_name} \
  --name ${vmss_name} \
  --image CentOS \
  --upgrade-policy-mode automatic \
  --admin-username azureuser \
  --generate-ssh-keys
  
#Set your Azure Virtual Machine Scale Sets diagnostic variables.
storacc_name=linuxdiagnosticstest1007

# Download the sample public settings. (You could also use curl or any web browser.)
wget https://raw.githubusercontent.com/Azure/azure-linux-extensions/master/Diagnostic/tests/lad_2_3_compatible_portal_pub_settings.json -O portal_public_settings.json

# Build the virtual machine scale set resource ID. Replace the storage account name and resource ID in the public settings.
vmss_resourceid=$(az vmss show -g ${rg_name} -n ${vmss_name} --query "id" -o tsv)
sed -i "s#__DIAGNOSTIC_STORAGE_ACCOUNT__#${storacc_name}#g" portal_public_settings.json
sed -i "s#__VM_RESOURCE_ID__#${vmss_resourceid}#g" portal_public_settings.json

# Build the protected settings (storage account SAS token).
storacc_sastoken=$(az storage account generate-sas --permissions wlacu --account-name ${storacc_name} --expiry 2037-12-31T23:59:00Z --resource-types co --services bt -o tsv)
protected_settings="{'storageAccountName': '${storacc_name}', 'storageAccountSasToken': '${storacc_sastoken}'}"

# Finally, tell Azure to install and enable the extension.
az vmss extension set --publisher Microsoft.Azure.Diagnostics --name LinuxDiagnostic --version 3.0 --resource-group ${rg_name} --vmss-name ${vmss_name} --protected-settings "${protected_settings}" --settings portal_public_settings.json  
