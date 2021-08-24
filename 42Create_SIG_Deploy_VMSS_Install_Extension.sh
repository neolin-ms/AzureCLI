#!/bin/bash

## https://ifi.tech/2021/03/25/application-deployment-to-vmss-using-azure-devops/
## https://docs.microsoft.com/en-us/azure/service-fabric/service-fabric-diagnostics-oms-agent 

# Create Resource Group, Image and SIG
az group create --name myGalleryRG --location eastasia
az sig create --resource-group myGalleryRG --gallery-name myGallery

az sig image-definition create \
   --resource-group myGalleryRG \
   --gallery-name myGallery \
   --gallery-image-definition myImageDefinition \
   --publisher myPublisher \
   --offer myOffer \
   --sku mySKU \
   --os-type Linux \
   --os-state specialized

az sig image-version create \
   --resource-group myGalleryRG \
   --gallery-name myGallery \
   --gallery-image-definition myImageDefinition \
   --gallery-image-version 1.0.0 \
   --target-regions "eastasia=1" \
   --managed-image "/subscriptions/a76944aa-xxxx-xxxx-xxxx-xxxxxxxxxxxx/resourceGroups/testUbuntuRg/providers/Microsoft.Compute/virtualMachines/myUbuntu1804vm0726"

# Create VMSS and deploy instance by use the image of SIG
az vmss create \
   --resource-group testUbuntuRg \
   --name myScaleSet \
   --image "/subscriptions/a76944aa-xxxx-xxxx-xxxx-xxxxxxxxxxxx/resourceGroups/myGalleryRG/providers/Microsoft.Compute/galleries/myGallery/images/myImageDefinition" \
   --specialized
   
# Install the Linux Diagnostic extension on instances of VMSS
az vm extension set --publisher Microsoft.Azure.Diagnostics --name LinuxDiagnostic --version 4.0 --resource-group testUbuntuRg --vm-name <vm_name> --protected-settings ProtectedSettings.json --settings PublicSettings.json   


my_resource_group=testUbuntuRg
my_linux_vmss=myScaleSet
my_diagnostic_storage_account=myscalesetsa0726

az vmss identity assign -g $my_resource_group -n $my_linux_vmss

wget https://raw.githubusercontent.com/Azure/azure-linux-extensions/master/Diagnostic/tests/lad_2_3_compatible_portal_pub_settings.json -O portal_public_settings.json

my_vmss_resource_id=$(az vmss show -g $my_resource_group -n $my_linux_vmss --query "id" -o tsv)

sed -i "s#__DIAGNOSTIC_STORAGE_ACCOUNT__#$my_diagnostic_storage_account#g" portal_public_settings.json
sed -i "s#__VM_RESOURCE_ID__#$my_vmss_resource_id#g" portal_public_settings.json

my_diagnostic_storage_account_sastoken=$(az storage account generate-sas --account-name $my_diagnostic_storage_account --expiry 2037-12-31T23:59:00Z --permissions wlacu --resource-types co --services bt -o tsv)
my_lad_protected_settings="{'storageAccountName': '$my_diagnostic_storage_account', 'storageAccountSasToken': '$my_diagnostic_storage_account_sastoken'}"

az vmss extension set \
  --publisher Microsoft.Azure.Diagnostics \
  --name LinuxDiagnostic \
  --version 4.0 \
  --resource-group $my_resource_group \
  --vmss-name $my_linux_vmss \
  --protected-settings "${my_lad_protected_settings}" \
  --settings portal_public_settings.json

## Install the Log Analytics extension
az vmss extension set \
  --resource-group <nameOfResourceGroup> \
  --vmss-name <nameOfNodeType> \
  --name OmsAgentForLinux \
  --publisher Microsoft.EnterpriseCloud.Monitoring \ 
  --settings "{'workspaceId':'<Log AnalyticsworkspaceId>'}" \
  --protected-settings "{'workspaceKey':'<Log AnalyticsworkspaceKey>'}"
