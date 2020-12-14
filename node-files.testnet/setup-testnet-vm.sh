#!/bin/bash

set -e 

apt update
apt -y upgrade 
apt -y install docker.io docker-compose collectd certbot  s3fs bc openjdk-11-jdk-headless iotop netutils

mkfs.ext4 -m 0 -E lazy_itable_init=0,lazy_journal_init=0 /dev/vdb
mkdir -p /rchain 
mount -o defaults /dev/vdb /rchain
echo "UUID=`blkid|grep \"^/dev/vdb\"|cut -d'\"' -f2` /rchain ext4 defaults,nofail 0 2" >>/etc/fstab

mkdir -p /rchain/scripts 
mkdir -p /rchain/files
curl -o /etc/collectd/collectd.conf  https://raw.githubusercontent.com/rchain/rchain-testnet-node/dev/collectd.conf
curl -o /rchain/files/logback.xml    https://raw.githubusercontent.com/rchain/rchain-testnet-node/dev/logback.xml
curl -o /rchain/files/kamon.conf     https://raw.githubusercontent.com/rchain/rchain-testnet-node/dev/node-files.mainnet-val/kamon.conf 
curl -o /rchain/docker-compose.yml   https://raw.githubusercontent.com/rchain/rchain-testnet-node/dev/node-files.testnet/multi-docker-compose.yml
curl -o /rchain/scripts/chk-multi-rnode-memory.sh https://raw.githubusercontent.com/rchain/rchain-testnet-node/dev/scripts/chk-multi-rnode-memory.sh
chmod +x /rchain/scripts/chk-multi-rnode-memory.sh
echo "*/5 * * * * root /rchain/scripts/chk-multi-rnode-memory.sh >/dev/null 2>&1" > /rchain/scripts/chk-multi-rnode-memory-crontab
ln -sf /rchain/scripts/chk-multi-rnode-memory-crontab /etc/cron.d


# Create support & dev team accounts
curl https://raw.githubusercontent.com/rchain/rchain-testnet-node/dev/newinfra/setup-users.sh|bash

# Mount IBM Cloud bucket
mkdir -p /mnt/heapdumps
s3fs rchain-heapdumps /mnt/heapdumps -o url=https://s3.direct.eu.cloud-object-storage.appdomain.cloud,passwd_file=/rchain/files/rchain-bucket.key,use_cache=/rchain,parallel_count=10,multipart_size=1000
