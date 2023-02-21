#! /bin/bash

echo "Start dynipt-client installation"

DIR=/opt/dynipt-client
read -p "Remote host IP/FQDN: " DYNIPT_HOST
read -p "DynIPt remote host user: " DYNIPT_USR
DYNIPT_PWD=$(date +%s | sha256sum | base64 | head -c 32; echo)
echo

# System requirements
echo "Installing system requirements..."
sudo apt -qq update > /dev/null 2>&1
sudo apt install -qqy python3 python3-venv git iptables curl > /dev/null 2>&1
echo "System requirements installeds"
echo

# Package download
echo "Getting source code..."
sudo git clone -q https://github.com/orzocogorzo/dynipt-client.git $DIR
echo "Source code placed on $DIR"
echo

# User creation
echo "Creating system user 'dynipt'..."
sudo useradd -d $DIR -s /usr/sbin/nologin dynipt > /dev/null
sudo usermod -aG sudo dynipt > /dev/null
sudo chown -R dynipt: $DIR > /dev/null
echo -e "$DYNIPT_PWD\n$DYNIPT_PWD" | sudo passwd dynipt > /dev/null
echo "'dynipt' user created"
echo

# SSH credentials
echo "Configuring ssh DynIPt credentials..."
sudo -u dynipt mkdir -p $DIR/.ssh
sudo -u dynipt chmod 700 $DIR/.ssh
sudo -u dynipt test ! -f $DIR/.ssh/id_rsa && sudo -u dynipt ssh-keygen -a 100 -t rsa -N "" -C "sshuttle_key" -f $DIR/.ssh/id_rsa > /dev/null
sudo -u dynipt ssh-copy-id -o StrictHostKeyChecking=no -i $DIR/.ssh/id_rsa.pub $DYNIPT_USR@$DYNIPT_HOST > /dev/null 2>&1
echo "DynIPt ssh credentials createds"
echo

# SystemD configuration
echo "Configuring dynipt-client SystemD service..."
sudo cp $DIR/snippets/systemd.service /etc/systemd/system/dynipt-client.service
sudo systemctl daemon-reload
echo "SystemD service created"
echo

# Python requirements
echo "Installing Python dependencies..."
cd $DIR
sudo -u dynipt python3 -m venv .venv
sudo -u dynipt .venv/bin/python -m pip install -r requirements.txt > /dev/null
echo "Python is ready"
echo

# DynIPt config
echo "Configuring dynipt-client dotfile..."
sudo -u dynipt sh -c "echo "DYNIPT_PWD=$DYNIPT_PWD" > $DIR/.env"
sudo -u dynipt sh -c "echo "DYNIPT_USR=$DYNIPT_USR" >> $DIR/.env"
sudo -u dynipt sh -c "echo "DYNIPT_HOST=$DYNIPT_HOST" >> $DIR/.env"
sudo chmod 600 $DIR/.env
echo

# Client start
sudo systemctl start dynipt-client.service

echo "DynIPt client is running"
echo "Your public IP is: $(curl -s ip.yunohost.org)"
