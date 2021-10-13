#!/bin/bash

# Reference
## https://docs.microsoft.com/en-us/azure/load-balancer/quickstart-load-balancer-standard-public-cli?tabs=option-1-create-load-balancer-standard
## https://docs.microsoft.com/en-us/azure/virtual-machine-scale-sets/quick-create-cli
## https://docs.microsoft.com/en-us/cli/azure/vmss?view=azure-cli-latest
## https://docs.microsoft.com/en-us/azure/load-balancer/howto-load-balancer-imds?tabs=linux

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

# List public IP prefix resources and show the Public IP Prefix info.
az network public-ip prefix list -o table

az network public-ip prefix show --resource-group ${rg_name} --name ${ipprefix_name}

# Get the details of a public IP prefix resource and resource ID.
subscription_id='<Subscription ID>'
az network public-ip prefix show --name ${ipprefix_name} --resource-group ${rg_name} --subscription ${subscription_id} 
az network public-ip prefix show --name ${ipprefix_name} --resource-group ${rg_name} --subscription ${subscription_id} --query id

# Add Public IP Prefix to VMSS Instances
ipprefix_resourceid='<Public IP Prefix Resource ID>'

az vmss update -n ${vmss_name} -g ${rg_name} --set virtualMachineProfile.networkProfile.networkInterfaceConfigurations[0].ipConfigurations[0].publicIpAddressConfiguration.name='pub1' \
virtualMachineProfile.networkProfile.networkInterfaceConfigurations[0].ipConfigurations[0].publicIpAddressConfiguration.idleTimeoutInMinutes=15

az vmss update -n ${vmss_name} -g ${rg_name} --set virtualMachineProfile.networkProfile.networkInterfaceConfigurations[0].ipConfigurations[0].publicIpAddressConfiguration.publicIpPrefix.id=${ipprefix_resourceid} \
virtualMachineProfile.networkProfile.networkInterfaceConfigurations[0].ipConfigurations[0].publicIpAddressConfiguration.publicIpPrefix.resourceGroup=${rg_name}

# List public IP prefix resources
az network public-ip prefix list --resource-group ${rg_name} --subscription ${subscription_id} -o table

# List public IP addresses of VM instances within a set.
az vmss list-instance-public-ips --name ${vmss_name} --resource-group ${rg_name} -o table

# Retrieve load balancer metadata using the Azure Instance Metadata Service (IMDS) and public IP address of Instance of VMSS
curl -H "Metadata:true" --noproxy "*" "http://169.254.169.254:80/metadata/loadbalancer?api-version=2020-10-01"
