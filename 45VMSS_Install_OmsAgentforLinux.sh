#!/bin/bash

#References
## https://docs.microsoft.com/en-us/azure/virtual-machines/extensions/oms-linux
## https://docs.microsoft.com/en-us/cli/azure/vmss/extension?view=azure-cli-latest#az_vmss_extension_set
## https://docs.microsoft.com/en-us/cli/azure/monitor/log-analytics/workspace?view=azure-cli-latest#az_monitor_log_analytics_workspace_show

# Login to Azure before you do anything else.
az login

# Select the subscription.
subscription_id=<Azure Subscription ID>
az account set --subscription ${subscription_id}

# Creaet a new resource group and VMSS.
rg_name=testcentosrg
region_name=japaneast
vmss_name=myScaleSet

az group create --name ${rg_name} --location ${region_name}

az vmss create \
  --resource-group ${rg_name} \
  --name ${vmss_name} \
  --image Canonical:UbuntuServer:18.04-LTS:18.04.202103250 \
  --upgrade-policy-mode automatic \
  --lb-sku Standard \
  --admin-username azureuser \
  --generate-ssh-keys
  
##Option Parameters
##--image Canonical:UbuntuServer:18.04-LTS:18.04.202103250 \
##--image CentOS \
##[--lb-sku {Basic, Gateway, Standard}]

# Create a workspace instance.
workspace_name=myworkspace1013

az monitor log-analytics workspace create -g ${rg_name} -n ${workspace_name}

# Get the Log Analytocs workspace ID and Primany Key
az monitor log-analytics workspace show --resource-group ${rg_name} --workspace-name ${workspace_name} --query customerId 
az monitor log-analytics workspace get-shared-keys --resource-group ${rg_name} --workspace-name ${workspace_name}

# Finally, tell Azure to install and enable the extension.
workspace_id=<Log Analytics Workspace ID>
workspace_key=<Workspace Primary Key>

az vmss extension set \
  --resource-group ${rg_name} \
  --vmss-name ${vmss_name} \
  --name OmsAgentForLinux \
  --publisher Microsoft.EnterpriseCloud.Monitoring \
  --settings '{"workspaceId":"${workspace_id}"}' \
  --protected-settings '{"workspaceKey":"${workspace_key}"}'

az vmss extension set \
  --resource-group ${rg_name} \
  --vmss-name ${vmss_name} \
  --name OmsAgentForLinux \
  --publisher Microsoft.EnterpriseCloud.Monitoring \
  --settings '{"workspaceId":"myWorkspaceId"}' \
  --protected-settings '{"workspaceKey":"myWorkspaceKey"}'
