#!/bin/bash

# Install the AzureCLI on Linux - Install with one command (https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Login to Azure
az login --use-device-code

# Docker install on ubuntu (https://docs.docker.com/engine/install/ubuntu/)
sudo apt-get update

sudo apt-get install \
    ca-certificates \
    curl \
    gnupg \
    lsb-release
	
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg	

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  
sudo apt-get install docker-ce docker-ce-cli containerd.io  

sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io

sudo docker run hello-world

# Install Docker Compose on Linux systems (https://docs.docker.com/compose/install/)
sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

sudo chmod +x /usr/local/bin/docker-compose

sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose

docker-compose --version

# Installing Helm (https://helm.sh/docs/intro/install/)
## From Apt (Debian/Ubuntu)
curl https://baltocdn.com/helm/signing.asc | sudo apt-key add -
sudo apt-get install apt-transport-https --yes
echo "deb https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update
sudo apt-get install helm

# Connect to the cluster (https://docs.microsoft.com/en-us/azure/aks/kubernetes-walkthrough#connect-to-the-cluster)
az aks install-cli
az aks get-credentials --resource-group myResourceGroup --name myAKSCluster
kubectl get nodes

# Confirm AKS cluster is using managed identity (https://docs.microsoft.com/en-us/azure/aks/use-managed-identity)
az aks show -g myResourceGroup -n myCluster --query "servicePrincipalProfile"

az aks show -g StagingGroup -n planStagingCluster --query "servicePrincipalProfile"

# Find the control plane system-assigned identity's object ID
az aks show -g StagingGroup -n planStagingCluster --query "identity"
