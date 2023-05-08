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
## https://learn.microsoft.com/en-us/dotnet/architecture/grpc-for-wcf-developers/docker
## https://learn.microsoft.com/en-us/aspnet/core/tutorials/grpc/grpc-start?view=aspnetcore-7.0&tabs=visual-studio-code
## https://github.com/dotnet-architecture/grpc-for-wcf-developers/tree/main/KubernetesSample
## https://learn.microsoft.com/en-us/dotnet/architecture/grpc-for-wcf-developers/docker
## https://learn.microsoft.com/en-us/dotnet/core/tools/sdk-errors/netsdk1064
## https://learn.microsoft.com/en-us/dotnet/core/tools/dotnet-sln
## https://learn.microsoft.com/en-us/aspnet/core/tutorials/grpc/grpc-start?view=aspnetcore-7.0&tabs=visual-studio-code
## https://stackoverflow.com/questions/61167032/error-netsdk1064-package-dnsclient-1-2-0-was-not-found
## https://github.com/dotnet/dotnet-docker/blob/main/samples/dotnetapp/.dockerignore
## https://github.com/caddyserver/caddy/issues/3236
## https://kubernetes.io/docs/concepts/containers/images/

## 1. Create ACR
export rgName=eastasiaResourceGroup
export locationRegion=eastasia
az group create --name $rgName --location $locationRegion

export myACR=myacr0508
az acr create --resource-group $RG --name $myACR --sku Basic

az acr login --name $myACR

## 2. Build a gRPC service of ASP.NET Core by Dockerfile and push to ACR

git clone https://github.com/neolin-ms/asp-net-grpc-greeter.git

cd asp-net-grpc-greeter
docker build -t greeter:1.0.0 -f ./Greeter/Dockerfile .
docker images
docker tag greeter:1.0.0 $myACR.azurecr.io/greeter:1.0.0
docker push $myACR.azurecr.io/greeter:1.0.0

## 2.1 Option - Create a new greeter by Vistual Stdio Core
## mkdir asp-net-grpc-greeter && cd "$_"  
## dotnet new grpc -o Greeter
## code -r Greeter
## 2.2 Option - Open the intergrated terminal of Visual Studio Code
##  dotnet run
## 2.3 Option - Open a borwase and vavifates to http://localhost:port, such as http://localhost:7042
## 2.5 Option - Create a new solution file of Vistual Stdio Core
## dotnet new sln -n Greeter
## 2.5 Option - Copy the Dockerfile 
## cp /Greeter
## curl https://raw.githubusercontent.com/neolin-ms/asp-net-grpc-greeter/main/Greeter/Dockerfile
## 2.6 Option - Build a container image of Greeter of gRPC
## docker build -t greeter:1.0.0 -f ./Greeter/Dockerfile .
## 2.7 Option - Push container image to ACR
## docker images
## docker tag greeter:1.0.0 $myACR.azurecr.io/greeter:1.0.0
## docker push $myACR.azurecr.io/greeter:1.0.0

az acr repository list --name $myACR --output table

## 3. Create an AKS cluster with ACR
export aksName=eastasiaAKSCluster
az aks create \
    --resource-group $RG \
    --name $aksName \
    --node-count 2 \
    --generate-ssh-keys \
    --attach-acr $myACR

az aks get-credentials --resource-group $rgName --name $aksName

kubectl get nodes

## 3. Create NGINX Ingress Controller on AKS cluster

export NAMESPACE=ingress-basic

helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

helm install ingress-nginx ingress-nginx/ingress-nginx \
  --create-namespace \
  --namespace $NAMESPACE \
  --set controller.service.annotations."service\.beta\.kubernetes\.io/azure-load-balancer-health-probe-request-path"=/healthz

kubectl get pods,svc,ingress -n ingress-basic

## 4. Create a gRPC service by Ingress Controller

### Step 4.1 Create a TLS certificate
cd /asp-net-grpc-greeter/KuberneterSample
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -out aks-grpc-tls.crt \
    -keyout aks-grpc-tls.key \
    -subj "/CN=demo.azure.com/O=aks-grpc-tls" \
    -addext "subjectAltName = DNS:demo.azure.com"

### Step 4.2 Creae pod and service for gRPC service

cd /asp-net-grpc-greeter/KubenetersExample
kubectl apply -f namespace.yml
kubectl get ns

vi greeter-pod-service.yml
kubectl apply -f greeter-pod-service.yml

kubectl get pods,svc -n greeter

### Step 4.3 Create a scret on kubernetes for TLS certificate
kubectl create secret tls aks-grpc-tls \
    --namespace greeter \
    --key aks-grpc-tls.key \
    --cert aks-grpc-tls.crt

### Step 4.4 Deploy a ingress for gRPC service of greeter
kubectl apply -f greeter-ingress.yml -n greeter

### Step 4.5 Check the pod, svc, ingress
kubectl get pods,svc,ingress -n greeter
kubectl describe ingress greeter-ingress -n greeter

## 5. Test the connection
cd /asp-net-grpc-greeter/Greeter/Protos
scp greet.proto azureuser@<PUBLIC_IP>:~/.
cd /asp-net-grpc-greeter/KuberneterSample
scp aks-grpc-tls.crt azureuser@<PUBLIC_IP>:/tmp/.
ssh azureuser@<PUBLIC_IP>
sudo cp /tmp/aks-grpc-tls.crt /usr/local/share/ca-certificates/.
sudo update-ca-certificates

apt-get update -y
apt-get install dnsutils -y
apt-get install curl -y
apt-get install netcat -y
apt install vim -y

sudo /etc/hosts
<PUBLIC_IP> demo.azure.com

curl -sSL "https://github.com/fullstorydev/grpcurl/releases/download/v1.8.7/grpcurl_1.8.7_linux_x86_64.tar.gz" | sudo tar -xz -C /usr/local/bin
grpcurl -h

grpcurl -proto "greet.proto" demo.azure.com:443 describe
grpcurl -d '{"name": "World"}' -proto "greet.proto" demo.azure.com:443 greet.Greeter/SayHello
