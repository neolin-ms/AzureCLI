
# Prerequisites
docker run -it sturrent/aks-cm-l200lab:latest

aks-cm-l200lab -h

# lab1
aks-cm-l200lab -g aks-cm-lab1-rg -n aks-lab1 -l 1

##You have to deploy an AKS cluster with the following setup:
##1. Cluster name = aks-lab1
##2. Resource group name = aks-cm-lab1-rg
##3. Number of nodes = 1
##4. Node OS disk size = 70
##5. VM type = AvailabilitySet
##6. Max Pods = 100
##7. CNI = kubenet
##8. Load balancer sku = basic
##9. Cluster has to reach succeeded state

time {
aksName=aks-lab1   
rgName=aks-cm-lab1-rg
loName=eastus2

az group create --name $rgName -l $loName -o table

az aks create \
  --resource-group $rgName \
  --name $aksName \
  --node-count 1 \
  --node-osdisk-size 70 \
  --vm-set-type AvailabilitySet \
  --max-pods 100 \
  --network-plugin kubenet \
  --load-balancer-sku basic \
  --generate-ssh-keys
}

aks-cm-l200lab -g aks-cm-lab1-rg -n aks-lab1 -l 1 -v

# lab2
# https://supportability.visualstudio.com/AzureContainers/_wiki/wikis/Containers%20Wiki/325135/Hands-on-labs-Node-Autoscaler

aks-cm-l200lab -g aks-cm-lab1-rg -n aks-lab1 -l 2

az aks get-credentials --resource-group aks-cm-lab1-rg --name aks-lab1

##union ControlPlaneEvents, ControlPlaneEventsNonShoebox 
##| where PreciseTimeStamp >= datetime(2022-05-10 14:00) and PreciseTimeStamp <= datetime(2022-05-11 16:00) 
##| where namespace == "627bd2c9f9938c0001d6bc09"
##| where category contains "cluster-autoscaler" 
##| project PreciseTimeStamp, category, log=tostring(parse_json(properties).log)

##"PreciseTimeStamp": 2022-05-11T15:18:21Z,
##"category": cluster-autoscaler,
##"log":     "message": "Subnet aks-subnet-autoscalelab with address prefix 10.0.0.0/25 does not have enough capacity for 124 IP addresses."

az aks update -g aks-cm-lab1-rg -n aks-lab1 --disable-cluster-autoscaler

az vmss delete -g MC_aks-cm-lab1-rg_aks-lab1_eastus2 -n aks-nodepool1-13773316-vmss

az network vnet subnet update -g aks-cm-lab1-rg -n aks-subnet-autoscalelab --vnet-name aks-vnet-autoscalelab --address-prefixes 10.0.0.0/24

#1.22.6

az aks get-upgrades --resource-group aks-cm-lab1-rg --name aks-lab1 --output table

az aks upgrade -g aks-cm-lab1-rg -n aks-lab1 -k 1.23.3

az aks update -g aks-cm-lab1-rg -n aks-lab1 --enable-cluster-autoscaler --min-count 1 --max-count 7 --cluster-autoscaler-profile scan-interval=30s

kubectl get pods | egrep 'STATUS|Pending'

aks-cm-l200lab -g aks-cm-lab1-rg -n aks-lab1 -l 2 -v

# lab3
#/subscriptions/60796668-979e-4d0a-b3cd-74f9e7dba880/resourcegroups/aks-cm-lab3-rg/providers/Microsoft.ContainerService/managedClusters/aks-lab3

aks-cm-l200lab -g aks-cm-lab3-rg -n aks-lab3 -l 3

az aks get-credentials --resource-group aks-cm-lab3-rg --name aks-lab3

az aks upgrade \
    --resource-group aks-cm-lab3-rg \
    --name aks-lab3 \
    --kubernetes-version 1.23.3
	
aks-cm-l200lab -g aks-cm-lab3-rg -n aks-lab3 -l 3 -v

# lab4

aks-cm-l200lab -g aks-cm-lab4-rg -n aks-lab4 -l 4

az aks get-credentials --resource-group aks-cm-lab4-rg --name aks-lab4

kubectl describe pod slow-start-c47b6769f-nf4tf

##  Warning  Unhealthy  63s (x9 over 2m43s)  kubelet            Liveness probe failed: cat: can't open '/tmp/healthy': No such file or directory
##  Normal   Killing    63s (x3 over 2m33s)  kubelet            Container slow-start failed liveness probe, will be restarted

kubectl edit deploy slow-start

##spec:
##  containers:
##  - args:
##    - /bin/sh
##    - -c
##    - touch /tmp/healthy
##	image: sturrent/slow-start:latest
##      imagePullPolicy: Always
##      livenessProbe:
##        exec:
##          command:
##          - cat
##          - /tmp/healthy
##        failureThreshold: 3
##        initialDelaySeconds: 120
##        periodSeconds: 5
##        successThreshold: 1
##        timeoutSeconds: 1

aks-cm-l200lab -g aks-cm-lab4-rg -n aks-lab4 -l 4 -v  
