#!/bin/sh

## https://learn.microsoft.com/en-us/azure/openshift/tutorial-create-cluster
## https://learn.microsoft.com/en-us/azure/openshift/tutorial-connect-cluster
## https://learn.microsoft.com/en-us/azure/openshift/configure-azure-ad-ui
## https://learn.microsoft.com/en-us/azure/openshift/configure-azure-ad-cli
## https://docs.openshift.com/dedicated/3/admin_guide/manage_users.html
## https://onlyutkarsh.medium.com/fix-an-authentication-error-occurred-in-azure-red-hat-openshift-2cce36a1c760
## https://intelequia.com/blog/post/using-custom-claim-mappings-on-dnn-azure-ad-module
## https://learn.microsoft.com/en-us/azure/active-directory/develop/saml-claims-customization
## https://github.com/MicrosoftDocs/azure-docs/issues/111874

location=japaneast
resource_group=myaroResourceGroup

az group create --name $resource_group --location $location

az network vnet create \
   --resource-group $resource_group \
   --name aro-vnet \
   --address-prefixes 10.0.0.0/22
   
az network vnet subnet create \
  --resource-group $resource_group \
  --vnet-name aro-vnet \
  --name master-subnet \
  --address-prefixes 10.0.0.0/23   
  
az network vnet subnet create \
  --resource-group $resource_group \
  --vnet-name aro-vnet \
  --name worker-subnet \
  --address-prefixes 10.0.2.0/23  

aro_cluster=myaroCluster
az aro create \
  --resource-group $resource_group \
  --name $aro_cluster \
  --vnet aro-vnet \
  --master-subnet master-subnet \
  --worker-subnet worker-subnet

az aro list-credentials \
  --name $aro_cluster \
  --resource-group $resource_group
  
{
  "kubeadminPassword": "kCcmm-xxxxxx-xxxxx-xxxxx",
  "kubeadminUsername": "kubeadmin"
}

az aro show \
    --name $aro_cluster \
    --resource-group $resource_group \
    --query "consoleProfile.url" -o tsv  

https://console-openshift-console.apps.qre3ydzt.japaneast.aroapp.io/

aro-test-auth-0630
Application (client) ID: f2e47c59-xxxx-xxxx-xxxx-xxxxxxxxxxxx
Directory (tanant) ID: 72f988bf-xxxx-xxxx-xxxx-xxxxxxxxxxxx

# The format of the oauthCallbackURL is slightly different with custom domains:
# If you are not using a custom domain then the $domain will be an eight character alnum string and is extended by $location.aroapp.io.
domain=$(az aro show -g $resource_group -n $aro_cluster --query clusterProfile.domain -o tsv)
location=$(az aro show -g $resource_group -n $aro_cluster --query location -o tsv)
oauthCallbackURL=https://oauth-openshift.apps.$domain.$location.aroapp.io/oauth2callback/AAD

https://oauth-openshift.apps.qre3ydzt.japaneast.aroapp.io/oauth2callback/AAD

aro-test-auth-0630-secret
xxxxxxxxxxxxzT3BDPmaoWg5nJDLxxxxxxxxxxxx

app_id="f2e47c59-xxxx-xxxx-xxxx-xxxxxxxxxxxx"

az ad app permission add \
 --api 00000002-0000-0000-c000-000000000000 \
 --api-permissions 311a71cc-xxxx-xxxx-xxxx-xxxxxxxxxxxx=Scope \
 --id $app_id
 
# Issuer URL is https://login.microsoftonline.com/<tenant id>

https://login.microsoftonline.com/72f988bf-xxxx-xxxx-xxxx-xxxxxxxxxxxx
https://login.microsoftonline.com/72f988bf-xxxx-xxxx-xxxx-xxxxxxxxxxxx/v2.0

apiServer=$(az aro show -g $resource_group -n $aro_cluster --query apiserverProfile.url -o tsv)

oc login $apiServer -u kubeadmin -p <PASSWORD>

oc get user
oc delete user <USER_NAME> 
oc get identity
oc delete identity <IDENTITY_ID>
