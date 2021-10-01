#!/bin/bash

# Sign in with Azure CLI
#az login --use-device-code

# Create a Resource Group
rg_name=testubunturg
region_name=eastasia
az group create --name ${rg_name} --location ${region_name} 

# Create the Load Balancer Resource
lb_name=myLoadBalancer
publicip_name=myPublicIP
frontend_name=myFrontEnd
backendpool_name=myBackEndPool

az network lb create \
    --resource-group ${rg_name} \
    --name ${lb_name} \
    --sku Standard \
    --public-ip-address ${publicip_name} \
    --frontend-ip-name ${frontend_name} \
    --backend-pool-name ${backendpool_name} 

# Deploy a virtual machine scale set with existing load balancer
vmss_name=myScaleSet
image_name=UbuntuLTS
admin_username=azureuser

az vmss create \
    --resource-group ${rg_name} \
    --name ${vmss_name} \
    --image ${image_name} \
    --admin-username ${admin_username} \
    --generate-ssh-keys  \
    --upgrade-policy-mode Manual \
    --instance-count 2 \
    --lb ${lb_name} \
    --backend-pool-name ${backendpool_name}

# Create a Public IP Prefix Resource.
ipprefix_name=MyPublicIPPrefix

az network public-ip prefix create --length 30 --location ${region_name} --name ${ipprefix_name} --resource-group ${rg_name} 

# List public IP prefix resources.
az network public-ip prefix list -o table

# Get the details of a public IP prefix resource.
subscription_id='<Subscription ID>'
az network public-ip prefix show --name ${ipprefix_name} --resource-group ${rg_name} --subscription ${subscription_id} 
az network public-ip prefix show --name ${ipprefix_name} --resource-group ${rg_name} --subscription ${subscription_id} --query id

# Add Public IP Prefix to VMSS Instances
az vmss update -n ${vmss_name} -g ${rg_name} --set virtualMachineProfile.networkProfile.networkInterfaceConfigurations[0].ipConfigurations[0].publicIpAddressConfiguration.name='pub1' \
virtualMachineProfile.networkProfile.networkInterfaceConfigurations[0].ipConfigurations[0].publicIpAddressConfiguration.idleTimeoutInMinutes=15

az vmss update -n ${vmss_name} -g ${rg_name} --set virtualMachineProfile.networkProfile.networkInterfaceConfigurations[0].ipConfigurations[0].publicIpAddressConfiguration.publicIpPrefix.id='/subscriptions/a76944aa-xxxx-xxxx-xxxx-ee3731eb8cec/resourcegroups/testubunturg/providers/Microsoft.Network/publicipprefixes/MyPublicIPPrefix' \
virtualMachineProfile.networkProfile.networkInterfaceConfigurations[0].ipConfigurations[0].publicIpAddressConfiguration.publicIpPrefix.resourceGroup=${rg_name}

# List public IP prefix resources
az network public-ip prefix list --resource-group ${rg_name} --subscription ${subscription_id} -o table

# List public IP addresses of VM instances within a set.
az vmss list-instance-public-ips --name ${vmss_name} --resource-group ${rg_name} -o table
