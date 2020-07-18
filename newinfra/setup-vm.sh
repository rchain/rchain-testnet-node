#!/bin/bash

# IBM root disk size is max 100G, so link rnode folders to the 2nd larger drive
mkfs.ext4 -m 0 -E lazy_itable_init=0,lazy_journal_init=0 /dev/xvdc
mkdir -p /rchain 
mount -o defaults /dev/xvdc /rchain
echo "UUID=`blkid|grep \"^/dev/xvdc\"|cut -d'\"' -f2` /rchain ext4 defaults,nofail 0 2" >>/etc/fstab
mkdir -p /rchain/rnode
mkdir -p /rchain/rnode-static
mkdir -p /rchain/rnode-diag
ln -s /rchain/rnode /var/lib/rnode
ln -s /rchain/rnode-static /var/lib/rnode-static
ln -s /rchain/rnode-diag /var/lib/rnode-diag

# reset FQDN hostname to just its host's name.  Few rnode setup scripts expects this and makes it compatible with GCP
_hostname="$(hostname)"
hostnamectl set-hostname "${_hostname%%.*}"

# Create support & dev team accounts
curl https://raw.githubusercontent.com/rchain/rchain-testnet-node/dev/newinfra/setup-users.sh|bash

# Make sure we don't conflict with apt.systemd.daily while bringing the system up to date

mask_services='apt-daily apt-daily-upgrade'
stop_services='unattended-upgrades'

cleanup()
{
        systemctl unmask $mask_services
        systemctl isolate default
}
trap cleanup EXIT

systemctl mask $mask_services
systemctl stop $stop_services

echo -n "$0:Waiting for following services to finish: $mask_services... "
while systemctl is-active $mask_services >/dev/null 2>&1; do
        sleep 1
done
echo "Done!"

export DEBIAN_FRONTEND=noninteractive
apt update -q 
apt -y upgrade

echo "$0:Script done!"

