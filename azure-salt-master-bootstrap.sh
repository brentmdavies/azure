#!/bin/bash
#brentmdavies Custom Salt Master bootstrap and install

##Install Azure CLI for creating and administering Salt nodes

#Download and install the Microsoft signing key
curl -sL https://packages.microsoft.com/keys/microsoft.asc | \
    gpg --dearmor | \
     tee /etc/apt/trusted.gpg.d/microsoft.asc.gpg > /dev/null

#Add the Azure CLI software repository:
AZ_REPO=$(lsb_release -cs)
echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $AZ_REPO main" | \
     tee /etc/apt/sources.list.d/azure-cli.list

#Update repository information and install the azure-cli package:
 apt-get update
 apt-get install azure-cli

#Create and Configure Salt Master Azure VM
az login

az group create --name saltGroup --location westus

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

az network nsg rule create \
    --resource-group saltGroup \
    --nsg-name masterSecurityGroup \
    --name masterSecurityGroupRule3200 \
    --protocol tcp \
    --priority 1003 \
    --destination-port-range 3200 \
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
    --location westus \
    --nics masterNic \
    --image UbuntuLTS \
    --admin-username brentmdavies \
    --generate-ssh-keys

#ssh azureuser@mysaltmaster.westus2.cloudapp.azure.com
#Install Salt and InfoSec tools
apt-get install salt-api salt-cloud salt-master salt-minion salt-ssh salt-syndice fail2ban sendmail iptables-persistent apt-transport-https lsb-release gnupg -y

#FIREWALL SETUP: Allow nginx on 3200, SSH 22, Salt on 4505 and 4506 Drop everything else
 iptables -A INPUT -i lo -j ACCEPT
 iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
 iptables -A INPUT -p tcp --dport 22 -j ACCEPT
 iptables -A INPUT -p tcp -m multiport --dports 80,443,3200 -j ACCEPT
 iptables -A INPUT -j DROP
 dpkg-reconfigure iptables-persistent

#FAIL2BAN SETUP:
service fail2ban start

#Salt config
mkdir /srv/salt

#Manual azure salt provider. Will Jinja template in the future
#vim /etc/salt/cloud.providers.d/azure.conf
#my-azure-provider:
#  driver: azure
#  subscription_id: ff768d5f-440a-4922-bf92-3f30ec0a0df5
#  certificate_path: /etc/salt/azure.pem
#
#  minion:
#    master: mysaltmaster.westus.cloudapp.azure.com

#Generate SSL certs
openssl req -x509 -nodes -days 365 -newkey rsa:1024 -keyout /etc/salt/azure.pem -out /etc/salt/azure.pem
openssl x509 -inform pem -in /etc/salt/azure.pem -outform der -out /etc/salt/azure.cer

#vim /etc/salt/cloud.profiles.d/azure.conf 
#azure-ubuntu:
#  provider: my-azure-provider
#  image: 'b39f27a8b8c64d52b05eac6a62ebad85__Ubuntu-16_04-LTS-amd64-server-20171121.1-en-us-30GB'
#  size: Small
#  location: 'West US'
#  ssh_username: brentmin
#  ssh_password: eb20c74f281de8c746307e46fdf15103
#  media_link: 'https://mysaltstorage.blob.core.windows.net/vhds'
#  virtual_network_name: saltVnet
#  subnet_name: minionSubnet
#  security_group: minionSecurityGroup
#  slot: production

salt-cloud -p azure-ubuntu myMinionVM
salt-key -a myMinionVM
