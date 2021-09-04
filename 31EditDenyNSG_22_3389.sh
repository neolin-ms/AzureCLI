#!/bin/sh

## AzureCLI
## https://docs.microsoft.com/en-us/cli/azure/network/nsg?view=azure-cli-latest

# Sign in with Azure CLI
#az login --use-device-code

# List network security groups.
#az network nsg list --query "[?location=='eastasia']"
#az network nsg list --query "[?Name]"

# Get information about a network security group.
#az network nsg show -g ${rg_name} -n ${nsg_name}
#az network nsg list --query [].name -o tsv
#az network nsg list --query [].resourceGroup -o tsv

# List all rules in a network security group
#az network nsg rule list -g ${rg_name} --nsg-name ${nsg_name}
#az network nsg rule list -g ${rg_name} --nsg-name ${nsg_name} --query [].destinationPortRange -o tsv

rg_word_count=$(az group list --query [].name -o tsv | wc -l)
for ((i = 1 ; i <= ${rg_word_count} ; i++)); do
  rg_name=$(az group list --query [].name -o tsv | sed -n ${i}p)
  echo "Resource Group ${i}: ${rg_name}"
  nsg_name=$(az network nsg list --resource-group ${rg_name} --query [].name -o tsv)
  if [[ -z "${nsg_name}" ]]; then
    echo "This Resource Group hasn't any NSGs."
  elif [[ -n "${nsg_name}" ]]; then
    if [[ testWindowsRg == ${rg_name} ]]; then
      echo "This is a Windows resource group"
      echo "NSG: ${nsg_name}"
    else
      echo "This is a Linux resource group" 
      nsg_word_count=$(az network nsg list --resource-group ${rg_name} --query [].name -o tsv | wc -l)
      for ((j = 1 ; j <= ${nsg_word_count} ; j++)); do
         nsg_name=$(az network nsg list --resource-group ${rg_name} --query [].name -o tsv | sed -n ${j}p)
         echo "NSG: ${nsg_name}"
         dest_port=$(az network nsg rule list -g ${rg_name} --nsg-name ${nsg_name} --query [].destinationPortRange -o tsv)
         echo "Destination Port Range: ${dest_port}"
      done
    fi
  fi
done
