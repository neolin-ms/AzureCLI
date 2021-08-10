#!/bin/bash

//==Create VM

LOCATION="eastasia"
RGNAME="testWindowsRg"
VMNAME="myWin2019vm0622"

az group create --name ${RGNAME} --location ${LOCATION} 

az vm create \
    --resource-group ${RGNAME} \
    --name ${VMNAME} \
    --image win2019datacenter \
    --admin-username azureuser

//==Create KV and KEK

KVRGNAME="testKvRg"
KVNAME="testmyKv20210702"
KEYNAME="testmykey20210702"

az group create --name ${KVRGNAME} --location ${LOCATION}

az keyvault create --name ${KVNAME} --resource-group ${KVRGNAME} --location ${LOCATION} --enabled-for-disk-encryption
	
az keyvault show -n ${KVNAME} --query id -o tsv
/subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/resourceGroups/testKvRg/providers/Microsoft.KeyVault/vaults/testmyKv06222021

az keyvault key create --name ${KEYNAME} --vault-name ${KVNAME} --kty RSA

az keyvault key show --vault-name ${KVNAME} --name ${KEYNAME} --query key.kid -o tsv
https://testmykv06222021.vault.azure.net/keys/testmykey0622/xxxxxxxxxxxxxxxx

//==Show Disk Encryption Status

az vm encryption show --name ${VMNAME} --resource-group ${RGNAME} --query "status" -o table

az vm encryption show -g ${RGNAME} -n ${VMNAME} --query "disks[*].[name, statuses[*].displayStatus]" -o table

osDisk=`az vm show -d -g ${RGNAME} -n ${VMNAME} --query "storageProfile.osDisk.name" -o tsv`
echo $osDisk
myVMWindows2019_disk1_xxxxxxxx

az vm show -d -g ${RGNAME} -n ${VMNAME} --query "storageProfile.dataDisks[].name" -o tsv
dataDisk0
dataDisk1

//==Show Disk Encryption Info

dataDisk0="dataDisk0"
dataDisk1="dataDisk1"

osDisk=`az vm show -g ${RGNAME} -n ${VMNAME} --query storageProfile.osDisk.name -o tsv`
az disk show -g ${RGNAME} -n ${osDisk} --query encryptionSettingsCollection.enabled
az disk show -g ${RGNAME} -n ${osDisk} --query encryptionSettingsCollection.encryptionSettingsVersion -o tsv
az disk show -g ${RGNAME} -n ${osDisk} --query encryptionSettingsCollection.encryptionSettings[].diskEncryptionKey.secretUrl -o tsv
az disk show -g ${RGNAME} -n ${osDisk} --query encryptionSettingsCollection.encryptionSettings[].keyEncryptionKey.keyUrl -o tsv

dataDisk0="dataDisk0"
az disk show -g ${RGNAME} -n ${dataDisk0} --query encryptionSettingsCollection.enabled
az disk show -g ${RGNAME} -n ${dataDisk0} --query encryptionSettingsCollection.encryptionSettingsVersion -o tsv
az disk show -g ${RGNAME} -n ${dataDisk0} --query encryptionSettingsCollection.encryptionSettings[].diskEncryptionKey.secretUrl -o tsv
az disk show -g ${RGNAME} -n ${dataDisk0} --query encryptionSettingsCollection.encryptionSettings[].keyEncryptionKey.keyUrl -o tsv

dataDisk1="dataDisk1"
az disk show -g ${RGNAME} -n ${dataDisk1} --query encryptionSettingsCollection.enabled
az disk show -g ${RGNAME} -n ${dataDisk1} --query encryptionSettingsCollection.encryptionSettingsVersion -o tsv
az disk show -g ${RGNAME} -n ${dataDisk1} --query encryptionSettingsCollection.encryptionSettings[].diskEncryptionKey.secretUrl -o tsv
az disk show -g ${RGNAME} -n ${dataDisk1} --query encryptionSettingsCollection.encryptionSettings[].keyEncryptionKey.keyUrl -o tsv

KVFULLSTRING="/subscriptions/xxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/resourceGroups/testKvRg/providers/Microsoft.KeyVault/vaults/testmyKv06222021"
KEKURI="https://testmykv06222021.vault.azure.net/keys/testmykey0622/xxxxxxxxx"

az vm encryption enable --resource-group ${RGNAME} --name ${VMNAME} --disk-encryption-keyvault ${KVFULLSTRING} --key-encryption-key ${KEKURI} --key-encryption-keyvault ${KVFULLSTRING} --volume-type [All|OS|Data]

az vm encryption enable --resource-group ${RGNAME} --name ${VMNAME} --disk-encryption-keyvault ${KVFULLSTRING} --key-encryption-key ${KEKURI} --key-encryption-keyvault ${KVFULLSTRING} --volume-type All

az vm encryption enable --resource-group ${RGNAME} --name ${VMNAME} --disk-encryption-keyvault ${KVFULLSTRING} --key-encryption-key ${KEKURI} --key-encryption-keyvault ${KVFULLSTRING} --volume-type OS

az vm encryption enable --resource-group ${RGNAME} --name ${VMNAME} --disk-encryption-keyvault ${KVFULLSTRING} --key-encryption-key ${KEKURI} --key-encryption-keyvault ${KVFULLSTRING} --volume-type Data

