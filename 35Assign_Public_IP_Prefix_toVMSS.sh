#!/bin/bash

## Create a Public IP Prefix Resource.
```bash
region_name=japaneast
ipprefix_name=MyPublicIPPrefix
rg_name=testUbuntuRg
az network public-ip prefix create --length 28 --location ${region_name} --name ${ipprefix} --resource-group ${rg_name} 
```
## Add Public IP Prefix to VMSS Instances
```bash
vmss_name=myScalSet1
az vmss update -n ${vmss_name} -g ${rg_name} \
--set virtualMachineProfile.networkProfile.networkInterfaceConfigurations[0].ipConfigurations[0].publicIpAddressConfiguration.name='PIP1' virtualMachineProfile.networkProfile.networkInterfaceConfigurations[0].ipConfigurations[0].publicIpAddressConfiguration.idleTimeoutInMinutes=15
```
