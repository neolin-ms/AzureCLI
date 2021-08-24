#!/bin/bash

## References
## https://ifi.tech/2021/03/25/application-deployment-to-vmss-using-azure-devops/
## https://docs.microsoft.com/en-us/azure/service-fabric/service-fabric-diagnostics-oms-agent 
## https://docs.microsoft.com/en-us/azure/azure-monitor/logs/quick-create-workspace-cli

# 1. Create Resource Group,and SIG
region_name=JapanEast
rg_name=testUbuntuRg
sig_name=myGallery

az group create --name ${rg_name} --location ${region_name}
az sig create --resource-group ${rg_name} --gallery-name ${sig_name} 

# 2. Create Linux VM  
vm_name=myUbuntu1804vm0824
vm_image=Canonical:UbuntuServer:18.04-LTS:18.04.202107200
vm_size=Standard_D4s_v3
vm_username=azureuser

az vm create \
  --resource-group ${rg_name} \
  --name ${vm_name} \
  --image ${vm_image} \
  --size ${vm_size} \
  --admin-username ${vm_username} \
  --generate-ssh-keys

# 3. Create dfinition for Linux, and image 
imagedefinition_name=myImageDefinition
publisher_name=myPublisher
offer_name=myOffer
sku_name=mySKU
os_type=Linux
os_state=specialized

az sig image-definition create \
   --resource-group ${rg_name} \
   --gallery-name ${sig_name} \
   --gallery-image-definition ${imagedefinition_name} \
   --publisher ${publisher_name} \
   --offer ${offer_name} \
   --sku ${sku_name} \
   --os-type ${os_type} \
   --os-state ${os_state}

managed_image=<VM_RESOURCE_URI>

az sig image-version create \
   --resource-group ${rg_name} \
   --gallery-name ${sig_name} \
   --gallery-image-definition ${imagedefinition_name} \
   --gallery-image-version 1.0.0 \
   --target-regions ${region_name}=1 \
   --managed-image ${managed_image}

# 4. Create VMSS and deploy instance by use the image of SIG
vmss_name=myScalSet
vmss_image=<IMAGE_DEFINITION_URI>

az vmss create \
   --resource-group ${rg_name} \
   --name ${vmss_name} \
   --image ${vmss_image} \
   --specialized
   
# 5. Install the Linux Diagnostic extension on instances of VMSS
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
  --resource-group ${rg_name} \
  --vmss-name ${vmss_name} \
  --protected-settings "${my_lad_protected_settings}" \
  --settings portal_public_settings.json

# 6. Create a Log Analytics workspace with AzureCLI 2.0
deployment_name=myDeployment

az deployment group create --resource-group ${rg_name} --name ${deployment_name} --template-file deploylaworkspacetemplate.json

# 7. Install the Log Analytics extension
workspace_id=<LOG_ANALYTICS_WORKSPACE_ID>
workspace_key=<LOG_ANALYTICS_WORKSPACE_Key>

az vmss extension set \
  --resource-group ${rg_name} \
  --vmss-name ${vmss_name} \
  --name OmsAgentForLinux \
  --publisher Microsoft.EnterpriseCloud.Monitoring \
  --settings "{'workspaceId':'${workspace_id}'}" \
  --protected-settings "{'workspaceKey':'workspace_key'}"
