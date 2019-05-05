#Azure minion Build and Config

az network vnet subnet create --name minionSubnet --address-prefix 10.0.2.0/24 --vnet-name saltVnet --resource-group saltGroup

az network public-ip create --resource-group saltGroup --name minionPublicIP --dns-name mysaltminion

az network nsg create --resource-group saltGroup --name minionSecurityGroup

az network nsg rule create --resource-group saltGroup --nsg-name minionSecurityGroup --name minionSecurityGroupRuleSSH --protocol tcp --priority 1000 --destination-port-range 22 --access allow

az network nic create --resource-group saltGroup --name minionNic --vnet-name saltVnet --subnet minionSubnet --public-ip-address minionPublicIP --network-security-group minionSecurityGroup

ssh azureuser@mysaltmaster.westus2.cloudapp.azure.com
salt-cloud -p azure-ubuntu myMinionVM
salt-key -a myMinionVM

vim /srv/salt/nginx/init.sls

nnginx:
  pkg:
    - installed
  service.running:
    - watch:
      - pkg: nginx
      - file: /etc/nginx/nginx.conf
      - file: /etc/nginx/sites-available/default

vim /srv/salt/top.sls
base:
  'myMinionVM':
    - nginx
