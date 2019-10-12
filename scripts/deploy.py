import grpc
import logging
import sys
from rchain.crypto import PrivateKey
from rchain.client import RClient

root = logging.getLogger()
root.setLevel(logging.DEBUG)
with grpc.insecure_channel('localhost:40401') as channel:
	client = RClient(channel)
	with open(sys.argv[2]) as file:
		data = file.read()
		client.deploy(PrivateKey.from_hex(sys.argv[1]), data, 1, 1000000000)