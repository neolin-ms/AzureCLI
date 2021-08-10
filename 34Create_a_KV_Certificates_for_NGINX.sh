me=testmyKv20210702
rg_name=testKvRg

az keyvault certificate create \
    --vault-name ${keyvault_name} \
    --name mycert \
    --policy "$(az keyvault certificate get-default-policy)"
	
secret=$(az keyvault secret list-versions \
          --vault-name ${keyvault_name} \
          --name mycert \
          --query "[?attributes.enabled].id" --output tsv)
		  
vm_secret=$(az vm secret format --secrets ${secret} -g ${rg_name} --keyvault ${keyvault_name})	

rgname=testubunturg

az vm create \
--resource-group ${rgname} \
--name myubuntu1804vm0726 \
--image Canonical:UbuntuServer:18_04-lts-gen2:18.04.202103250 \
--size Standard_D4s_v3 \
--admin-username azureuser \
--generate-ssh-keys \
--custom-data cloud-init-web-server.txt \
--secrets "$vm_secret"
