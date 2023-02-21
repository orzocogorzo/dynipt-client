#! /bin/bash

DIR=/opt/dynipt-client
read -p "Remote host IP/FQDN: " DYNIPT_HOST
read -p "DynIPt user password: " DYNIPT_PWD

# System requirements
sudo apt update
sudo apt install -y python3 python3-venv git iptables

# User creation
sudo useradd -d $DIR -s /usr/sbin/nologin dynipt
sudo usermod -aG sudo dynipt

# Package download
sudo git clone https://github.com/orzocogorzo/dynipt-client.git $DIR
sudo sh -c "echo "DYNIPT_PWD=$DYNIPT_PWD" > $DIR/.env" && sudo chmod 600 $DIR/.env
sudo chown -R dynipt: $DIR

# Identity
sudo -u dynipt mkdir $DIR/.ssh
sudo chmod 700 $DIR/.ssh
sudo -u dynipt ssh-keygen -a 100 -t rsa -N "" -C "sshuttle_key" -f $DIR/.ssh/id_rsa
read -p "DynIPt remote host user: " DYNIPT_RUSER
sudo -u dynipt ssh-copy-id -i $DIR/.ssh/id_rsa.pub $DYNIPT_RUSER@$DYNIPT_HOST

# SystemD configuration
sudo cp $DIR/snippets/systemd.service /etc/systemd/system/dynipt-client.service
sudo systemctl daemon-reload

# Python requirements
cd $DIR
sudo -u dynipt python3 -m venv .venv
sudo -u dynipt .venv/bin/python -m pip install -r requirements.txt

# DynIPt config
sudo -u dynipt sh -c "echo '{\"$DYNIPT_HOST\": [\"0.0.0.0/0\"]}' > $DIR/config.json"

# Client start
sudo systemctl start dynipt-client.service

echo "DynIPt client is running"
echo "Your public IP is: $(curl ip.yunohost.org)"
