#!/bin/bash
# Usage: ./restart.sh 00
# Invoke inside folder with secrets
#
# 1) Fetch docker-compose.yml, modify with rnode docker image and push it to the mainnet
# 2) Fetch rnode-v2.conf, modify with old config's private key, and push to mainnet
set -e

# When changing RNODE_IMAGE, remove local docker-compose.yml file so new version is downloaded
RNODE_IMAGE=rchain/rnode:v0.9.25.1
#BOOTSTRAP="rnode://191622c4b5f733ab4366d4cdb3f335126d744b17@node8.root-shard.mainnet.rchain.coop?protocol=40400&discovery=40404"
BOOTSTRAP="rnode://487e2c0c519b450b61253dea0a23b4d184a50089@node0.root-shard.mainnet.rchain.coop?protocol=40400&discovery=40404"
# escape all regex special characters, especially ampersand
BOOTSTRAP="$(<<< "$BOOTSTRAP" sed -e 's`[][\\/.*^$&]`\\&`g')"
KEY_FILE="mainnet-val.dat"

if [[ $# -eq 0 ]] ; then
    echo "$0: Missing node number.  Usage: ./restart.sh 00"
    exit 1
fi

# Check if the arguement is number only
fmt='^[0-9]+$'
if ! [[ $1 =~ $fmt ]] ; then
    echo "$0: Arguement <$1> has to be a number (i.e. 00 or 12)"
    exit 1
fi

if [[ ! -f $KEY_FILE ]]; then
	echo "$0: Missing keys <$KEY_FILE> file"
	exit 1
fi

# Convert number to base 10 and remove any leading 0
node="node$((10#$1))"

# Update docker-compose.yml with rnode image and move it to the mainnet server
if [[ ! -f docker-compose.yml ]]; then
	wget https://raw.githubusercontent.com/rchain/rchain-testnet-node/dev/node-files.mainnet-val/docker-compose.yml
	sed -i "s+RNODE_IMAGE+$RNODE_IMAGE+" docker-compose.yml
fi
scp docker-compose.yml root@$node.root-shard.mainnet.rchain.coop:/var/lib/rnode

# Update config file and move it to the mainnet server
if [[ ! -f $node.rnode-v2.conf ]]; then
	PRIV_KEY=`grep $1 $KEY_FILE | awk '{print $2}'`
	if [[ -z $PRIV_KEY ]] ; then
		echo "$0: Missing key for <$node> in <$KEY_FILE>"
		exit 1
	fi
     
	curl https://raw.githubusercontent.com/rchain/rchain-testnet-node/dev/node-files.mainnet-val/rnode-v2.conf -o $node.rnode-v2.conf
	sed -i "s/PRIV_KEY/$PRIV_KEY/" $node.rnode-v2.conf
	sed -i "s+NODE_HOST+$node+" $node.rnode-v2.conf
fi

sed -i 's+protocol-client.bootstrap.*$+protocol-client.bootstrap = "$BOOTSTRAP"+' $node.rnode-v2.conf

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
