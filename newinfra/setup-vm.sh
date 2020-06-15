#!/bin/bash

# IBM root disk size is max 100G, so link rnode folders to the 2nd larger drive
mkfs.ext4 -m 0 -E lazy_itable_init=0,lazy_journal_init=0,discard /dev/xvdc
mkdir -p /rchain
mount -o discard,defaults /dev/xvdc /rchain
echo "UUID=`blkid|grep \"^/dev/xvdc\"|cut -d'\"' -f2` /rchain ext4 discard,defaults,nofail 0 2" >>/etc/fstab
mkdir -p /rchain/rnode 
ln -s /rchain/rnode /var/lib/rnode
mkdir -p /rchain/rnode-static 
ln -s /rchain/rnode-static /var/lib/rnode-static
mkdir -p /rchain/rnode-diag
ln -s /rchain/rnode-diag /var/lib/rnode-diag

# reset FQDN hostname to just its host's name.  Few rnode setup scripts expects this and makes it compatible with GCP
_hostname="$(hostname)"
hostnamectl set-hostname "${_hostname%%.*}"

# Create support & dev team accounts
curl https://raw.githubusercontent.com/rchain/rchain-testnet-node/dev/newinfra/setup-users.sh|bash
