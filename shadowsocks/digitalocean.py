from __future__ import absolute_import, division, print_function, \
    with_statement

import sys
import os
import logging
import signal

sys.path.insert(0, os.path.join(os.path.dirname(__file__), '../'))
from shadowsocks import shell, daemon, eventloop, tcprelay, udprelay, \
    asyncdns, manager


# deploy to digitalocean
def main():
    shell.check_python()
    # todo
    # 1) use DO api key to create a droplet.
    # 2) ssh to server
    # 3) git clone my fork
    # 4) copy my config
    # 5) deploy using my config
