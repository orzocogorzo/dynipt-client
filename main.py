import os
import re
import socket
import subprocess
import logging
import logging.handlers

from dotenv import load_dotenv
load_dotenv()

log = logging.getLogger(__name__)
log.setLevel(logging.DEBUG)
handler = logging.handlers.SysLogHandler(address = '/dev/log')
formatter = logging.Formatter('%(module)s.%(funcName)s: %(message)s')
handler.setFormatter(formatter)
log.addHandler(handler)

home = os.path.abspath(os.path.dirname(__file__))
binary_path = os.path.join(home, ".venv/bin/sshuttle")
conf = f"{home}/config.json"
ssh_user = os.getenv("DYNIPT_USR", "dynipt")

def run():
    rhost = os.getenv("DYNIPT_HOST", "")
    xhost = socket.gethostbyname(rhost.split(":")[0])
    networks = os.getenv("DYNIPT_NETWORKS", "0.0.0.0/0")
    netrange = ""

    for network in networks.split(","):

        if "/" in network:
            netrange = netrange + " " + network
        else:
            netrange = netrange + " " + socket.gethostbyname(network)

    netrange = netrange.strip()
    try:
        log.info("starting dynipt client for networks: %s via %s" % (netrange, rhost))
        p = subprocess.Popen(" ".join([
                "echo",
                os.getenv("DYNIPT_PWD", ""),
                "|",
                "sudo",
                "--stdin",
                binary_path,
                "-r",
                f"{ssh_user}@{rhost}",
                "-x",
                xhost,
                *netrange.split(" "),
                "--ssh-cmd",
                f"'ssh -o StrictHostKeyChecking=no -i {home}/.ssh/id_rsa -o ServerAliveInterval=60'",
                "--no-latency-control"
            ]),
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            shell=True,
        )

        out, err = p.communicate(input=os.getenv("DYNIPT_PWD", "").encode())
        if err and re.search(r"\[sudo\] password for", err.decode()):
            raise Exception(err.decode())

    except Exception as err:
        err = "Error running dynipt client: %s" % str(err)
        log.error(err)

if __name__ == "__main__":
    run()
