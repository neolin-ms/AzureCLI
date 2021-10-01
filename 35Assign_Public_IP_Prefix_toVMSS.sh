#!/bin/bash

## Create a Resource Group
```bash
rg_name=testubunturg
region_name=eastasia
```

## Create a Load Balancer
```bash
lb_name=myScalSetlb
```

## Deploy a virtual machine scale set with existing load balancer
```bash
vmss_name=myScaleSet
az vmss create \
    --resource-group <resource-group> \
    --name <vmss-name>\
    --image <your-image> \
    --admin-username <admin-username> \
    --generate-ssh-keys  \
    --upgrade-policy-mode Automatic \
    --instance-count 3 \
    --vnet-name <virtual-network-name> \
    --subnet <subnet-name> \
    --lb <load-balancer-name> \
    --backend-pool-name <backend-pool-name>
```

## Create a Public IP Prefix Resource.
```bash
ipprefix_name=MyPublicIPPrefix
rg_name=testUbuntuRg
az network public-ip prefix create --length 28 --location ${region_name} --name ${ipprefix_name} --resource-group ${rg_name} 
```

## List public IP prefix resources.
```bash
az network public-ip prefix list -o table
```

## Get the details of a public IP prefix resource.
```bash
subscription_id='<Subscription ID>'
az network public-ip prefix show --name ${ipprefix_name} --resource-group ${rg_name} --subscription ${subscription_id} 
az network public-ip prefix show --name ${ipprefix_name} --resource-group ${rg_name} --subscription ${subscription_id} --query id
```

## Add Public IP Prefix to VMSS Instances
```bash
vmss_name=myScalSet1

az vmss update -n ${vmss_name} -g ${rg_name} --set virtualMachineProfile.networkProfile.networkInterfaceConfigurations[0].ipConfigurations[0].publicIpAddressConfiguration.name='pub1' \
virtualMachineProfile.networkProfile.networkInterfaceConfigurations[0].ipConfigurations[0].publicIpAddressConfiguration.idleTimeoutInMinutes=15

az vmss update -n ${vmss_name} -g ${rg_name} --set virtualMachineProfile.networkProfile.networkInterfaceConfigurations[0].ipConfigurations[0].publicIpAddressConfiguration.publicIpPrefix.id='/subscriptions/a76944aa-xxxx-xxxx-xxxx-ee3731eb8cec/resourcegroups/testubunturg/providers/Microsoft.Network/publicipprefixes/MyPublicIPPrefix' \
virtualMachineProfile.networkProfile.networkInterfaceConfigurations[0].ipConfigurations[0].publicIpAddressConfiguration.publicIpPrefix.resourceGroup=${rg_name}
```

## List public IP prefix resources
```bash
az network public-ip prefix list --resource-group ${rg_name} --subscription ${subscription_id} -o table
```

## List public IP addresses of VM instances within a set.
```bash
az vmss list-instance-public-ips --name ${vmss_name} --resource-group ${rg_name} -o table
```
