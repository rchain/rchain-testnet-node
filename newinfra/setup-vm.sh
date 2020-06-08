#!/bin/bash
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
