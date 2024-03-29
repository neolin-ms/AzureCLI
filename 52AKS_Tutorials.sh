#!/bin/bash

#References
## 1 - https://docs.microsoft.com/en-us/azure/aks/tutorial-kubernetes-prepare-app
## 2 - https://docs.microsoft.com/en-us/azure/aks/tutorial-kubernetes-prepare-acr?tabs=azure-cli
## 3 - https://docs.microsoft.com/en-us/azure/aks/tutorial-kubernetes-deploy-cluster?tabs=azure-cli
## 4 - https://docs.microsoft.com/en-us/azure/aks/tutorial-kubernetes-deploy-cluster?tabs=azure-cli
## 5 - https://docs.microsoft.com/en-us/azure/aks/tutorial-kubernetes-scale?tabs=azure-cli
## 6 - https://docs.microsoft.com/en-us/azure/aks/tutorial-kubernetes-app-update?tabs=azure-cli
## 7 - https://docs.microsoft.com/en-us/azure/aks/tutorial-kubernetes-upgrade-cluster?tabs=azure-cli
## 8 - https://learn.microsoft.com/en-us/troubleshoot/azure/azure-kubernetes/troubleshoot-connection-pods-services-same-cluster 

# 1.1 Get application code
git clone https://github.com/Azure-Samples/azure-voting-app-redis.git
cd azure-voting-app-redis
tree

# 1.2 Create container images
docker-compose up -d
docker images
docker ps
curl http://localhost:8080

# 1.3 Clean up resources
docker-compose down

# 2.1 Create an Azure Container Registry

rgName=myResourceGroup
regionName=eastus
az group create --name ${rgName} --location ${regionName}

acrName=neomyacrlab
az acr create --resource-group ${rgName} --name ${acrName} --sku Basic

# 2.2 Log in to the container registry

az acr login --name ${acrName}

##2.2.1 When login acr, and get the error messages below, please check the link. 
##https://stackoverflow.com/questions/51222996/docker-login-fails-on-a-server-with-no-x11-installed
##Error Messages:
##You may want to use 'az acr login -n neomyacrtest --expose-token' to get an access token, which does not require Docker to be installed.
##An error occurred: DOCKER_COMMAND_ERROR
##Got permission denied while trying to connect to the Docker daemon socket at unix:///var/run/docker.sock: Get http://%2Fvar%2Frun%2Fdocker.sock/v1.24/containers/json: dial unix /var/run/docker.sock: connect: permission denied 
##Example commandes: $ echo '<Access-Token>' | sudo docker login neomyacrtest.azurecr.io --username 00000000-0000-0000-0000-000000000000 --password-stdin 

# 2.3 Tag a container image

docker images

az acr list --resource-group ${rgName} --query "[].{acrLoginServer:loginServer}" --output table

neomyacrtest.azurecr.io

docker tag mcr.microsoft.com/azuredocs/azure-vote-front:v1 neomyacrtest.azurecr.io/azure-vote-front:v1

# 2.4 Push images to registry

docker push neomyacrtest.azurecr.io/azure-vote-front:v1

# 2.5 List images in registry

az acr repository list --name ${acrName} --output table

az acr repository show-tags --name ${acrName} --repository azure-vote-front --output table

# 3.1 Create a Kubernetes cluster
aksName=myAKSCluster
az aks create \
    --resource-group ${rgName} \
    --name ${aksName} \
    --node-count 2 \
    --generate-ssh-keys

az aks update -n ${aksName} -g ${rgName} --attach-acr ${acrName}

# 3.2 Install the Kubernetes CLI
az aks install-cli

# 3.3 Connect to cluster using kubectl
az aks get-credentials --resource-group ${rgName} --name ${aksName}

# 3.4 Verify the connection to your cluster
kubectl get nodes -o wide
kubectl get pods -n kube-system -o wide

# 4.1 Update the manifest file
az acr list --resource-group ${rgName} --query "[].{acrLoginServer:loginServer}" --output table

neomyacrlab.azurecr.io

vi azure-vote-all-in-one-redis.yaml
## containers:
## - name: azure-vote-front
  image: <acrName>.azurecr.io/azure-vote-front:v1

# 4.1 Deploy the application
kubectl apply -f azure-vote-all-in-one-redis.yaml

# 4.1 Test the application
kubectl get service azure-vote-front --watch 

# 5.1 Manually scale pods
kubectl get pods -n wide

kubectl scale --replicas=5 deployment/azure-vote-front

kubectl get pods -n wide

# 5.2 Autoscale pods
az aks show --resource-group ${rgName} --name ${aksName} --query kubernetesVersion --output table

kubectl autoscale deployment azure-vote-front --cpu-percent=50 --min=3 --max=10

## or you can create a manifest file to define the autoscaler behavior and resoure limits, e.g. azure-vote-hpa.yaml
## kubectl apply -f azure-vote-hpa.yaml

kubectl get hpa

# 5.3 Manually scale AKS nodes
az aks scale --resource-group ${rgName} --name ${aksName} --node-count 3

kubectl get nodes -o wide

# 6.1 Update an application
vi azure-vote/azure-vote/config_file.cfg

### UI Configurations
##TITLE = 'Azure Voting App'
##VOTE1VALUE = 'Blue'
##VOTE2VALUE = 'Purple'
##SHOWHOST = 'false'

# 6.2 Update the container image
docker-compose up --build -d

# 6.3 Test the application locally
curl http://localhost:8080

# 6.4 Tag and push the image
az acr list --resource-group ${rgName} --query "[].{acrLoginServer:loginServer}" --output table

neomyacrlab.azurecr.io

docker tag mcr.microsoft.com/azuredocs/azure-vote-front:v1 neomyacrlab.azurecr.io/azure-vote-front:v2

docker push neomyacrlab.azurecr.io/azure-vote-front:v2

az acr login -n neomyacrlab --expose-token

echo '<Access-Token>' | sudo docker login neomyacrlab.azurecr.io --username 00000000-0000-0000-0000-000000000000 --password-stdin

# 6.5 Deploy the updated application
kubectl set image deployment azure-vote-front azure-vote-front=neomyacrlab.azurecr.io/azure-vote-front:v2

# 6.6 Test the updated application
kubectl get service azure-vote-front

# 7.1 Get available cluster versions
az aks get-upgrades --resource-group ${rgName} --name ${aksName} -o table

# 7.2 Upgrade a cluster
k8sVersion=1.21.1
az aks upgrade \
    --resource-group ${rgName} \
    --name ${aksName} \
    --kubernetes-version ${k8sVersion}

# 7.3 Validate an upgrade
az aks show --resource-group ${rgName} --name ${aksName} --output table

# 7.4 Delete the cluster
az group delete --name ${rgName} --yes --no-wait

# 8.1 Set up the test pod and remote server port

kubectl run -it --rm aks-ssh --namespace <namespace> --image=debian:stable
kubectl run -it aks-ssh --namespace <namespace> --image=debian:stable
kubectl run -it aks-ssh --image=debian:stable  --overrides='{"spec": { "nodeSelector": {"kubernetes.io/hostname": "aks-nodepool1-291^C518-vmss000001"}}}'

apt-get update -y
apt-get install dnsutils -y
apt-get install curl -y
apt-get install netcat -y

curl -Iv http://<pod-ip-address>:<port>

nc -z -v <endpoint> <port>
