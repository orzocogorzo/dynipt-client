# DynIPt client

Proxy your LAN networks with [sshuttle](https://github.com/sshuttle/sshuttle)
through a remote hosts to achive static IP exposures.

_* Based on the work made by [perfecto25](https://gist.github.com/perfecto25) on this [gist](https://gist.github.com/perfecto25/6e9a0c982fb76401f720b661f1a8a9f1)._

## Description

Tiny solution to setup a VPS as a proxy to your local network. It acts as a
VPN, without all the headaches of the VPNs. The only requirement is to get
access via SSH to the remote server. With this solution you can reach the
internet from your home stations through a static IP.

## How it works?

The service relays on **shuttle**, who performs all the work. This client only
offers an installation script and a couple of snippets to configure **sshuttle**
as a daemon service with an agile interface to up and down the process.

**sshuttle** use [iptables](http://iptables.org/) and [ssh](https://www.openssh.com/)
connections to setup a transparent proxy from your local machine to your remote host.
If do you want to read more about it, look [this docs about how it works](https://sshuttle.readthedocs.io/en/latest/how-it-works.html).

## Installation

### On your local machine

To install **DynIPt client** on your local machine run:

```bash
curl -s https://raw.githubusercontent.com/orzocogorzo/dynipt-client/main/sh/install.sh > dynipt-install && bash ./dynipt-install
```

### On your VPS

On your VPS, you only will need [openssh](https://www.openssh.com/) installed, a user
with access via ssh, and, at least, during the installation, the password authentication
mode enabled for ssh sessions. **The user on the VPS doesn't need root permissions**.

### Manual installation

If you need some customization on your installation, or you want to install **DynIPt client**
into a non-debian based OS, follow the next steps and modify

#### System requirements

```bash
apt update && apt install -y python3 python3-venv git iptables curl
```

#### Package download

```bash
git clone https://github.com/orzocogorzo/dynipt-client.git /opt/dynipt-client
```

#### User creation

```bash
useradd -d /opt/dynipt-client -s /usr/sbin/nologin dynipt
usermod -aG sudo dynipt > /dev/null
chown -R dynipt: $DIR > /dev/null
passwd dynipt
```

#### SSH credentials

```bash
mkdir -p /opt/dynipt-client/.ssh
chmod 700 /opt/dynipt-client/.ssh
ssh-keygen -a 100 -t rsa -N "" -C "dynipt_key" -f /opt/dynipt-client/.ssh/id_rsa
ssh-copy-id -i /opt/dynipt-client/.ssh/id_rsa.pub {ruser}@{rhost}
```

#### Python requirements

```bash
python3 -m venv /opt/dynipt-client/.venv
/opt/dynipt-client/.venv/bin/python -m pip install -r requirements.txt
```

## Config

The configuration of your instance is placed on the `.env` file placed on the root
directory of the package, next to the `main.py` file.

### Options

```bash
# The remote host's user name with ssh access
DYNIPT_USR=username

# The password of the dedicated system user on the local machine
DYNIPT_PWD=******

# The IP of your remote host
DYNIPT_HOST=0.0.0.0

# The IP of your local machine network interface
DYNIPT_NETWORK=0.0.0.0
```

## Start up the service

### With shell scripts

```bash
# Start the service with
sudo -u dynipt /opt/dynipt-client/sh/dynipt-client.sh start

# Stop the service with
sudo -u dynipt /opt/dynipt-client/sh/dynipt-client.sh stop
```

### With systemd

Another way to start/stop the service is as a SystemD service. You can find an
service definition example on [`snippets/systemd.service`](https://github.com/orzocogorzo/dynipt-client/blob/main/snippets/systemd.service).
Edit the file to fit to your environment and move and rename it as `/etc/systemd/system/dynipt-client.service`.
After that, run

```bash
# Reload the new configuration
sudo systemctl daemon-reload

# Enable automatic boot time starts
sudo systemctl enable dynipt-client

# Disable automatic boot time starts
sudo systemctl disable dynipt-client

# Manually start the service
sudo systemctl start dynipt-client

# Manually stop the service
sudo systemctl stop dynipt-client
```
