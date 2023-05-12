#!/bin/sh

## Install an Application Gateway Ingress Controller (AGIC) using an existing Application Gateway
## https://learn.microsoft.com/en-us/azure/application-gateway/ingress-controller-install-existing

## == AKS with Azure Container Networking Interface (CNI) ==

export rgName=eastasiaResourceGroup
export locationRegion=eastasia

az group create -n $rgName -l $locationRegion

export clusterName=eastasiaAKSCluster

az aks create \
    --resource-group $rgName \
    --name $clusterName \
    --network-plugin azure \
    --node-count 2 \
    --generate-ssh-keys
	
## == Application Gateway v2 in the same virtual network as AKS ==
## https://learn.microsoft.com/en-us/azure/application-gateway/tutorial-ingress-controller-add-on-existing?toc=https%3A%2F%2Flearn.microsoft.com%2Fen-us%2Fazure%2Faks%2Ftoc.json&bc=https%3A%2F%2Flearn.microsoft.com%2Fen-us%2Fazure%2Fbread%2Ftoc.json#deploy-a-new-application-gateway

export NODES_RESOURCE_GROUP=$(az aks show -n $clusterName -g $rgName --query nodeResourceGroup -o tsv)
export pipName=myPublicIp0510
az network public-ip create -n $pipName -g $NODES_RESOURCE_GROUP --allocation-method Static --sku Standard

export vnetName=$(az resource list -g $NODES_RESOURCE_GROUP -o json --query [].id -o tsv | grep -i virtualNetworks)
export subnetName=mySubnet0510
az network vnet subnet create --name $subnetName --vnet-name $vnetName --resource-group $NODES_RESOURCE_GROUP --address-prefixes "10.225.0.0/24"

export appgwName=appgw0510
az network application-gateway create -n $appgwName -l $locationRegion -g $NODES_RESOURCE_GROUP --sku Standard_v2 --public-ip-address $pipName --vnet-name $vnetName --subnet $subnetName --priority 100

## == AAD Pod Identity installed on your AKS cluster ==
## https://learn.microsoft.com/en-us/azure/aks/use-azure-ad-pod-identity
## https://azure.github.io/aad-pod-identity/docs/demo/standard_walkthrough/
## https://azure.github.io/aad-pod-identity/docs/getting-started/role-assignment/

export SUBSCRIPTION_ID="60796668-979e-4d0a-b3cd-74f9e7dba880"
export RESOURCE_GROUP="eastasiaResourceGroup"
export CLUSTER_NAME="eastasiaAKSCluster"

curl -s https://raw.githubusercontent.com/Azure/aad-pod-identity/master/hack/role-assignment.sh | bash

export IDENTITY_RESOURCE_GROUP="$(az aks show -g ${RESOURCE_GROUP} -n ${CLUSTER_NAME} --query nodeResourceGroup -otsv)"
export IDENTITY_NAME="demo"

kubectl apply -f https://raw.githubusercontent.com/Azure/aad-pod-identity/master/deploy/infra/deployment-rbac.yaml

kubectl get pods -A

az identity create -g ${IDENTITY_RESOURCE_GROUP} -n ${IDENTITY_NAME}

{
  "clientId": "32f9d0bc-5e27-4bf0-9544-ddb6f9722094",
  "id": "/subscriptions/60796668-979e-4d0a-b3cd-74f9e7dba880/resourcegroups/MC_eastasiaResourceGroup_eastasiaAKSCluster_eastasia/providers/Microsoft.ManagedIdentity/userAssignedIdentities/demo",
  "location": "eastasia",
  "name": "demo",
  "principalId": "02c231c1-2b11-44db-a5d3-98cd23295216",
  "resourceGroup": "MC_eastasiaResourceGroup_eastasiaAKSCluster_eastasia",
  "systemData": null,
  "tags": {},
  "tenantId": "72f988bf-86f1-41af-91ab-2d7cd011db47",
  "type": "Microsoft.ManagedIdentity/userAssignedIdentities"
}

export IDENTITY_CLIENT_ID="$(az identity show -g ${IDENTITY_RESOURCE_GROUP} -n ${IDENTITY_NAME} --query clientId -otsv)"
export IDENTITY_RESOURCE_ID="$(az identity show -g ${IDENTITY_RESOURCE_GROUP} -n ${IDENTITY_NAME} --query id -otsv)"

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

cat <<EOF | kubectl apply -f -
apiVersion: "aadpodidentity.k8s.io/v1"
kind: AzureIdentityBinding
metadata:
  name: ${IDENTITY_NAME}-binding
spec:
  azureIdentity: ${IDENTITY_NAME}
  selector: ${IDENTITY_NAME}
EOF

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
    image: mcr.microsoft.com/oss/azure/aad-pod-identity/demo:v1.8.15
    args:
      - --subscription-id=${SUBSCRIPTION_ID}
      - --resource-group=${IDENTITY_RESOURCE_GROUP}
      - --identity-client-id=${IDENTITY_CLIENT_ID}
  nodeSelector:
    kubernetes.io/os: linux
EOF

kubectl logs demo --follow

## == Azure resource Manager Authentication ==

export principalId=$(az identity show -g $NODES_RESOURCE_GROUP -n $IDENTITY_NAME --query "principalId" -o tsv)
export appgwResourceId=$(az network application-gateway show -g $NODES_RESOURCE_GROUP -n $appgwName --query id -o tsv)

/subscriptions/60796668-979e-4d0a-b3cd-74f9e7dba880/resourceGroups/MC_eastasiaResourceGroup_eastasiaAKSCluster_eastasia/providers/Microsoft.Network/applicationGateways/appgw0510

az role assignment create \
    --role Contributor \
    --assignee $principalId \
    --scope $appgwResourceId
	
az role assignment create \
    --role Reader \
    --assignee $principalId \
    --scope /subscriptions/60796668-979e-4d0a-b3cd-74f9e7dba880/resourceGroups/MC_eastasiaResourceGroup_eastasiaAKSCluster_eastasia
	
## == Install Ingress Controller as a Helm Chart ==

helm repo add application-gateway-kubernetes-ingress https://appgwingress.blob.core.windows.net/ingress-azure-helm-package/
helm repo update

wget https://raw.githubusercontent.com/Azure/application-gateway-kubernetes-ingress/master/docs/examples/sample-helm-config.yaml -O helm-config.yaml

vi helm-config.yaml

helm install ingress-azure -f helm-config.yaml application-gateway-kubernetes-ingress/ingress-azure --version 1.6.0
helm list

kubectl logs pod/ingress-azure-cc977cc76-m98cd

## == Expose an AKS service over HTTP or HTTPS using Application Gateway ==
## https://learn.microsoft.com/en-us/azure/application-gateway/ingress-controller-expose-service-over-http-http
## https://learn.microsoft.com/en-us/azure/application-gateway/ingress-controller-install-new#install-a-sample-app

kubectl apply -f https://raw.githubusercontent.com/kubernetes/examples/master/guestbook/all-in-one/guestbook-all-in-one.yaml

cat << EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: guestbook
  annotations:
    kubernetes.io/ingress.class: azure/application-gateway
spec:
  rules:
  - http:
      paths:
        - path: /
          backend:
            service:
              name: frontend
              port:
                number: 80
          pathType: Exact
EOF		  

kubectl get pod,svc,ingress
