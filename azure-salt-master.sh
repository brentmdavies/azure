#Initial Azure Salt Master Build
sudo apt install python-pip
pip install azure

curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

az login

az group create --name saltGroup --location westus2

az network vnet create \
    --resource-group saltGroup \
    --name saltVnet \
    --address-prefix 10.0.0.0/16 \
    --subnet-name masterSubnet \
    --subnet-prefix 10.0.1.0/24

az network public-ip create \
    --resource-group saltGroup \
    --name masterPublicIP \
    --dns-name mysaltmaster

az network nsg create \
    --resource-group saltGroup \
    --name masterSecurityGroup        

az network nsg rule create \
    --resource-group saltGroup \
    --nsg-name masterSecurityGroup \
    --name masterSecurityGroupRuleSSH \
    --protocol tcp \
    --priority 1000 \
    --destination-port-range 22 \
    --access allow    

az network nsg rule create \
    --resource-group saltGroup \
    --nsg-name masterSecurityGroup \
    --name masterSecurityGroupRule4505 \
    --protocol tcp \
    --priority 1001 \
    --destination-port-range 4505 \
    --access allow     

az network nsg rule create \
    --resource-group saltGroup \
    --nsg-name masterSecurityGroup \
    --name masterSecurityGroupRule4506 \
    --protocol tcp \
    --priority 1002 \
    --destination-port-range 4506 \
    --access allow   

az network nic create \
    --resource-group saltGroup \
    --name masterNic \
    --vnet-name saltVnet \
    --subnet masterSubnet \
    --public-ip-address masterPublicIP \
    --network-security-group masterSecurityGroup

az vm create \
    --resource-group saltGroup \
    --name masterVM \
    --location westus2 \
    --nics masterNic \
    --image UbuntuLTS \
    --admin-username azureuser \
    --generate-ssh-keys

