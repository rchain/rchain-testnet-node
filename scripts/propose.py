import grpc
from rchain.client import RClient

with grpc.insecure_channel('localhost:40401') as channel:
	client = RClient(channel)
	client.propose()