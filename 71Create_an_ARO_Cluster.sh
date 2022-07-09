#/bin/sh

#References
## Tutorial: Create an Azure Red Hat OpenShift 4 cluster
## https://docs.microsoft.com/en-us/azure/openshift/tutorial-create-cluster
## Enable FIPS for an Azure Red Hat OpenShift cluster
## https://docs.microsoft.com/en-us/azure/openshift/howto-enable-fips-openshift
## az aro
## https://docs.microsoft.com/en-us/cli/azure/aro?view=azure-cli-latest

RESOURCEGROUP=myAROResourceGroup
CLUSTER=myAROCluster
LOCATION=eastasia

az provider register -n Microsoft.RedHatOpenShift --wait

az vm list-usage -l $LOCATION \
--query "[?contains(name.value, 'standardDSv3Family')]" \
-o table

az group create -n $RESOURCEGROUP -l $LOCATION

az network vnet create \
   --resource-group $RESOURCEGROUP \
   --name aro-vnet \
   --address-prefixes 10.0.0.0/22

az network vnet subnet create \
  --resource-group $RESOURCEGROUP \
  --vnet-name aro-vnet \
  --name master-subnet \
  --address-prefixes 10.0.0.0/23 \
  --service-endpoints Microsoft.ContainerRegistry

az network vnet subnet create \
  --resource-group $RESOURCEGROUP \
  --vnet-name aro-vnet \
  --name worker-subnet \
  --address-prefixes 10.0.2.0/23 \
  --service-endpoints Microsoft.ContainerRegistry

az network vnet subnet update \
  --name master-subnet \
  --resource-group $RESOURCEGROUP \
  --vnet-name aro-vnet \
  --disable-private-link-service-network-policies true

az aro create \
  --resource-group $RESOURCEGROUP \
  --name $CLUSTER \
  --vnet aro-vnet \
  --master-subnet master-subnet \
  --worker-subnet worker-subnet \
  --fips-validated-modules true
