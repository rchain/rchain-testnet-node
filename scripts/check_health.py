"""
This script is to check the health of the rchain service.

You have to config a file with server you want to check health, like below

servers:
  - http://node0.testnet.rchain-dev.tk:40403
  - http://node1.testnet.rchain-dev.tk:40403
  - http://node2.testnet.rchain-dev.tk:40403
  - http://node3.testnet.rchain-dev.tk:40403
  - http://observer.testnet.rchain.coop:40403
check_interval:
      5
"""
import logging
import sys
import yaml
from argparse import ArgumentParser
import json
import time
import requests

handler = logging.StreamHandler(sys.stdout)
handler.setLevel(logging.INFO)
root = logging.getLogger()
formatter = logging.Formatter("%(asctime)s-%(levelname)s-%(message)s")
handler.setFormatter(formatter)
root.addHandler(handler)
root.setLevel(logging.INFO)

parser = ArgumentParser(description="reporting performance test")
parser.add_argument("--config", action="store", type=str, required=True, dest="config")
args = parser.parse_args()

with open(args.config) as f:
    config = yaml.load(f)

def main():
    while True:
        for server in config['servers']:
            resp = requests.get(server+"/status")
            if resp.status_code != 200:
                raise ValueError()
            else:
                logging.info("{} is working ok".format(server))
        time.sleep(config['check_interval'])


if __name__ == '__main__':
    main()
