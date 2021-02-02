#!/bin/bash
## Find Linux VM images in the Azure Marketplace with the Azure CLI
## https://docs.microsoft.com/en-us/azure/virtual-machines/linux/cli-ps-findimage

# List popular images
az vm image list --output table 

# Find specific images
az vm image list --offer Debian --all --output table

# Lists all Debian 8 SKUs in the West Eurpoe location
az vm image list --location westeurope --offer Deb --publisher credativ --sku 8 --all --output table

# Navigate the images
# Lists the image publishers in the West US location
az vm image list-publishers --location westus --output table

# Pass the location and the publisher 
az vm image list-offers --location westus --publisher Canonical --output table

# Check the SKUs
az vm image list-skus --location westus --publisher Canonical --offer UbuntuServer --output table

# Find a secific version of the SKU you want
az vm image list --location westus --publisher Canonical --offer UbuntuServer --sku 18.04-LTS --all --output table
