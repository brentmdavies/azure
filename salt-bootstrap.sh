#brentmdavies Custom Salt Master bootstrap and install

#Install Dependencies
sudo apt-get update
sudo apt-get install fail2ban sendmail iptables-persistent apt-transport-https lsb-release gnupg -y

#FIREWALL SETUP: Allow nginx on 3200 and ssh on 22. Drop everything else
sudo iptables -A INPUT -i lo -j ACCEPT
sudo iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 22 -j ACCEPT
sudo iptables -A INPUT -p tcp -m multiport --dports 80,443,3200 -j ACCEPT
sudo iptables -A INPUT -j DROP
sudo dpkg-reconfigure iptables-persistent

#FAIL2BAN SETUP:
awk '{ printf "# "; print; }' /etc/fail2ban/jail.conf | sudo tee /etc/fail2ban/jail.local
sudo service fail2ban start

##Salt bootstrap installer
#future placeholder for verifying lastest SHA 
#The SHA256 sum of the bootstrap-salt.sh file, per release, is:
#2019.02.27: 23728e4b5e54f564062070e3be53c5602b55c24c9a76671968abbf3d609258cb

curl -o bootstrap-salt.sh -L https://bootstrap.saltstack.com
sudo sh bootstrap-salt.sh git develop

##Install Azure CLI for creating and administering Minion nodes
#Download and install the Microsoft signing key
curl -sL https://packages.microsoft.com/keys/microsoft.asc | \
    gpg --dearmor | \
    sudo tee /etc/apt/trusted.gpg.d/microsoft.asc.gpg > /dev/null

#Add the Azure CLI software repository:
AZ_REPO=$(lsb_release -cs)
echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $AZ_REPO main" | \
    sudo tee /etc/apt/sources.list.d/azure-cli.list

#Update repository information and install the azure-cli package:
sudo apt-get update
sudo apt-get install azure-cli