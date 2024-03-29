#!/bin/bash

## Find Linux VM images in the Azure Marketplace with the Azure CLI
## https://docs.microsoft.com/en-us/azure/virtual-machines/linux/cli-ps-findimage

# List popular images
az vm image list --output table 

# List all publishers in the West US region.
az vm image list-publishers -l westus

# Find specific images
az vm image list --offer Debian --all --output table

# Lists all Debian 8 SKUs in the West Eurpoe location
az vm image list --location westeurope --offer Debian --publisher credativ --sku 8 --all --output table

# Navigate the images
# Lists the image publishers in the West US location
az vm image list-publishers --location westus --output table

# Pass the location and the publisher 
az vm image list-offers --location westus --publisher Canonical --output table
az vm image list-offers --location westus --publisher OpenLogic --output table
az vm image list-offers --location westus --publisher MicrosoftWindowsDesktop --output table
az vm image list-offers --location westus --publisher MicrosoftWindowsServer --output table
az vm image list-offers --location westus --publisher RedHat --output table
az vm image list-offers --location westus --publisher SUSE --output table

# Check the SKUs
az vm image list-skus --location westus --publisher Canonical --offer UbuntuServer --output table
az vm image list-skus --location eastus --publisher OpenLogic --offer CentOS --output table
az vm image list-skus --location westus --publisher MicrosoftWindowsDesktop --offer windows-7 --output table
az vm image list-skus --location westus --publisher MicrosoftWindowsDesktop --offer windows-10 --output table
az vm image list-skus --location westus --publisher MicrosoftWindowsServer --offer WindowsServer --output table
az vm image list-skus --location eastus --publisher RedHat --offer RHEL --output table
az vm image list-skus --location eastus --publisher RedHat --offer rhel-raw --output table
az vm image list-skus --location eastus --publisher SUSE --offer sles-15-sp3 --output table

# Find a secific version of the SKU you want
az vm image list --location westus --publisher Canonical --offer UbuntuServer --sku 18.04-LTS --all --output table
az vm image list --location westus --publisher OpenLogic --offer CentOS --sku 7_4 --all --output table
az vm image list --location westus --publisher MicrosoftWindowsDesktop --offer windows-7 --sku win7-enterprise --all --output table
az vm image list --location westus --publisher MicrosoftWindowsDesktop --offer windows-10 --sku 19h2-ent --all --output table
az vm image list --location westus --publisher MicrosoftWindowsServer --offer WindowsServer --sku 2022-datacenter-azure-edition-core --all --output table
az vm image list --location westus --publisher RedHat --offer RHEL --sku 8_3 --all --output table
az vm image list --location westus --publisher RedHat --offer RHEL --sku 8_4 --all --output table
az vm image list --location westus --publisher RedHat --offer RHEL --sku 8-lvm --all --output table
az vm image list --location westus --publisher RedHat --offer rhel-raw --sku 8_3 --all --output table
az vm image list --location westus --publisher RedHat --offer RHEL --sku 6.10 --all --output table
az vm image list --location westus --publisher SUSE --offer sles-15-sp3 --sku gen1 --all --output table
