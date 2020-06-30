#!/bin/bash
#
# Upgrade to release 0.9.25, with new configuration file and docker-compose
#
# 1) Installs kamon.conf on validator node
# 2) Install docker-compose on validator node
# 3) Run restart-v2.sh, which modifies and installs docker-compose.yml & rnode-v2.conf, and runs rnode on validator node
# 4) Install new nginx proxy configuration
#
node=$1

ssh root@$node.root-shard.mainnet.rchain.coop \
  "curl -sSfL https://raw.githubusercontent.com/rchain/rchain-testnet-node/dev/node-files.mainnet-val/kamon.conf -o /var/lib/rnode/kamon.conf"

ssh root@$node.root-shard.mainnet.rchain.coop \
  'curl -sSfL https://github.com/docker/compose/releases/download/1.26.0/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose \
&& chmod +x /usr/local/bin/docker-compose'

./restart-v2.sh $node

ssh root@$node.root-shard.mainnet.rchain.coop \
 "(export RD_OPTION_CONFIG_V2=yes \
&& curl https://raw.githubusercontent.com/rchain/rchain-testnet-node/dev/rundeck-scripts/provision_nginx_proxy.sh|bash)"

