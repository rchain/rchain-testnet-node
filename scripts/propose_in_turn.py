"""
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
  - node3:
      host: node3.sandboxnet.rchain-dev.tk
      grpc_port: 40401
      http_port: 40403
  - node4:
      host: node4.sandboxnet.rchain-dev.tk
      grpc_port: 40401
      http_port: 40403
waitTimeout: 300
waitInterval: 10
proposeInterval: 0
valid_offset: 0
error_logs: /rchain/rchain-testnet-node/error.log
pause_path: /rchain/pause.propose
keepalive: 10
keepalive_timeout: 10
max_propose_retry: 3
deploy:
    contract: /rchain/rholang/examples/hello_world_again.rho
    phlo_limit: 100000
    phlo_price: 1
    deploy_key: 34d969f43affa8e5c47900e6db475cb8ddd8520170ee73b2207c54014006ff2b
    shardID: shardID

This script would take the orders node1 -> node2 -> node2 to propose block in order.

"""

import logging
import os
import sys
import time
from argparse import ArgumentParser
from collections import deque

import grpc
import yaml
from rchain.client import RClient, RClientException
from rchain.crypto import PrivateKey

formatter = logging.Formatter('%(asctime)s - %(levelname)s - %(message)s')
handler = logging.StreamHandler(sys.stdout)
handler.setFormatter(formatter)
handler.setLevel(logging.INFO)
root = logging.getLogger()
root.addHandler(handler)
root.setLevel(logging.INFO)

parser = ArgumentParser(description="In turn propose script")
parser.add_argument("-c", "--config-file", action="store", type=str, required=True, dest="config",
                    help="the config file of the script")

args = parser.parse_args()


class Client():
    def __init__(self, host, grpc_port, websocket_host, host_name, keepalive, keepalive_timeout, valid_offset):
        self.host = host
        self.port = int(grpc_port)
        self.grpc_host = "{}:{}".format(host, grpc_port)
        self.websocket_host = "ws://{}:{}/ws/events".format(host, websocket_host)
        self.host_name = host_name
        self.asycn_ws = None
        self.keepalive = int(keepalive * 1000)
        self.keepalive_timeout = int(keepalive_timeout * 1000)
        self.valid_offset = valid_offset
        self.grpc_options = (
            ('grpc.keepalive_time_ms', self.keepalive), ('grpc.keepalive_timeout_ms', self.keepalive_timeout),)

        self.latest_message = None

    def get_lastest_block_hash(self):
        with RClient(self.host, self.port, self.grpc_options) as client:
            latest_blocks = client.show_blocks(1)
            # TODO consider situation multiple blocks in the same block number
            self.latest_message = latest_blocks[0].blockHash
            return self.latest_message

    def deploy_and_propose(self, deploy_key, contract, phlo_price, phlo_limit, waitforPropose, shard_ID):
        with RClient(self.host, self.port, self.grpc_options) as client:
            try:
                logging.info("Trying to propose directly. on {}".format(self.host_name))
                blockhash = client.propose()
                logging.info("Successfully propose directly {} on {}".format(blockhash, self.host_name))
                return blockhash
            except RClientException as e:
                error_message = e.args[0]
                if "NoNewDeploys" in error_message:
                    logging.info("The node {} doesn't have new deploy. Going to deploy now".format(self.host_name))
                    try:
                        timestamp = int(time.time() * 1000)
                        if self.valid_offset != 0:
                            latest_blocks = client.show_blocks(1)
                            latest_block = latest_blocks[0]
                            latest_block_num = latest_block.blockNumber
                            deploy_id = client.deploy(deploy_key, contract, phlo_price, phlo_limit,
                                                      latest_block_num + self.valid_offset,timestamp, shard_ID)
                        else:
                            deploy_id = client.deploy_with_vabn_filled(deploy_key, contract, phlo_price,
                                                                       phlo_limit,
                                                                       timestamp, shard_ID)
                        logging.info("Succefully deploy {}".format(deploy_id))
                        logging.info("going to propose on {}".format(self.host_name))
                        start = time.time()
                        block_hash = client.propose()
                        logging.info("Successfully propose {} done and it takes {} second on {}".format(block_hash,
                                                                                                        time.time() - start,
                                                                                                        self.host_name))
                    except grpc.RpcError as e:
                        logging.info(
                            "Sleep {} and try again because :deploy and propose {} got grpc error: {}, {}".format(
                                waitforPropose, self.host_name, e.details(), e.code()))
                        time.sleep(waitforPropose)
                        return
                    return block_hash
                else:
                    logging.error("unknown error on proposing {}: {}".format(self.host_name, e))
                    return
            except grpc.RpcError as e:
                logging.warning("Directly propose {} got grpc error: {}, {}".format(self.host_name, e.details(),
                                                                                    e.code()))
                return
            except Exception as e:
                logging.error("Unknown error: {}".format(e))
                raise e

    def is_contain_block_hash(self, block_hash):
        with RClient(self.host, self.port, self.grpc_options) as client:
            if block_hash is None:
                logging.error("The blockhash can not be None")
                return False
            try:
                client.show_block(block_hash)
                return True
            except RClientException:
                logging.info("node {} doesn't contain {}".format(self.host_name, block_hash))
                return False
            except grpc.RpcError as e:
                logging.info("ShowBlock {} got grpc error: {}, {}".format(block_hash, e.details(), e.code()))
                return False


