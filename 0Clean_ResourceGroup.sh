# History
# 2015/07/17    VBird   first release
#PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
#export PATH

getRsg=$(az group list --out tsv --query \'\[].[name]\'\)

for rsg in ${getRsg}       
do
        echo ${rsg}
done
