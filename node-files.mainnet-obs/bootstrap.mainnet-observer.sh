#!/bin/bash
#
apt update
apt -y upgrade 
apt -y install docker.io docker-compose collectd certbot 

curl -o /etc/collectd/collectd.conf  https://raw.githubusercontent.com/rchain/rchain-testnet-node/dev/collectd.conf
curl -o /var/lib/rnode-static/logback.xml https://raw.githubusercontent.com/rchain/rchain-testnet-node/dev/logback.xml
curl -o /var/lib/rnode/docker-compose.yml https://raw.githubusercontent.com/rchain/rchain-testnet-node/dev/node-files.mainnet-obs/docker-compose.yml

(cd /var/lib/rnode; docker-compose up -d rnode)
curl https://raw.githubusercontent.com/rchain/rchain-testnet-node/dev/rundeck-scripts/provision_nginx_proxy.sh | bash
