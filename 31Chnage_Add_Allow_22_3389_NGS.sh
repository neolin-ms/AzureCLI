#!/bin/bash

## AzureCLI
## https://docs.microsoft.com/en-us/cli/azure/network/nsg?view=azure-cli-latest
## https://docs.microsoft.com/en-us/cli/azure/network/nsg?view=azure-cli-latest#az_network_nsg_list
## https://docs.microsoft.com/en-us/cli/azure/network/nsg/rule?view=azure-cli-latest#az_network_nsg_rule_list
## https://docs.microsoft.com/en-us/cli/azure/network/nsg/rule?view=azure-cli-latest#az_network_nsg_rule_update

# Sign in with Azure CLI
#az login --use-device-code

# List network security groups.
#az network nsg list --query "[?location=='eastasia']"
#az network nsg list --query "[?Name]"

# Get information about a network security group.
#az network nsg show -g ${rgName} -n ${nsgName}
#az network nsg list --query [].name -o tsv
#az network nsg list --query [].resourceGroup -o tsv

# List all rules in a network security group
#az network nsg rule list -g ${rgName} --nsg-name ${nsgName}
#az network nsg rule list -g ${rgName} --nsg-name ${nsgName} --query [].destinationPortRange -o tsv

rgCount=$(az group list --query [].name -o tsv | wc -l)
for ((i = 1 ; i <= ${rgCount} ; i++)); do
  rgName=$(az group list --query [].name -o tsv | sed -n ${i}p)
  echo "Resource Group Name ${i}: ${rgName}"
  nsgName=$(az network nsg list --resource-group ${rgName} --query [].name -o tsv)
  if [[ -z "${nsgName}" ]]; then
    echo "This Resource Group hasn't any NSGs."
    echo "------------------------------------"
  elif [[ -n "${nsgName}" ]]; then
    nsgCount=$(az network nsg list --resource-group ${rgName} --query [].name -o tsv | wc -l)
    for ((j = 1 ; j <= ${nsgCount} ; j++)); do
       nsgName=$(az network nsg list --resource-group ${rgName} --query [].name -o tsv | sed -n ${j}p)
       echo "NSG Name: ${nsgName}"
       ruleCount=$(az network nsg rule list --resource-group ${rgName} --nsg-name ${nsgName} --query [].name -o tsv | wc -l)
       for ((k=1 ; k <= ${ruleCount} ; k++)); do
	  echo ${ruleCount}     
          destPort=$(az network nsg rule list -g ${rgName} --nsg-name ${nsgName} --query [].destinationPortRange -o tsv)
          echo "Destination Port Range: ${destPort}"
          if [[ "${destPort}" = "22" ]]; then
            publicIP=$(curl https://ipinfo.io/ip -s)
            echo ${publicIP}
          fi
       done
    done
  fi
done
