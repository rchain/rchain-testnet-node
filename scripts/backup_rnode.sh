#!/bin/bash

set -e
trap 'catch_errors $? $LINENO' EXIT

ALERT_URL="https://discord.com/api/webhooks/745631958700261386/lQMlhZw5Q80JrnNLbfpwi-AtDacTEf3-81mcv9rOBOvyRp0TiCmW3uMhHyaPGhq8PUjI"
PATH="$PATH:/usr/local/bin"
DT=$(date -u +%g%m%d-%H%M)

TARDIR="/rchain"
TARFILE_PREFIX="rnode-backup"
TARFILE="$TARFILE_PREFIX-$DT.tar.gz"
LOCKFILE="$TARDIR/$TARFILE_PREFIX.LOCK"
BACKUP_DIR="/mnt/heapdumps/$(hostname -f)"

# Catch script errors and send discord alert
catch_errors() {
	if [ "$1" != "0" ]; then
		msg="{\"content\": \"$(hostname -f):$0: Backup failed with error <$1> on line $2.\"}"
		/usr/bin/curl --silent -H "Content-Type: application/json" -d "$msg" "$ALERT_URL"
	fi
}

# Redirect all outout to syslog and stderr
exec 1> >(logger -s -t $(basename $0)) 2>&1

echo "Starting rnode backup"

# Check if this script is already running?
if [[ -f "$LOCKFILE" ]]; then
        catch_errors "Previous run $LOCKFILE still exists!  Please remove the file after investigation.  Exiting..."  "$LINENO"
else
        echo "Creating $LOCKFILE"
        touch $LOCKFILE
fi

echo "Stopping rnode"
docker stop rnode && docker rm rnode

echo "Archiving rnode database into $TARFILE"
(cd $TARDIR;tar -I "pigz --best --recursive" -cvf $TARFILE rnode/{blockstore,dagstorage,rspace,last-finalized-block,casperbuffer})

echo "Starting rnode"
(cd /var/lib/rnode/;docker-compose up -d rnode)

FILESIZE=$(stat -c "%s" $TARDIR/$TARFILE)
echo "Moving $TARFILE (Size=$FILESIZE) to heapdumps bucket"
mkdir -p $BACKUP_DIR
cp $TARDIR/$TARFILE $BACKUP_DIR && rm $TARDIR/$TARFILE

echo "Cleaning up backup files older then 7 days"
find $BACKUP_DIR -name $TARFILE_PREFIX*.tar.gz -mtime +7 -exec rm {} \;

rm $LOCKFILE
echo "All Done!"

