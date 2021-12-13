#!/bin/bash

rgName=testCentOSRg
nsgName=myCentOS79vm1208NSG

#valueIPs=`cat /home/neolin/testIPs.txt`
valueIPs=$(</home/neolin/testIPs.txt)

echo $valueIPs

az network nsg rule create -g $rgName --name 'Allow Remote' --nsg-name $nsgName --priority 1001 --source-address-prefixes $valueIPs --destination-port-ranges 22 --access Allow
