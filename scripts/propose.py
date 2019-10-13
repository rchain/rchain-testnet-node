import grpc
import logging
from rchain.client import RClient
from rchain.client import RClientException

root = logging.getLogger()
root.setLevel(logging.DEBUG)

with grpc.insecure_channel('localhost:40401') as channel:
    client = RClient(channel)
    try:
        client.propose()
    except RClientException as e:
        # NoNewDeploys is a valid scenario
        if "NoNewDeploys" not in str(e):
            raise
