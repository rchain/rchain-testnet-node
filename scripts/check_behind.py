"""
This script is to check the health of the rchain service.

You have to config a file with server you want to check health, like below

servers:
  - http://node0.testnet.rchain-dev.tk:40403
  - http://node1.testnet.rchain-dev.tk:40403
  - http://node2.testnet.rchain-dev.tk:40403
  - http://node3.testnet.rchain-dev.tk:40403
  - http://observer.testnet.rchain.coop:40403
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
    result = []
    for server in config['servers']:
        resp = requests.get(server+"/api/blocks/1")
        body = json.loads(resp.text)
        block = body[0]
        number = block['blockNumber']
        result.append((server, number))
    result.sort(key=lambda x:x[1], reverse=True)
    for re in result:
        logging.info("server {} latest block number is {}".format(re[0], re[1]))

if __name__ == '__main__':
    main()
