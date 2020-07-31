#!/bin/bash
#
#  Install chk-rnode-memory.sh ias cron to force jvm garbage collection
#
set -e

apt -y install openjdk-11-jdk-headless bc

mkdir -p /opt/rchain/scripts
curl -o /opt/rchain/scripts/chk-rnode-memory.sh https://raw.githubusercontent.com/rchain/rchain-testnet-node/dev/scripts/chk-rnode-memory.sh
chmod +x /opt/rchain/scripts/chk-rnode-memory.sh

ln -sf /opt/rchain/scripts/chk-rnode-memory.sh /etc/cron.hourly/chk-rnode-memory
