#!/bin/bash

## References
## https://docs.microsoft.com/en-us/azure/virtual-machines/extensions/oms-linux
## https://docs.microsoft.com/en-us/azure/virtual-machines/extensions/oms-windows
## https://techcommunity.microsoft.com/t5/itops-talk-blog/how-to-query-azure-resources-using-the-azure-cli/ba-p/360147
## https://docs.microsoft.com/en-us/cli/azure/format-output-azure-cli

#az login --use-device-code
Num=`az vm list -o tsv | wc -l`
for ((i=0; i<${Num}; ++i)); do 
  vmName=`az vm list --query "[$i].[name, resourceGroup]" -o tsv | sed -n 1p`
  rgName=`az vm list --query "[$i].[name, resourceGroup]" -o tsv | sed -n 2p`
  extensionName=`az vm extension list --resource-group ${rgName} --vm-name ${vmName} --query "[].[id, name, typeHandlerVersion]" -o tsv | cut -f2`
  extensionVersion=`az vm extension list --resource-group ${rgName} --vm-name ${vmName} --query "[].[id, name, typeHandlerVersion]" -o tsv | cut -f3`
  echo ${vmName}, ${extensionName}, ${extensionVersion}
done
