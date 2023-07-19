#!/bin/bash

## https://learn.microsoft.com/en-us/azure/aks/csi-secrets-store-identity-access
## https://learn.microsoft.com/en-us/azure/active-directory/workload-identities/workload-identity-federation-considerations#errors
## https://learn.microsoft.com/en-us/azure/aks/workload-identity-overview
## https://learn.microsoft.com/en-us/azure/key-vault/general/quick-create-cli
## https://learn.microsoft.com/en-us/azure/aks/csi-secrets-store-driver

## Deploy and configure workload identity on an Azure Kubernetes Service (AKS) cluster
export RESOURCE_GROUP="neoResourceGroup"
export LOCATION="japaneast"
export SERVICE_ACCOUNT_NAMESPACE="default"
export SERVICE_ACCOUNT_NAME="workload-identity-sa"
export SUBSCRIPTION="$(az account show --query id --output tsv)"
export USER_ASSIGNED_IDENTITY_NAME="myIdentity071923"
export FEDERATED_IDENTITY_CREDENTIAL_NAME="myFedIdentity"
export CLUSTER_NAME="neoAKSCluster"

## Update an existing AKS cluster
az aks update -g ${RESOURCE_GROUP} -n ${CLUSTER_NAME} --enable-oidc-issuer --enable-workload-identity

## Retrieve the OIDC Issuer URL
export AKS_OIDC_ISSUER="$(az aks show -n ${CLUSTER_NAME} -g "${RESOURCE_GROUP}" --query "oidcIssuerProfile.issuerUrl" -otsv)"

## Create a managed identity
az identity create --name "${USER_ASSIGNED_IDENTITY_NAME}" --resource-group "${RESOURCE_GROUP}" --location "${LOCATION}" --subscription "${SUBSCRIPTION}"

export USER_ASSIGNED_CLIENT_ID="$(az identity show --resource-group "${RESOURCE_GROUP}" --name "${USER_ASSIGNED_IDENTITY_NAME}" --query 'clientId' -otsv)"

## Create Kubernetes service account
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  annotations:
    azure.workload.identity/client-id: "${USER_ASSIGNED_CLIENT_ID}"
  name: "${SERVICE_ACCOUNT_NAME}"
  namespace: "${SERVICE_ACCOUNT_NAMESPACE}"
EOF

## Establish federated identity credential
az identity federated-credential create --name ${FEDERATED_IDENTITY_CREDENTIAL_NAME} --identity-name "${USER_ASSIGNED_IDENTITY_NAME}" --resource-group "${RESOURCE_GROUP}" --issuer "${AKS_OIDC_ISSUER}" --subject system:serviceaccount:"${SERVICE_ACCOUNT_NAMESPACE}":"${SERVICE_ACCOUNT_NAME}" --audience api://AzureADTokenExchange

## Deploy your application
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: quick-start
  namespace: "${SERVICE_ACCOUNT_NAMESPACE}"
  labels:
    azure.workload.identity/use: "true"
spec:
  serviceAccountName: "${SERVICE_ACCOUNT_NAME}"
EOF

## Create a key vault using the Azure CLI
export kv_name=mykv0719
az keyvault create --name "${kv_name}" --resource-group "${RESOURCE_GROUP}" --location "EastAsia"

## Optional - Grant permissions to access Azure Key Vault


## Upgrade an existing AKS cluster with Azure Key Vault Provider for Secrets Store CSI Driver support
az aks enable-addons --addons azure-keyvault-secrets-provider --name ${CLUSTER_NAME} --resource-group ${RESOURCE_GROUP}

## Provide an identity to access the Azure Key Vault Provider for Secrets Store CSI Driver
export SUBSCRIPTION_ID="$(az account show --query id --output tsv)"
export RESOURCE_GROUP="neoResourceGroup"
export UAMI="myIdentity071923"
export KEYVAULT_NAME="mykv0719"
export CLUSTER_NAME="neoAKSCluster"

## Get managed identity and tenant
export USER_ASSIGNED_CLIENT_ID="$(az identity show -g $RESOURCE_GROUP --name $UAMI --query 'clientId' -o tsv)"
export IDENTITY_TENANT=$(az aks show --name $CLUSTER_NAME --resource-group $RESOURCE_GROUP --query identity.tenantId -o tsv)

## Set an access policy that grants the workload identity permission to access the Key Vault secrets
az keyvault set-policy -n $KEYVAULT_NAME --key-permissions get --spn $USER_ASSIGNED_CLIENT_ID
az keyvault set-policy -n $KEYVAULT_NAME --secret-permissions get --spn $USER_ASSIGNED_CLIENT_ID
az keyvault set-policy -n $KEYVAULT_NAME --certificate-permissions get --spn $USER_ASSIGNED_CLIENT_ID

## Deploy a SecretProviderClass
cat <<EOF | kubectl apply -f -
# This is a SecretProviderClass example using workload identity to access your key vault
apiVersion: secrets-store.csi.x-k8s.io/v1
kind: SecretProviderClass
metadata:
  name: default # needs to be unique per namespace
spec:
  provider: azure
  parameters:
    usePodIdentity: "false"
    useVMManagedIdentity: "false"          
    clientID: "${USER_ASSIGNED_CLIENT_ID}" # Setting this to use workload identity
    keyvaultName: ${KEYVAULT_NAME}       # Set to the name of your key vault
    cloudName: ""                         # [OPTIONAL for Azure] if not provided, the Azure environment defaults to AzurePublicCloud
    objects:  |
      array:
        - |
          objectName: secret1
          objectType: secret              # object types: secret, key, or cert
          objectVersion: ""               # [OPTIONAL] object versions, default to latest if empty
        - |
          objectName: key1
          objectType: key
          objectVersion: ""
    tenantId: "${IDENTITY_TENANT}"        # The tenant ID of the key vault
EOF

## Deploy a sample pod
cat <<EOF | kubectl apply -f -
# This is a sample pod definition for using SecretProviderClass and the user-assigned identity to access your key vault
kind: Pod
apiVersion: v1
metadata:
  name: busybox-secrets-store-inline-user-msi
  labels:
    azure.workload.identity/use: "true"
spec:
  serviceAccountName: ${SERVICE_ACCOUNT_NAME}
  containers:
    - name: busybox
      image: registry.k8s.io/e2e-test-images/busybox:1.29-1 
      command:
        - "/bin/sleep"
        - "10000"
      volumeMounts:
      - name: secrets-store01-inline
        mountPath: "/mnt/secrets-store"
        readOnly: true
  volumes:
    - name: secrets-store01-inline
      csi:
        driver: secrets-store.csi.k8s.io
        readOnly: true
        volumeAttributes:
          secretProviderClass: "azure-kvname-workload-identity"
EOF

## Validate the secrets
## show secrets held in secrets-store
kubectl exec busybox-secrets-store-inline-user-msi -- ls /mnt/secrets-store/

## print a test secret 'ExampleSecret' held in secrets-store
kubectl exec busybox-secrets-store-inline-user-msi -- cat /mnt/secrets-store/key0719
kubectl exec busybox-secrets-store-inline-user-msi -- cat /mnt/secrets-store/secret0719
