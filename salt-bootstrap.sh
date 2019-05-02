#brentmdavies Custom Salt Master bootstrap and install

#Install Dependencies
sudo apt-get update
sudo apt-get install fail2ban sendmail iptables-persistent -y

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

#Salt bootstrap installer
curl -o bootstrap-salt.sh -L https://bootstrap.saltstack.com
sudo sh bootstrap-salt.sh git develop

