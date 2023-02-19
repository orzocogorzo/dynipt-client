#!/bin/python3

import os
import sys
import json
import signal
import time
import socket
import subprocess
from subprocess import CalledProcessError
import logging
import logging.handlers

log = logging.getLogger(__name__)
log.setLevel(logging.DEBUG)
handler = logging.handlers.SysLogHandler(address = '/dev/log')
formatter = logging.Formatter('%(module)s.%(funcName)s: %(message)s')
handler.setFormatter(formatter)
log.addHandler(handler)

conf = "/opt/dynipt-client/config.json"
ssh_user = "dynipt"  ## username thats used for SSH connection

def precheck():
    if len(sys.argv) < 2:
        print("need to pass argument: start | stop | restart | status ")
        sys.exit()
    
    if sys.argv[1] in ["help", "-h", "--help", "h"]:
        print("dynipt-client.py start | stop | restart | status")
        sys.exit()

    if not sys.argv[1] in ["start", "stop", "restart", "status"]:
        print("usage: dynipt-client.py start | stop | restart | status")
        sys.exit()
    
    if not os.path.exists(conf):
        print("no dynipt client config file present, exiting.")
        sys.exit()
    
    # check if sshuttle is installed
    try:
        subprocess.check_output(["which", "sshuttle"]).strip()
    except CalledProcessError:
        print("sshuttle is not installed on this host")
        sys.exit()
        
def start():
    with open(conf) as jsondata:
        data = json.load(jsondata)
    
    for rhost in data.keys():
        netrange = ""

        # if single network, turn into List
        if not type(data[rhost]) is list:
            networks = data[rhost].split()
        else:
            networks = data[rhost]

        for network in networks:
            
            # check if CIDR format
            if "/" in network:
                netrange = netrange + " " + network
            else:
                netrange = netrange + " " + socket.gethostbyname(network)
        netrange = netrange.strip()
        xhost = socket.gethostbyname(rhost.split(":")[0])
        
        # build rpath
        rpath = "-r {0}@{1} -x {2} {3} --ssh-cmd 'ssh -i /opt/dynipt-client/.ssh/id_rsa -o ServerAliveInterval=60' --no-latency-control".format(
            ssh_user,
            rhost,
            xhost,
            netrange,
        )
        try:
            print("starting dynipt client..")
            log.info("starting dynipt client for networks: %s via %s" % (netrange, rhost))
            subprocess.Popen("sshuttle {}".format(rpath), shell=True) 
        except CalledProcessError as err:
            log.error("error running dynipt client: %s" % str(err))
        
        # sleep to give connection time to establish SSH handshake, in case other connections use this conn as a hop
        time.sleep(3)

def get_pid():
    search = "ps -ef | grep '/usr/bin/python /usr/share/sshuttle/main.py /usr/bin/python -r' | grep -v grep | awk {'print $2'}"    
    pids = []
    for line in os.popen(search):
        fields = line.split()
        pids.append(fields[0])
    return pids

def stop():
    pids = get_pid()
    for pid in pids:
        print("stopping dynipt client PID %s " % pid)
        log.info("stopping dynipt client")
        os.kill(int(pid), signal.SIGTERM)

def status():
    pids = get_pid()
    if pids:
        print("dynipt client is running..")
    else:
        print("dynipt client is not running..")

if __name__ == "__main__":

    precheck()

    cmd = sys.argv[1].lower()

    if cmd == "start":
        start()

    if cmd == "stop":
        stop()
    
    if cmd == "restart":
        print("restarting dynipt client..")
        stop()
        start()
        
    if cmd == "status":
        status()

