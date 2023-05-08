#!/bin/bash

## References
## Tutorial: Deploy and use Azure Container Registry
## https://learn.microsoft.com/en-us/azure/aks/tutorial-kubernetes-prepare-acr?tabs=azure-cli
## Tutorial: Deploy an Azure Kubernetes Service (AKS) cluster
## https://learn.microsoft.com/en-us/azure/aks/tutorial-kubernetes-deploy-cluster?tabs=azure-cli
## Create an ingress controller in Azure Kubernetes Service (AKS)
## https://learn.microsoft.com/en-us/azure/aks/ingress-basic?tabs=azure-cli
## kubernetes/ingress-nsing - gRPC
## https://kubernetes.github.io/ingress-nginx/examples/grpc/
## Tutorial: Create a gRPC client and server in ASP.NET Core
## https://learn.microsoft.com/en-us/aspnet/core/tutorials/grpc/grpc-start?view=aspnetcore-7.0&tabs=visual-studio-code
## Create TLS certificate
## https://github.com/MicrosoftDocs/azure-docs.zh-tw/blob/master/articles/aks/ingress-own-tls.md
## Can't connect to pods and service in same cluster
## https://learn.microsoft.com/en-us/troubleshoot/azure/azure-kubernetes/troubleshoot-connection-pods-services-same-cluster
## Test the connection
## https://github.com/fullstorydev/grpcurl
## How to install the grpcurl binary on Linux?
## https://github.com/fullstorydev/grpcurl/issues/154

## 1. Create ACR
az group create --name eastusResourceGroup --location eastus

az acr create --resource-group eastusResourceGroup --name myacr0503 --sku Basic

az acr login --name myacr0503

## 2. Build a gRPC service of ASP.NET Core by Dockerfile and push to ACR

mkdir asp-net-grpc-greeter && cd "$_"  

dotnet new grpc -o GrpcGreeter
code -r GrpcGreeter

## Open the intergrated terminal of Virsual Studio Code
dotnet run

## Open a borwase and vavifates to http://localhost:port, such as http://localhost:7042

curl https://raw.githubusercontent.com/neolin-ms/asp-net-grpc-greeter/main/Greeter/Dockerfile

docker build -t greeter:1.0.0 -f ./Greeter/Dockerfile .
docker images
docker tag greeter:1.0.0 myacr0503.azurecr.io/greeter:1.0.0
docker push myacr0503.azurecr.io/greeter:1.0.0

az acr repository list --name myacr0503 --output table

## 3. Create an AKS cluster with ACR
az aks create \
    --resource-group eastusResourceGroup \
    --name eastusAKSCluster \
    --node-count 2 \
    --generate-ssh-keys \
    --attach-acr myacr0503

az aks get-credentials --resource-group eastusResourceGroup --name eastusAKSCluster

## 3. Create NGINX Ingress Controller on AKS cluster

NAMESPACE=ingress-basic

helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

helm install ingress-nginx ingress-nginx/ingress-nginx \
  --create-namespace \
  --namespace $NAMESPACE \
  --set controller.service.annotations."service\.beta\.kubernetes\.io/azure-load-balancer-health-probe-request-path"=/healthz

kubectl get pods,svc,ingress -n ingress-basic

## 4. Create a gRPC service by Ingress Controller

### Step 4.1 Create a TLS certificate
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -out aks-grpc-tls.crt \
    -keyout aks-grpc-tls.key \
    -subj "/CN=demo.azure.com/O=aks-grpc-tls" \
    -addext "subjectAltName = DNS:demo.azure.com"

### Step 4.2 Create a scret on kubernetes for TLS certificate
kubectl create secret tls aks-grpc-tls \
    --namespace ingress-basic \
    --key aks-grpc-tls.key \
    --cert aks-grpc-tls.crt

### Step 4.3 Creae pod and service for gRPC service
kubectl apply -f https://raw.githubusercontent.com/neolin-ms/asp-net-grpc-greeter/main/KubernetesSample/namespace.yml
kubectl get ns

kubectl apply -f https://raw.githubusercontent.com/neolin-ms/asp-net-grpc-greeter/main/KubernetesSample/greeter-pod-service.yml

kubectl apply -f https://raw.githubusercontent.com/neolin-ms/asp-net-grpc-greeter/main/KubernetesSample/greeter-ingress.yml -n greeter

### Step 4.4 Check the pod, svc, ingress
kubectl get pods,svc,ingress -n greeter
kubectl describe ingress greeter-ingress -n greeter

## Step 4.5 Check the pod/service/ingress of gRPC service
kubectl get pod,svc,ingress -n ingress-basic

## 5. Test the connection
kubectl run -it aks-ssh --namespace ingress-basic --image=debian:stable
apt-get update -y
apt-get install dnsutils -y
apt-get install curl -y
apt-get install netcat -y
apt install vim -y

kubectl cp aks-grpc-tls.crt aks-ssh:/tmp/

scp aks-grpc-tls.crt azureuser@<PUBLIC_IP>:/tmp/.
cp aks-grpc-tls.crt /usr/local/share/ca-certificates/.
sudo update-ca-certificates

cd /asp-net-grpc-greeter/Greeter/Protos
scp greet.proto azureuser@<PUBLIC_IP>:~/.

sudo /etc/hosts
<PUBLIC_IP> demo.azure.com

curl -sSL "https://github.com/fullstorydev/grpcurl/releases/download/v1.8.7/grpcurl_1.8.7_linux_x86_64.tar.gz" | sudo tar -xz -C /usr/local/bin
grpcurl -h

grpcurl -proto "greet.proto" demo.azure.com:443 describe
grpcurl -d '{"name": "World"}' -proto "greet.proto" demo.azure.com:443 greet.Greeter/SayHello
