#!/bin/bash
# Usage: ./restart.sh node0
# Invoke inside folder with secrets
#
# 1) Fetch docker-compose.yml, modify with rnode docker image and push it to the mainnet
# 2) Fetch rnode-v2.conf, modify with old config's private key, and push to mainnet

node=$1; 
RNODE_IMAGE=rchain/rnode:v0.9.25
#BOOTSTRAP="rnode://191622c4b5f733ab4366d4cdb3f335126d744b17@node8.root-shard.mainnet.rchain.coop?protocol=40400&discovery=40404"
BOOTSTRAP="rnode://487e2c0c519b450b61253dea0a23b4d184a50089@node0.root-shard.mainnet.rchain.coop?protocol=40400&discovery=40404"

# Check if the old config file exists?
if [[ ! -f $node.rnode.conf ]]; then
	echo "$0: <$node> old config file missing!"
	exit 1
fi

# Update docker-compose.yml with rnode image and move it to the mainnet server
if [[ ! -f docker-compose.yml ]]; then
	wget https://raw.githubusercontent.com/rchain/rchain-testnet-node/dev/node-files.mainnet-val/docker-compose.yml
fi
sed -i "s+RNODE_IMAGE+$RNODE_IMAGE+" docker-compose.yml
scp docker-compose.yml root@$node.root-shard.mainnet.rchain.coop:/var/lib/rnode

# Update config file and move it to the mainnet server
if [[ ! -f $node.rnode-v2.conf ]]; then
	curl https://raw.githubusercontent.com/rchain/rchain-testnet-node/dev/node-files.mainnet-val/rnode-v2.conf -o $node.rnode-v2.conf
fi
PRIV_KEY=`grep validator-private-key $node.rnode.conf | awk '{print $2}'`
sed -i "s/PRIV_KEY/$PRIV_KEY/" $node.rnode-v2.conf
sed -i "s+NODE_HOST+$node+" $node.rnode-v2.conf
sed -i "s+BOOTSTRAP+$BOOTSTRAP+" $node.rnode-v2.conf
scp $node.rnode-v2.conf root@$node.root-shard.mainnet.rchain.coop:/var/lib/rnode/rnode-v2.conf

# Run rnode via docker-compose
ssh root@$node.root-shard.mainnet.rchain.coop \
"docker stop rnode && docker rm rnode \
&& \
(cd /var/lib/rnode;docker-compose up -d rnode) \
&& \
sleep 5 \
&& \
rm /var/lib/rnode/rnode-v2.conf"
