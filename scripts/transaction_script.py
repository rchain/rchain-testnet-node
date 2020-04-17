import logging
import sys
from argparse import ArgumentParser
import json

try:
    import thread
except ImportError:
    import _thread as thread
from rchain.client import RClient
from rchain.param import mainnet_param
import websocket
from collections import defaultdict



handler = logging.StreamHandler(sys.stdout)
handler.setLevel(logging.INFO)
root = logging.getLogger()
formatter = logging.Formatter("%(asctime)s-%(levelname)s-%(message)s")
handler.setFormatter(formatter)
root.addHandler(handler)
root.setLevel(logging.INFO)


parser = ArgumentParser(description="reporting performance test")
parser.add_argument("--port", action="store", type=str, required=True, dest="port")
parser.add_argument( "--host", action="store", type=str, required=True, dest="host")
parser.add_argument("--grpc-port", action="store", type=str, required=True, dest="grpc_port")
args = parser.parse_args()


def on_message(ws, message):
    logging.info(message)
    mes = json.loads(message)
    event = mes.get("event")
    if event == "block-added":
        payload = mes.get('payload')
        block_hash = payload.get('block-hash')
        result = ws.rclient.get_transaction(block_hash)
        logging.info("The result is {}".format(result))


def on_error(ws, error):
    logging.error(error)


def on_close(ws):
    logging.info("### closed ###")


def on_open(ws):
    logging.info("### open ###")


class EventDispatcher:

    def __init__(self):
        self.event_registry = defaultdict(list)

    def register(self, event, callback):
        self.event_registry[event].append(callback)

    def trigger(self, event, data):
        for call in self.event_registry[event]:
            call(data)


def main():
    websocket.enableTrace(True)
    ws = websocket.WebSocketApp("ws://{}:{}/ws/events".format(args.host, args.port),
                                on_message=on_message,
                                on_error=on_error,
                                on_close =on_close,
                                on_open=on_open)
    print(args)
    ws.rclient = RClient(args.host, args.grpc_port)
    ws.rclient.install_param(mainnet_param)


    ws.run_forever()


if __name__ == '__main__':
    main()