class DispatchCenter():
    def __init__(self, config):
        self.setup_error_log(config['error_logs'])
        logging.info("Initialing dispatcher")
        self._config = config

        self.clients = {}

        self.keepalive = config['keepalive']
        self.keepalive_timeout = config['keepalive_timeout']
        self.valid_offset = config['valid_offset']
        for server in config['servers']:
            for host_name, host_config in server.items():
                self.clients[host_name] = init_client(host_name, host_config, self.keepalive, self.keepalive_timeout,
                                                      self.valid_offset)

        logging.info("Read the deploying contract {}".format(config['deploy']['contract']))
        with open(config['deploy']['contract']) as f:
            self.contract = f.read()
        logging.info("Checking if deploy key is valid.")
        self.deploy_key = PrivateKey.from_hex(config['deploy']['deploy_key'])

        self.phlo_limit = int(config['deploy']['phlo_limit'])
        self.phlo_price = int(config['deploy']['phlo_price'])
        self.shard_ID = config['deploy']['shardID']

        self.wait_timeout = int(config['waitTimeout'])
        self.wait_interval = int(config['waitInterval'])

        self.propose_interval = int(config['proposeInterval'])

        self.pause_path = config['pause_path']

        self.init_queue()

        self._running = False

    def get_latest_blocks_from_every_one(self):
        latest_blocks = {}
        for key, value in self.clients.items():
            latest_hash = value.get_lastest_block_hash()
            assert latest_hash
            latest_blocks[key] = latest_hash
            logging.info("Checked node {} latest mes is {}".format(key, latest_hash))
        return latest_blocks

    def make_sure_every_one_on_the_same_page(self):
        latest_blocks = self.get_latest_blocks_from_every_one()
        set_blockHash = set([i for i in latest_blocks.values()])
        logging.info("Checking every node is on the same page {}".format(set_blockHash))
        return len(set_blockHash) == 1

    def setup_error_log(self, path):
        handler = logging.FileHandler(path)
        handler.setLevel(logging.ERROR)
        root.addHandler(handler)

    def deploy_and_propose(self):
        current_server = self.queue.popleft()
        logging.info("Going to deploy and propose in {}".format(current_server))
        client = self.clients[current_server]
        try:
            self.queue.append(current_server)
            block_hash = client.deploy_and_propose(self.deploy_key, self.contract, self.phlo_price, self.phlo_limit,
                                                   self.wait_interval, self.shard_ID)
            return block_hash
        except Exception as e:
            logging.error("Node {} can not deploy and propose because of {}".format(client.host_name, e))

    def wait_next_server_to_be_different(self, block_hash):
        """return True when the next server receive the block hash"""
        current_time = int(time.time())
        wait_server = self.queue.popleft()
        client = self.clients[wait_server]
        logging.info("Waiting {} to be different from last block hash {} at {}".format(client.host_name, block_hash,
                                                                                       current_time))
        while 1:
            try:
                time.sleep(self.wait_interval)
                latest_block = client.get_lastest_block_hash()
                is_different = latest_block != block_hash
                if is_different:
                    logging.info(
                        "Node {} successfully receive new block hash {} from {}".format(client.host_name, latest_block,
                                                                                        block_hash))
                    self.queue.appendleft(wait_server)
                    return latest_block
                else:
                    logging.info(
                        "Node {} does not have new block hash from {}. Sleep {} s and try again".format(
                            client.host_name,
                            block_hash,
                            self.wait_interval))
            except Exception as e:
                logging.error(
                    "There is something wrong with node {}, exception {}".format(client.host_name, e))
                sys.exit(1)

    def init_queue(self):
        self.queue = deque()
        for client in self.clients.values():
            self.queue.append(client.host_name)

    def pause_check(self):
        return os.path.isfile(self.pause_path)

    def run(self):
        while not self.make_sure_every_one_on_the_same_page():
            logging.info("every is not on the same page, check in {}".format(self.wait_interval))
            time.sleep(self.wait_interval)

        last_block_hash = list(self.clients.values())[0].get_lastest_block_hash()

        self._running = True
        while self._running:
            while self.pause_check():
                logging.info(
                    "The script found the pause file. The script will continue until the pause file {} is removed. Sleep {}".format(
                        self.pause_path, self.wait_interval))
                time.sleep(self.wait_interval)

            logging.info("Sleep {} seconds before proposing.".format(self.propose_interval))
            time.sleep(self.propose_interval)
            self.deploy_and_propose()
            last_block_hash = self.wait_next_server_to_be_different(last_block_hash)


with open(args.config) as f:
    config = yaml.load(f)


def init_client(host_name, host_config, keepalive, keepalive_timeout, valid_offset):
    return Client(host_config['host'], host_config['grpc_port'], host_config['http_port'], host_name, keepalive,
                  keepalive_timeout, valid_offset)


if __name__ == '__main__':
    dispatcher = DispatchCenter(config)
    dispatcher.run()
