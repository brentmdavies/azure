#Salt bootstrap and install

sudo apt-get update
sudo apt-get install fail2ban

curl -o bootstrap-salt.sh -L https://bootstrap.saltstack.com
sudo sh bootstrap-salt.sh git develop
