#/!bin/bash

az vmss run-command invoke -g az-entaks-nonprod-01-esco-dev-eastus-rg-02 -n aks-escoba1np02-20500933-vmss --command-id RunShellScript --instance-id 22 --scripts "curl -vvv mcr.microsoft.com"
 
az vmss run-command invoke -g az-entaks-nonprod-01-esco-dev-eastus-rg-02 -n aks-escoba1np02-20500933-vmss --command-id RunShellScript --instance-id 22 --scripts "dig mcr.microsoft.com 443"
 
az vmss run-command invoke -g az-entaks-nonprod-01-esco-dev-eastus-rg-02 -n aks-escoba1np02-20500933-vmss --command-id RunShellScript --instance-id 22 --scripts "nc -vz mcr.microsoft.com 443"

az vmss run-command invoke -g az-entaks-nonprod-01-esco-dev-eastus-rg-02 -n aks-escoba1np02-20500933-vmss --command-id RunShellScript --instance-id 22 --scripts "cat /etc/resolv.conf"

az vmss run-command invoke -g MC_neoResourceGroup_neoAKSCluster_eastus -n aks-nodepool1-61412696-vmss --command-id RunShellScript --instance-id 6 --scripts "dig mcr.microsoft.com 443"

az vmss run-command invoke -g MC_neoResourceGroup_neoAKSCluster_eastus -n aks-nodepool1-61412696-vmss --command-id RunShellScript --instance-id 6 --scripts "cat /etc/resolv.conf"

az vmss list-instances --name <vmss-name> -g <node-rg> --query "[].id" --output tsv

az vmss list-instances -g MC_neoResourceGroup_neoAKSCluster_eastus --name aks-nodepool1-61412696-vmss --query "[].id" --output tsv

az vmss run-command invoke -g MC_neoResourceGroup_neoAKSCluster_eastus -n aks-nodepool1-61412696-vmss --command-id RunShellScript --instance-id 6 --scripts 'grep nameserver /etc/resolv.conf || { dhclient -x; dhclient -i eth0; sleep 10; pkill dhclient; grep nameserver /etc/resolv.conf; }'

az vmss list-instances --name <vmss-name> -g <node-rg> \
 --query "[].id" --output tsv | \
 az vmss run-command invoke --ids @- \
 --command-id RunShellScript \
 --scripts 'grep nameserver /etc/resolv.conf || { dhclient -x; dhclient -i eth0; sleep 10; pkill dhclient; grep nameserver /etc/resolv.conf; }'


az vmss list-instances --name aks-nodepool1-61412696-vmss -g MC_neoResourceGroup_neoAKSCluster_eastus \
 --query "[].id" --output tsv | \
 az vmss run-command invoke --ids @- \
 --command-id RunShellScript \
 --scripts 'echo ok'
