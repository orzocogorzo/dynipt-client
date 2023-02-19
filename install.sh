#! /bin/bash

DIR=/opt/dynipt-client

# System requirements
sudo apt update
sudo apt install -y python3 python3-venv sshuttle git

# User creation
sudo useradd -d $DIR -s /usr/sbin/nologin dynipt

# Package download
sudo git clone https://github.com/orzocogorzo/dynipt-client.git $DIR
sudo chown -R dynipt: $DIR

# Identity
sudo -u dynipt mkdir $DIR/.ssh
sudo chmod 700 $DIR/.ssh
sudo -u dynipt ssh-keygen -a 100 -t rsa -N "" -C "sshuttle_key" -f $DIR/.ssh/id_rsa

# SystemD configuration
sudo cp $DIR/snippets/dynipt-client.service /etc/systemd/system/dynipt-client.service
sudo systemctl daemon-reload

# Python requirements
cd $DIR
sudo -u dynipt python3 -m venv .venv
sudo -u dynipt .venv/bin/python -m pip install -r requirements.txt

# Client start
sh/service.sh start

echo "DynIPt client is running"
echo "Your public IP is: $(curl ip.yunohost.org)"
