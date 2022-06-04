#  AZURE ACTIVE DIRECTORY POD IDENTITY FOR KUBERNETES - Standard Walkthrough
# https://azure.github.io/aad-pod-identity/docs/demo/standard_walkthrough/

# 0. Create a rsource group and AKS cluster and Azure-related environment variables 
az group create --name neolinResourceGroup --location eastus
az aks create --resource-group neolinResourceGroup --name neolinAKSCluster --node-count 1 --network-plugin azure --generate-ssh-keys
az aks get-credentials --resource-group neolinResourceGroup --name neolinAKSCluster

## login as a user and set the appropriate subscription ID
export SUBSCRIPTION_ID="<SubscriptionID>"
az login
az account set -s "${SUBSCRIPTION_ID}"
export RESOURCE_GROUP="neolinResourceGroup"
export CLUSTER_NAME="neolinAKSCluster"

## for this demo, we will be deploying a user-assigned identity to the AKS node resource group
export IDENTITY_RESOURCE_GROUP="$(az aks show -g ${RESOURCE_GROUP} -n ${CLUSTER_NAME} --query nodeResourceGroup -otsv)"
export IDENTITY_NAME="demoidentity"

# 1. Deploy aad-pod-identity, Deploy aad-pod-identity components to a non-RBAC cluster:

kubectl apply -f https://raw.githubusercontent.com/Azure/aad-pod-identity/master/deploy/infra/deployment.yaml

## For AKS clusters, deploy the MIC and AKS add-on exception by running -
kubectl apply -f https://raw.githubusercontent.com/Azure/aad-pod-identity/master/deploy/infra/mic-exception.yaml

# 2. Create an identity on Azure 
az identity create -g ${IDENTITY_RESOURCE_GROUP} -n ${IDENTITY_NAME}
## Output
{
"clientId": "3a88cf70-xxxx-xxxx-xxxx-2a9863cc99f7",
"clientSecretUrl": "https://control-eastus.identity.azure.net/subscriptions/60796668-xxxx-xxxx-xxxx-74f9e7dba880/resourcegroups/MC_neolinResourceGroup_neolinAKSCluster_eastus/providers/Microsoft.ManagedIdentity/userAssignedIdentities/demoidentity/credentials?tid=72f988bf-xxxx-xxxx-xxxx-2d7cd011db47&oid=1bf786dd-xxxx-xxxx-xxxx-70c984190578&aid=3a88cf70-xxxx-xxxx-xxxx-2a9863cc99f7",
"id": "/subscriptions/60796668-xxxx-xxxx-xxxx-74f9e7dba880/resourcegroups/MC_neolinResourceGroup_neolinAKSCluster_eastus/providers/Microsoft.ManagedIdentity/userAssignedIdentities/demoidentity",
"location": "eastus",
"name": "demoidentity",
"principalId": "1bf786dd-xxxx-xxxx-xxxx-70c984190578",
"resourceGroup": "MC_neolinResourceGroup_neolinAKSCluster_eastus",
"tags": {},
"tenantId": "72f988bf-xxxx-xxxx-xxxx-2d7cd011db47",
"type": "Microsoft.ManagedIdentity/userAssignedIdentities"
}

export IDENTITY_CLIENT_ID="$(az identity show -g ${IDENTITY_RESOURCE_GROUP} -n ${IDENTITY_NAME} --query clientId -otsv)"
export IDENTITY_RESOURCE_ID="$(az identity show -g ${IDENTITY_RESOURCE_GROUP} -n ${IDENTITY_NAME} --query id -otsv)"

# 3. Deploy AzureIdentity 
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

# 4. (Optional) Match pods in the namespace 
https://azure.github.io/aad-pod-identity/docs/configure/match_pods_in_namespace/

# 5. Deploy AzureIdentityBinding 
cat <<EOF | kubectl apply -f -
apiVersion: "aadpodidentity.k8s.io/v1"
kind: AzureIdentityBinding
metadata:
  name: ${IDENTITY_NAME}-binding
spec:
  azureIdentity: ${IDENTITY_NAME}
  selector: ${IDENTITY_NAME}
EOF

# 6. Deployment and Validation 
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

# 7. Clean up
