#!/bin/bash
# Usage: ./restart.sh node0
# Invoke inside folder with secrets

node=$1; 
RNODE_IMAGE=rchain/rnode:v0.9.25
#BOOTSTRAP="rnode://191622c4b5f733ab4366d4cdb3f335126d744b17@node8.root-shard.mainnet.rchain.coop?protocol=40400&discovery=40404"
BOOTSTRAP="rnode://487e2c0c519b450b61253dea0a23b4d184a50089@node0.root-shard.mainnet.rchain.coop?protocol=40400&discovery=40404"

if [[ ! -f ./docker-compose.yml ]]; then
	wget https://raw.githubusercontent.com/rchain/rchain-testnet-node/dev/node-files.mainnet-val/docker-compose.yml
	sed -i "s+RNODE_IMAGE+$RNODE_IMAGE+" ./docker-compose.yml
	sed -i "s+NODE+$node+" ./docker-compose.yml
	sed -i "s+BOOTSTRAP+$BOOTSTRAP+" ./docker-compose.yml
	
	scp ./docker-compse.yml root@$node.root-shard.mainnet.rchain.coop:/var/lib/rnode
fi

if [[ ! -f ./$node.rnode-v2.conf ]]; then
	curl https://raw.githubusercontent.com/rchain/rchain-testnet-node/dev/node-files.mainnet-val/rnode-v2.conf -o $node.rnode-v2.conf
	KEY=`grep validator-private-key $node.rnode.conf | awk '{print $2}'`
	sed -i "s/# validator-private-key =/validator-private-key = $KEY/" $node.rnode-v2.conf
fi

scp ./$node.rnode-v2.conf root@$node.root-shard.mainnet.rchain.coop:/var/lib/rnode/rnode-v2.conf
ssh root@$node.root-shard.mainnet.rchain.coop \
"docker stop rnode && docker rm rnode \
&& \
(cd /var/lib/rnode;docker-compose up -d rnode) \
&& \
sleep 5 \
&& \
rm /var/lib/rnode/rnode-v2.conf"
