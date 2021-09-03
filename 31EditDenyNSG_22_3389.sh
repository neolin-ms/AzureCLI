#!/bin/sh

# https://docs.microsoft.com/en-us/cli/azure/network/nsg?view=azure-cli-latest

# List network security groups.
```bash
az network nsg list --query "[?location=='eastasia']"
az network nsg list --query "[?Name]"
```

# Get information about a network security group.
```bash
rg_name=<ResourceGroup>
nsg_name=<NetworkSecurityGroup>
az network nsg show -g ${rg_name} -n ${nsg_name}
az network nsg list --query [].id -o tsv
```
