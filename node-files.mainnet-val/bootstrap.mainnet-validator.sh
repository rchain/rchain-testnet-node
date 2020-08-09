#!/bin/bash

set -e

# Mount IBM Cloud bucket
#curl -o /tmp/s3fs_1.86+git-v1.86-2_amd64.deb https://media.githubusercontent.com/media/maresb/docker-build-s3fs/master/builds/s3fs_1.86+git-v1.86-2_amd64.deb
#dpkg -i /tmp/s3fs_1.86+git-v1.86-2_amd64.deb
#mkdir -p /mnt/rchain-heapdumps
#s3fs rchain-heapdumps /mnt/rchain-heapdumps -o url="https://s3.private.eu.cloud-object-storage.appdomain.cloud",passwd_file=/root/rchain-bucket.key,use_cache=/rchain,parallel_count=5,multipart_size=1000

mkdir -p /opt/rchain/scripts
curl -o /opt/rchain/scripts/chk-rnode-memory.sh https://raw.githubusercontent.com/rchain/rchain-testnet-node/dev/scripts/chk-rnode-memory.sh
ln -sf  /opt/rchain/scripts/chk-rnode-memory.sh /etc/cron.hourly/chk-rnode-memory

curl -o /etc/collectd/collectd.conf  https://raw.githubusercontent.com/rchain/rchain-testnet-node/dev/collectd.conf
curl -o /var/lib/rnode-static/logback.xml https://raw.githubusercontent.com/rchain/rchain-testnet-node/dev/logback.xml
curl -o /var/lib/rnode/docker-compose.yml https://raw.githubusercontent.com/rchain/rchain-testnet-node/dev/node-files.mainnet-obs/docker-compose.yml
sed -i "s/\${HOST_NAME}/$(hostname -f)/" /var/lib/rnode/docker-compose.yml

#(cd /var/lib/rnode; docker-compose up -d rnode)
curl https://raw.githubusercontent.com/rchain/rchain-testnet-node/dev/rundeck-scripts/provision_nginx_proxy.sh | bash
