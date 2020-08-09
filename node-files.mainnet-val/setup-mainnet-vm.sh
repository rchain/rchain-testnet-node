#!/bin/bash
set -e

# IBM root disk size is max 100G, so link rnode folders to the 2nd larger drive
mkfs.ext4 -m 0 -E lazy_itable_init=0,lazy_journal_init=0 /dev/vdd
mkdir -p /rchain 
mount -o defaults /dev/vdd /rchain
echo "UUID=`blkid|grep \"^/dev/vdd\"|cut -d'\"' -f2` /rchain ext4 defaults,nofail 0 2" >>/etc/fstab
mkdir -p /rchain/rnode
mkdir -p /rchain/rnode-static
mkdir -p /rchain/rnode-diag
ln -s /rchain/rnode /var/lib/rnode
ln -s /rchain/rnode-static /var/lib/rnode-static
ln -s /rchain/rnode-diag /var/lib/rnode-diag

# Add domain name
sed -i "s/$/.root-shard.mainnet.rchain.coop/" /etc/hostname

# Setup garabage collection cron job
mkdir -p /opt/rchain/scripts
curl -o /opt/rchain/scripts/chk-rnode-memory.sh https://raw.githubusercontent.com/rchain/rchain-testnet-node/dev/scripts/chk-rnode-memory.sh
ln -sf  /opt/rchain/scripts/chk-rnode-memory.sh /etc/cron.hourly/chk-rnode-memory

curl -o /etc/collectd/collectd.conf  https://raw.githubusercontent.com/rchain/rchain-testnet-node/dev/collectd.conf
curl -o /var/lib/rnode-static/logback.xml https://raw.githubusercontent.com/rchain/rchain-testnet-node/dev/logback.xml

echo "$0:Script done!"

