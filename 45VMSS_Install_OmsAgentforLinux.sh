#!/bin/bash

#References

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
  --lb-sku Standard \
  --admin-username azureuser \
  --generate-ssh-keys
  
##Option Parameters
##[--lb-sku {Basic, Gateway, Standard}]

# Finally, tell Azure to install and enable the extension.
workspace_id=
workspace_key=

az vm extension set \
  --resource-group ${rg_name} \
  --vmss-name ${vmss_name} \
  --name OmsAgentForLinux \
  --publisher Microsoft.EnterpriseCloud.Monitoring \
  --settings '{"workspaceId":"${workspace_id}"}' \
  --protected-settings '{"workspaceKey":"${workspace_key}"}'

az vm extension set \
  --resource-group ${rg_name} \
  --vmss-name ${vmss_name} \
  --name OmsAgentForLinux \
  --publisher Microsoft.EnterpriseCloud.Monitoring \
  --settings '{"workspaceId":"myWorkspaceId"}' \
  --protected-settings '{"workspaceKey":"myWorkspaceKey"}'
