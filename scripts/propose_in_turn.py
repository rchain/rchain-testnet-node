"""
This script needs a yaml config file like below:

servers:
  - node0:
      host: node0.sandboxnet.rchain-dev.tk
      grpc_port: 40401
      http_port: 40403
  - node1:
      host: node1.sandboxnet.rchain-dev.tk
      grpc_port: 40401
      http_port: 40403
  - node2:
      host: node2.sandboxnet.rchain-dev.tk
      grpc_port: 40401
      http_port: 40403
orders:
  - node1
  - node2
  - node0
deploy:
    contract: /rchain/rholang/examples/hello_world_again.rho
    phlo_limit: 100000
    phlo_price: 1
    deploy_key: 34d969f43affa8e5c47900e6db475cb8ddd8520170ee73b2207c54014006ff2b

This script would take the orders node1 -> node2 -> node2 to propose block in order.

"""

import logging
import asyncio
import sys
from argparse import ArgumentParser
import yaml
import grpc
import queue
import websockets
import json
import time
from rchain.client import RClient
from rchain.crypto import PrivateKey

handler = logging.StreamHandler(sys.stdout)
handler.setLevel(logging.INFO)
root = logging.getLogger()
root.addHandler(handler)
root.setLevel(logging.INFO)

loop = asyncio.get_event_loop()

parser = ArgumentParser(description="In turn propose script")
parser.add_argument("-c", "--config-file", action="store", type=str, required=True, dest="config",
                    help="the config file of the script")

args = parser.parse_args()

class Client():
    def __init__(self, grpc_client, websocket_client, host_name):
        self.grpc_client = grpc_client
        self.websocket_client = websocket_client
        self.host_name = host_name
        self.asycn_ws = None

    async def setup(self):
        self.asycn_ws = await self.websocket_client


class DispatchCenter():
    def __init__(self, config):
        logging.info("Initialing dispatcher")
        self._config = config

        self.clients = {}
        for server in config['servers']:
            for host_name, host_config in server.items():
                self.clients[host_name] = init_client(host_name,host_config)

        self.orders = config['orders']

        logging.info("Read the deploying contract {}".format(config['deploy']['contract']))
        with open(config['deploy']['contract']) as f:
            self.contract = f.read()
        logging.info("Checking if deploy key is valid.")
        self.deploy_key = PrivateKey.from_hex(config['deploy']['deploy_key'])
        self.phlo_limit = int(config['deploy']['phlo_limit'])
        self.phlo_price = int(config['deploy']['phlo_price'])

        self.queue = queue.Queue()
        for host in self.orders:
            self.queue.put_nowait(host)

        self._running = False

    def deploy_and_propose(self, client):
        client.grpc_client.deploy_with_vabn_filled(self.deploy_key, self.contract, self.phlo_price, self.phlo_limit,
                                                   int(time.time() * 1000))
        return client.grpc_client.propose()

    async def wait_server_to_receive(self, client, block_hash):
        logging.info("Waiting {} to receive {}".format(client.host_name, block_hash))
        while True:
            message = await client.asycn_ws.recv()
            logging.info("Receive {} from {}".format(message, client.host_name))
            deco_mes = json.loads(message)
            if deco_mes['event'] == 'block-added' and deco_mes['payload']['block-hash'] == block_hash:
                logging.info("Waiting Done!")
                break
            else:
                logging.info("The block hasn't been added")

    async def run(self):
        self._running = True
        logging.info("Setup websocket client")
        await self.init_ws_client()

        current_server = self.queue.get_nowait()
        while self._running:
            logging.info("Going to deploy and propose in {}".format(current_server))
            block_hash = self.deploy_and_propose(self.clients[current_server])
            logging.info("Successfully deploy and propose {} in {}".format(block_hash, current_server))
            next_server = self.queue.get_nowait()
            await self.wait_server_to_receive(self.clients[next_server], block_hash)
            self.queue.put_nowait(current_server)
            current_server = next_server

    async def init_ws_client(self):
        for client in self.clients.values():
            await client.setup()


with open(args.config) as f:
    config = yaml.load(f)


def init_client(host_name, host_config):
    channel = grpc.insecure_channel("{}:{}".format(host_config['host'], host_config['grpc_port']))
    client = RClient(channel)
    ws = websockets.connect("ws://{}:{}/ws/events".format(host_config['host'], host_config['http_port']), loop=loop)
    return Client(client, ws, host_name)


dispatcher = DispatchCenter(config)
loop.run_until_complete(dispatcher.run())
