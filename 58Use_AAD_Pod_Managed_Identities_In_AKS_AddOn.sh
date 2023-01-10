#!/bin/bash

# Azure Active Directory pod-managed identities in Azure Kubernetes Service (Preview)
# https://docs.microsoft.com/en-us/azure/aks/use-azure-ad-pod-identity

# Register the EnablePodIdentityPreview
az feature register --name EnablePodIdentityPreview --namespace Microsoft.ContainerService

# Install the aks-preview Azure CLI
## Install the aks-preview extension
az extension add --name aks-preview

## Update the extension to make sure you have the latest version installed
az extension update --name aks-preview

# Create an AKS cluster with Azure Container Networking Interface (CNI)
az group create --name neoResourceGroup --location eastus
az aks create -g neoResourceGroup -n neoAKSCluster --enable-pod-identity --network-plugin azure
az aks get-credentials --resource-group neoResourceGroup --name neoAKSCluster

# Create an identity
az group create --name myIdentity0516 --location eastus
export IDENTITY_RESOURCE_GROUP="myIdentity0516"
export IDENTITY_NAME="neo-application-identity"
az identity create --resource-group ${IDENTITY_RESOURCE_GROUP} --name ${IDENTITY_NAME}

{
	"clientId": "a6ff440f-xxxx-xxxx-xxxx-3dca911a1b97",
	"clientSecretUrl": "https://control-eastus.identity.azure.net/subscriptions/60796668-xxxx-xxxx-xxxx-74f9e7dba880/resourcegroups/myIdentityResourceGroup/providers/Microsoft.ManagedIdentity/userAssignedIdentities/neo-application-identity/credentials?tid=72f988bf-xxxx-xxxx-xxxx-2d7cd011db47&oid=cb9e251c-xxxx-xxxx-xxxx-18dce5074f11&aid=a6ff440f-xxxx-xxxx-xxxx-3dca911a1b97",
	"id": "/subscriptions/60796668-xxxx-xxxx-xxxx-74f9e7dba880/resourcegroups/myIdentityResourceGroup/providers/Microsoft.ManagedIdentity/userAssignedIdentities/neo-application-identity",
	"location": "eastus",
	"name": "neo-application-identity",
	"principalId": "cb9e251c-xxxx-xxxx-xxxx-18dce5074f11",
	"resourceGroup": "myIdentityResourceGroup",
	"tags": {},
	"tenantId": "72f988bf-xxxx-xxxx-xxxx-2d7cd011db47",
	"type": "Microsoft.ManagedIdentity/userAssignedIdentities"
}

export IDENTITY_CLIENT_ID="$(az identity show -g ${IDENTITY_RESOURCE_GROUP} -n ${IDENTITY_NAME} --query clientId -otsv)"
export IDENTITY_RESOURCE_ID="$(az identity show -g ${IDENTITY_RESOURCE_GROUP} -n ${IDENTITY_NAME} --query id -otsv)"

# Assign permissions for the managed identity
NODE_GROUP=$(az aks show -g neoResourceGroup -n neoAKSCluster --query nodeResourceGroup -o tsv)
NODES_RESOURCE_ID=$(az group show -n $NODE_GROUP -o tsv --query "id")
az role assignment create --role "Virtual Machine Contributor" --assignee "$IDENTITY_CLIENT_ID" --scope $NODES_RESOURCE_ID

# Create a pod identity
export POD_IDENTITY_NAME="my-pod-identity"
export POD_IDENTITY_NAMESPACE="my-app"
az aks pod-identity add --resource-group neoResourceGroup --cluster-name neoAKSCluster --namespace ${POD_IDENTITY_NAMESPACE}  --name ${POD_IDENTITY_NAME} --identity-resource-id ${IDENTITY_RESOURCE_ID}
kubectl get azureidentity -n $POD_IDENTITY_NAMESPACE
kubectl get azureidentitybinding -n $POD_IDENTITY_NAMESPACE

# Run a sample application
echo $POD_IDENTITY_NAME
my-pod-identity
echo $IDENTITY_CLIENT_ID
a6ff440f-xxxx-xxxx-xxxx-3dca911a1b97
echo $IDENTITY_RESOURCE_GROUP
myIdentityResourceGroup
SUBSCRIPTION_ID
60796668-xxxx-xxxx-xxxx-74f9e7dba880

nano demo_pod_identity.yaml
kubectl apply -f demo.yaml --namespace $POD_IDENTITY_NAMESPACE
kubectl logs demo --follow --namespace $POD_IDENTITY_NAMESPACE

I0512 08:47:49.089506       1 main.go:95] successfully acquired a token using the MSI, msiEndpoint(http://169.254.169.254/metadata/identity/oauth2/token)
I0512 08:47:49.106867       1 main.go:114] successfully acquired a token, userAssignedID MSI, msiEndpoint(http://169.254.169.254/metadata/identity/oauth2/token) clientID(a6ff440f-xxxx-xxxx-xxxx-3dca911a1b97)
I0512 08:47:49.119323       1 main.go:141] successfully made GET on instance metadata, {"compute"

# Run an application with multiple identities
az aks pod-identity add --resource-group myResourceGroup --cluster-name myAKSCluster --namespace ${POD_IDENTITY_NAMESPACE}  --name ${POD_IDENTITY_NAME_1} --identity-resource-id ${IDENTITY_RESOURCE_ID_1} --binding-selector myMultiIdentitySelector
az aks pod-identity add --resource-group myResourceGroup --cluster-name myAKSCluster --namespace ${POD_IDENTITY_NAMESPACE}  --name ${POD_IDENTITY_NAME_2} --identity-resource-id ${IDENTITY_RESOURCE_ID_2} --binding-selector myMultiIdentitySelector

# Clean up
