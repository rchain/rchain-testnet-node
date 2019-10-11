import sys
import grpc
from rchain.crypto import PrivateKey
from rchain.client import RClient

with grpc.insecure_channel('localhost:40401') as channel:
	client = RClient(channel)
	with open(sys.argv[2]) as file:
		data = file.read()
		client.deploy(PrivateKey.from_hex(sys.argv[1]), data, 1, 1000000000)