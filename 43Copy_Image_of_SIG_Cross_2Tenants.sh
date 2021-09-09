#!/bin

## Reference
Share gallery VM images across Azure tenants using the Azure CLI<br>
https://docs.microsoft.com/en-us/azure/virtual-machines/linux/share-images-across-tenants<br>

#Tenant 1, Subscription 1, Source SIG
App registrations: myGalleryApp0804neolin<br>
Application (client) ID: 18a04353-7080-4df1-aa44-xxxxxxxxxxxx<br>
Serets: l2xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
Tenant 1: 56d6941c-896b-4583-9a66-xxxxxxxxxxxx
Subscription 1: a76944aa-b763-4bb1-85eb-xxxxxxxxxxxx
Source SIG Image Version: /subscriptions/a76944aa-b763-4bb1-xxxxxxxxxxxx/resourceGroups/myGalleryRG/providers/Mic rosoft.Compute/galleries/myGalleryWindows0805/images/mydefinitionwindows0805/versions/1.0.0
Source SIG name: myGalleryWindows0805 (RBAC role: Reader)

#Tenant 2, Subscription 2, Destination SIG
Tenant 2: 72f988bf-86f1-41af-91ab-xxxxxxxxxxxx
Subscription 2: 60796668-979e-4d0a-b3cd-xxxxxxxxxxxx
Destination SIG Definition: /subscriptions/60796668-979e-4d0a-b3cd-xxxxxxxxxxxx/resourceGroups/testubunturg/providers/Microsoft .Compute/galleries/myDestinationGallery0805/images/myDestinationImgDef0805
Destination SIG name: myDestinationGallery0805
Destination resource: testubunturg (RBAC role: Contributor)

#Sign in the service principal for tenant 1 using the appID, the app key, and the ID of tenant 1
az account clear
az login --service-principal -u '18a04353-7080-4df1-aa44-xxxxxxxxxxxx' -p 'l2xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx' --tenant '56d6941c-896b-4583-9a66-xxxxxxxxxxxx'
az account get-access-token

#Sign in the service principal for tenant 2 using the appID, the app key, and the ID of tenant 2
az login --service-principal -u '18a04353-7080-4df1-aa44-76b69dcb9b7a' -p ' l2xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx' --tenant '72f988bf-86f1-41af-91ab-xxxxxxxxxxxx'
az account get-access-token

# Copy an image from gallery of tenant1 to gallery of tenant2 
az sig image-version create \
   --resource-group testubunturg \
   --gallery-name myDestinationGallery0805 \
   --gallery-image-definition myDestinationImgDef0805 \
   --gallery-image-version 1.0.0 \
   --target-regions "eastasia=1" \
   --replica-count 1 \
   --managed-image "/subscriptions/a76944aa-b763-4bb1-85eb-xxxxxxxxxxxx/resourceGroups/myGalleryRG/providers/Microsoft.Compute/galleries/myGalleryWindows0805/images/mydefinitionwindows0805/versions/1.0.0"

