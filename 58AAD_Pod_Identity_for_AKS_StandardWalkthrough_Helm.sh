
# AZURE ACTIVE DIRECTORY POD IDENTITY FOR KUBERNETES - Standard Walkthrough - Part 2 Helm
# https://azure.github.io/aad-pod-identity/docs/demo/standard_walkthrough/

# 0. Create a resource group and AKS cluster
export SUBSCRIPTION_ID="60796668-xxxx-xxxx-xxxx-74f9e7dba880"

## login as a user and set the appropriate subscription ID
az login
az account set -s "${SUBSCRIPTION_ID}"

export RESOURCE_GROUP="neoResourceGroup"
export CLUSTER_NAME="neoAKSClsuter"

az group create --name ${RESOURCE_GROUP} --location eastasia
az aks create -g ${RESOURCE_GROUP} -n ${CLUSTER_NAME} --node-count 1 --network-plugin azure --generate-ssh-keys
az aks create -g ${RESOURCE_GROUP} -n ${CLUSTER_NAME} --node-count 1 --enable-pod-identity --network-plugin azure --generate-ssh-keys
az aks get-credentials --resource-group ${RESOURCE_GROUP} --name ${CLUSTER_NAME}

## for this demo, we will be deploying a user-assigned identity to the AKS node resource group
export IDENTITY_RESOURCE_GROUP="$(az aks show -g ${RESOURCE_GROUP} -n ${CLUSTER_NAME} --query nodeResourceGroup -otsv)"
export IDENTITY_NAME="demoidentity0517"

# 1. Deploy aad-pod-identity by Helm
helm repo add aad-pod-identity https://raw.githubusercontent.com/Azure/aad-pod-identity/master/charts
helm repo update
helm install aad-pod-identity aad-pod-identity/aad-pod-identity

## To verify that AAD Pod Identity has started in standard mode, run:
## kubectl --namespace=default get pods -l "app.kubernetes.io/component=mic"
## kubectl --namespace=default get pods -l "app.kubernetes.io/component=nmi"

## Now you can follow the demos to get familiar with AAD Pod Identity: https://azure.github.io/aad-pod-identity/docs/demo/

# 2. Create an identity on Azure
az identity create -g ${IDENTITY_RESOURCE_GROUP} -n ${IDENTITY_NAME}
## Output
{
"clientId": "a7155ffd-xxxx-xxxx-xxxx-d40f7e421b3f",
"clientSecretUrl": "https://control-eastasia.identity.azure.net/subscriptions/60796668-xxxx-xxxx-xxxx-74f9e7dba880/resourcegroups/MC_neoResourceGroup_neoAKSClsuter_eastasia/providers/Microsoft.ManagedIdentity/userAssignedIdentities/demoidentity0517/credentials?tid=72f988bf-xxxx-xxxx-xxxx-2d7cd011db47&oid=87cc7be0-xxxx-xxxx-xxxx-a3cd4043ad82&aid=a7155ffd-xxxx-xxxx-xxxx-d40f7e421b3f",
"id": "/subscriptions/60796668-xxxx-xxx-xxxx-74f9e7dba880/resourcegroups/MC_neoResourceGroup_neoAKSClsuter_eastasia/providers/Microsoft.ManagedIdentity/userAssignedIdentities/demoidentity0517",   "location": "eastasia",
"name": "demoidentity0517",
"principalId": "87cc7be0-xxxx-xxxx-xxxx-a3cd4043ad82",
"resourceGroup": "MC_neoResourceGroup_neoAKSClsuter_eastasia",
"tags": {},
"tenantId": "72f988bf-xxxx-xxxx-xxxx-2d7cd011db47",
"type": "Microsoft.ManagedIdentity/userAssignedIdentities"
}

export IDENTITY_CLIENT_ID="$(az identity show -g ${IDENTITY_RESOURCE_GROUP} -n ${IDENTITY_NAME} --query clientId -o tsv)"
export IDENTITY_RESOURCE_ID="$(az identity show -g ${IDENTITY_RESOURCE_GROUP} -n ${IDENTITY_NAME} --query id -o tsv)"

export NODE_GROUP=$(az aks show -g ${RESOURCE_GROUP} -n ${CLUSTER_NAME} --query nodeResourceGroup -o tsv)
export NODES_RESOURCE_ID=$(az group show -n $NODE_GROUP -o tsv --query "id")
az role assignment create --role "Virtual Machine Contributor" --assignee "$IDENTITY_CLIENT_ID" --scope $NODES_RESOURCE_ID

# 3 Role Assignment
curl -s https://raw.githubusercontent.com/Azure/aad-pod-identity/master/hack/role-assignment.sh | bash

# 4. Deploy AzureIdentity 
cat <<EOF | kubectl apply -f -
apiVersion: "aadpodidentity.k8s.io/v1"
kind: AzureIdentity
metadata:
  name: ${IDENTITY_NAME}
spec:
  type: 0
  resourceID: ${IDENTITY_RESOURCE_ID}
  clientID: ${IDENTITY_CLIENT_ID}
EOF

# 5. (Optional) Match pods in the namespace 

# 6. Deploy AzureIdentityBinding 
cat <<EOF | kubectl apply -f -
apiVersion: "aadpodidentity.k8s.io/v1"
kind: AzureIdentityBinding
metadata:
  name: ${IDENTITY_NAME}-binding
spec:
  azureIdentity: ${IDENTITY_NAME}
  selector: ${IDENTITY_NAME}
EOF

# 7. Deployment and Validation 
cat << EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: demo
  labels:
    aadpodidbinding: $IDENTITY_NAME
spec:
  containers:
  - name: demo
    image: mcr.microsoft.com/oss/azure/aad-pod-identity/demo:v1.8.8
    args:
      - --subscription-id=${SUBSCRIPTION_ID}
      - --resource-group=${IDENTITY_RESOURCE_GROUP}
      - --identity-client-id=${IDENTITY_CLIENT_ID}
  nodeSelector:
    kubernetes.io/os: linux
EOF

kubectl logs demo
## Output
I0517 09:16:46.655847       1 main.go:98] curl -H Metadata:true "http://169.254.169.254/metadata/instance?api-version=2017-08-01": {"compute":{"location":"eastasia","name":"aks-nodepool1-18128784-vmss_0","offer":"","osType":"Linux","placementGroupId":"a4e87672-xxxx-xxxx-xxxx-c4f5115d4b9a","platformFaultDomain":"0","platformUpdateDomain":"0","publisher":"","resourceGroupName":"MC_neoResourceGroup_neoAKSClsuter_eastasia","sku":"","subscriptionId":"60796668-xxxx-xxxx-xxxx-74f9e7dba880"
I0517 09:16:48.646754       1 main.go:70] successfully acquired a service principal token from IMDS using a user-assigned identity (a7155ffd-7d86-4f28-8af2-d40f7e421b3f)
I0517 09:16:48.646782       1 main.go:43] Try decoding your token xxxxxxxxxxxxV1QiLCJhbGciOiJSUzI1NiIsIng1dCI6ImpTMVhvMU9XRGpfNTJ2YndHTmd2UU8yVnpNYyIsImtpZCI6ImpTMVxxxx
