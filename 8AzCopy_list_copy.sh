
==Verify role assignments==
Storage Blob Data Contributor
Storage Blob Data Owner

==login==
.\azcopy login --tenant-id=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx

==list==
.\azcopy list https://neowinsql0629.blob.core.windows.net/bootdiagnostics-neowindow-a59b7386-xxxx-xxxx-xxxx-xxxxxxxxxxxx

.\azcopy list https://testcopy0722.blob.core.windows.net/testcontainer0722

==upload==
azcopy copy 'C:\myDirectory' 'https://mystorageaccount.blob.core.windows.net/mycontainer' --recursive

.\azcopy copy 'C:\Users\xxxx\Downloads\210716006000xxxx' 'https://neowinsql0629.blob.core.windows.net/bootdiagnostics-neowindow-a59b7386-xxxx-xxxx-xxxx-xxxxxxxxxxxx' --recursive

.\azcopy copy 'C:\Users\xxxx\Downloads\210716006000xxxx\test' 'https://testcopy0722.blob.core.windows.net/testcontainer0722' --recursive

==SAS==
<Get the SAS-Token from Azure Portal>

==copy blob==
.\azcopy copy 'https://neowinsql0629.blob.core.windows.net/bootdiagnostics-neowindow-a59b7386-xxxx-xxxx-xxxx-xxxxxxxxxxxx/neowindowssql0629.xxxxxxxxxx.serialconsole.log?<SAS-Token>' https://testcopy0722.blob.core.windows.net/testcontainer0722/neowindowssql0629.xxxxxxxxxxxx.serialconsole.log

==copy folder==
azcopy copy 'https://mysourceaccount.blob.core.windows.net/mycontainer/myBlobDirectory?<SAS-Token>' 'https://mydestinationaccount.blob.core.windows.net/mycontainer' --recursive

.\azcopy copy 'https://neowinsql0629.blob.core.windows.net/bootdiagnostics-neowindow-a59b7386-xxxx-xxxx-xxxxxxxxxxxx/210716006000xxxx?<SAS-Token>' 'https://testcopy0722.blob.core.windows.net/testcontainer0722/test' --recursive

.\azcopy copy 'https://neowinsql0629.blob.core.windows.net/bootdiagnostics-neowindow-a59b7386-xxxx-xxxx-xxxx-xxxxxxxxxxxx/210716006000xxxx/*?<SAS-Token>' 'https://testcopy0722.blob.core.windows.net/testcontainer0722/test' --recursive
