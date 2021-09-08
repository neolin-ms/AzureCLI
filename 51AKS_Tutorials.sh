#!/bin/bash

## References

1 - Prepare application for AKS, https://docs.microsoft.com/en-us/azure/aks/tutorial-kubernetes-prepare-app<br>
2 - Create container registry, https://docs.microsoft.com/en-us/azure/aks/tutorial-kubernetes-prepare-acr?tabs=azure-cli<br>  
3 - Create Kubernetes cluster, https://docs.microsoft.com/en-us/azure/aks/tutorial-kubernetes-deploy-cluster?tabs=azure-cli<br>
4 - Run application, https://docs.microsoft.com/en-us/azure/aks/tutorial-kubernetes-deploy-application?tabs=azure-cli<br>

## Tutotials

1 - Prepare application for AKS, Tutorial: Prepare an application for Azure Kubernetes Service (AKS)

Step 1. Get application code
Use git to clone the sample application to your development environment:

```bash
git clone https://github.com/Azure-Samples/azure-voting-app-redis.git
```
Change into the cloned directory.
```bash
cd azure-voting-app-redis
```

Step 2. Create container images

Use the sample docker-compose.yaml file to create the container image, download the Redis image, and start the application:
```bash
docker-compose up -d
```
When completed, use the docker images command to see the created images
```bash
$ docker images
```
Run the docker ps command to see the running containers:
```bash
$ docker ps
```

Step 3. Test application locally

To see the running application, enter http://localhost:8080 in a local web browser.

Step 4. Clean up resources

Stop and remove the container instances.
```bash
$ docker-compose down
```

2 - Create container registry - Tutorial: Deploy and use Azure Container Registry
 
Step 1. Create an Azure Container Registry

Create a resource group with the az group create command. 
```bash
az group create --name myResourceGroup --location eastus
```
Create an Azure Container Registry instance
```bash
az acr create --resource-group myResourceGroup --name <acrName> --sku Basic
```

Step 2. Log in to the container registry

To use the ACR instance, you must first log in.
```bash
az acr login --name <acrName>
```
The command returns a Login Succeeded message once completed.

Step 3. Tag a container image

To see a list of your current local images
```bash
docker images
```
To get the login server addres
```bash
az acr list --resource-group myResourceGroup --query "[].{acrLoginServer:loginServer}" --output table
```
Tag your local azure-vote-front image with the acrLoginServer address of the container registry
```bash
docker tag mcr.microsoft.com/azuredocs/azure-vote-front:v1 <acrLoginServer>/azure-vote-front:v1
```
To verify the tags are applied
```bash
$ docker images
```

Step 4. Push images to registry

With your image built and tagged, push the azure-vote-front image to your ACR instance.
```bash
docker push <acrLoginServer>/azure-vote-front:v1
```

Step 5. List images in registry

To return a list of images that have been pushed to your ACR instance
```bash
az acr repository list --name <acrName> --output table
```
To see the tags for a specific image
```bash
az acr repository show-tags --name <acrName> --repository azure-vote-front --output table
```

3 - Create Kubernets cluster

Step 1. Create a Kubernetes cluster

Create an AKS cluster using az aks create.
```bash
az aks create \
    --resource-group myResourceGroup \
    --name myAKSCluster \
    --node-count 2 \
    --generate-ssh-keys \
    --attach-acr <acrName>
```

Step 2. Install the Kubernets CLI

```bash
az aks install-cli
```

Step 3. Connect to cluster using kubectl

To configure kubectl to connect to your Kubernetes cluster
```bash
az aks get-credentials --resource-group myResourceGroup --name myAKSCluster
```
To verify the connection to your cluster
```bash
kubectl get nodes
```

4 - Run application, Tutorial: Run applications in Azure Kubernetes Service (AKS)
 
Step 1. Update the manifest file
Get the ACR login server name
```bash
az acr list --resource-group myResourceGroup --query "[].{acrLoginServer:loginServer}" --output table
```
Make sure that you're in the cloned azure-voting-app-redis directory, then open the manifest file with a text editor
```bash
vi azure-vote-all-in-one-redis.yaml
```
Replace microsoft with your ACR login server name. The image name is found on line 60 of the manifest file.
```bash
```

Step 2. Deploy the application
deploy your application
```bash
kubectl apply -f azure-vote-all-in-one-redis.yaml
```

Step 3. Test the application
To monitor progress
```bash
kubectl get service azure-vote-front --watch
```
When the EXTERNAL-IP address changes from pending to an actual public IP address, use CTRL-C to stop the kubectl watch process.<br>

To see the application in action, open a web browser to the external IP address of your service.<br>

view the status of your containers<br>
```bash
kubectl get pods -o wide
```
