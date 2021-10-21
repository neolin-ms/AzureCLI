#!/bin/bash

#References
## https://docs.microsoft.com/en-us/cli/azure/vmss?view=azure-cli-latest#az_vmss_create
## https://docs.microsoft.com/en-us/azure/virtual-machines/extensions/oms-linux
## https://docs.microsoft.com/en-us/cli/azure/vmss/extension?view=azure-cli-latest#az_vmss_extension_set
## https://docs.microsoft.com/en-us/cli/azure/monitor/log-analytics/workspace?view=azure-cli-latest#az_monitor_log_analytics_workspace_show
## https://docs.microsoft.com/en-us/cli/azure/monitor/log-analytics/workspace?view=azure-cli-latest#az_monitor_log_analytics_workspace_get_shared_keys
## https://github.com/microsoft/OMS-Agent-for-Linux/blob/master/docs/OMS-Agent-for-Linux.md
## https://docs.microsoft.com/en-us/azure/azure-monitor/agents/agent-linux-troubleshoot
## https://blog.surgut.co.uk/2019/08/how-to-disable-tls-10-and-tls-11-on.html
## https://devanswers.co/test-server-tls-1-2-ubuntu/
## https://www.openssl.org/docs/man3.0/man5/config.html

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
  --settings '{"workspaceId":"'${workspace_id}'"}' \
  --protected-settings '{"workspaceKey":"'${workspace_key}'"}'

# Also you can directly replace the WorkspaceId and WorkspaceKey, don't use the bash variable, e.g. workspace_id and workspace_key. 
az vmss extension set \
  --resource-group ${rg_name} \
  --vmss-name ${vmss_name} \
  --name OmsAgentForLinux \
  --publisher Microsoft.EnterpriseCloud.Monitoring \
  --settings '{"workspaceId":"WorkspaceId"}' \
  --protected-settings '{"workspaceKey":"WorkspaceKey"}'

# Onboarding with Azure Monitor Log Analytics workspace - Onboarding using the command line
cd /opt/microsoft/omsagent/bin/omsadmin.sh -w <Workspace ID> -s <Primary Key> -v

# Onboarding with Azure Monitor Log Analytics workspace - Onboarding using a file

## 1. Create the file /etc/omsagent-onboard.conf The file must be readable and writable for root.
sudo vi /etc/omsagent-onboard.conf

## 2. Insert the following lines in the file with your Workspace ID and Shared Key:
WORKSPACE_ID=<WorkspaceID>
SHARED_KEY=<Shared Key>

## 3. Onboard to an Azure Monitor Log Analytics workspace:
sudo /opt/microsoft/omsagent/bin/omsadmin.sh -v

## 4. The file will be deleted on successful onboarding.
sudo /opt/microsoft/omsagent/bin/omsadmin.sh -l

## 5. Other operion of omsadmin.sh
sudo /opt/microsoft/omsagent/bin/omsadmin.sh -h

Maintenance tool for OMS:                                                                                               
Onboarding:                                                                                                             
omsadmin.sh -w <workspace id> -s <shared key> [-d <top level domain>]

List Workspaces: 
omsadmin.sh -l

Remove Workspace:
omsadmin.sh -x <workspace id>

Remove All Workspaces:
omsadmin.sh -X

Update workspace configuration and folder structure to multi-homing schema:
omsadmin.sh -U                                                                                                                                                                                                                                  

Onboard the workspace with a multi-homing marker. The workspace will be regarded as secondary.                          
omsadmin.sh -m <multi-homing marker>                                                                                                                                                                                                            

Define proxy settings ('-u' will prompt for password):                                                                  
omsadmin.sh [-u user] -p host[:port]                                                                                                                                                                                                            

Azure resource ID:                                                                                                      
omsadmin.sh -a <Azure resource ID>                                                                                                                                                                                                              

Detect if omiserver is listening to SCOM port:                                                                          
omsadmin.sh -o

# How to test a server for TLS v1.2/1.3 support in Linux
## 1. openssl for TLS v1.2
openssl s_client -connect google.com:443 -tls1_2
openssl s_client -connect <Workspace ID>.oms.opinsights.azure.com:443 -tls1_2

## 2. openssl for TLS v1.3
openssl s_client -connect google.com:443 -tls1_3
penssl s_client -connect <Workspace ID>.oms.opinsights.azure.com:443 -tls1_3

# How to disable TLS v1.0/1.1 in OpenSSL
##1. Edit /etc/ssl/openssl.cnf
sudo vi /etc/ssl/openssl.cnf

## 2. After oid_section stanza add
# System default
openssl_conf = default_conf

## 3. After oid_section stanza add
[default_conf]
ssl_conf = ssl_sect

[ssl_sect]
system_default = system_default_sect

[system_default_sect]
MinProtocol = TLSv1.2
# MaxProtocol = TLSv1.2
CipherString = DEFAULT@SECLEVEL=2

## 4. Save the file
