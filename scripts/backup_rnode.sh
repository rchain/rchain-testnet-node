#!/bin/bash

#set -e

if [ $# -ne 2 ]; then
	echo "usage: $(basename $0) <rnode-container-name> <rnode-dir>"
	echo "Example: $(basename $0) mainnet-observer-dev /rchain/mainnet/observer-dev"
	exit
fi

ALERT_URL="https://discord.com/api/webhooks/745631958700261386/lQMlhZw5Q80JrnNLbfpwi-AtDacTEf3-81mcv9rOBOvyRp0TiCmW3uMhHyaPGhq8PUjI"
PATH="$PATH:/usr/local/bin"
DT=$(date -u +%g%m%d-%H%M)

RNODE_NETWORK="$1"
RNODE_NAME="$2"

RNODE_CONTAINER_NAME="${RNODE_NETWORK}-${RNODE_NAME}"
RNODE_DIR="/rchain/${RNODE_NETWORK}/${RNODE_NAME}"
TARFILE="$RNODE_CONTAINER_NAME-$DT.tar.gz"
LOCKFILE="$RNODE_DIR/backing-up-$RNODE_NAME.LOCK"
BACKUP_DIR="/mnt/heapdumps/$RNODE_NETWORK"
S3FS_DIR="/rchain/rchain-heapdumps"

# Catch script errors and send discord alert
trap 'catch_errors $? $LINENO' EXIT
catch_errors() {
        if [ "$1" != "0" ]; then
		msg="{\"content\": \"$(hostname -f):$(basename $0): Backup failed with error <$1> on line $2.\"}"
                ###/usr/bin/curl --silent -H "Content-Type: application/json" -d "$msg" "$ALERT_URL"
                echo "/usr/bin/curl --silent -H 'Content-Type: application/json' -d $msg $ALERT_URL"
        fi
}

# Redirect all outout to syslog and stderr
exec 1> >(logger -s -t $(basename $0)) 2>&1

# Do some error checking
if [[ -z "$(docker ps -q -f name=${RNODE_CONTAINER_NAME})" ]]; then
	echo "Error: Docker container $RNODE_CONTAINER_NAME doesn't exist.  Exiting..."
	exit
fi

if [[ ! -d $RNODE_DIR ]]; then
	echo "Error: Directory $RNODE_DIR does not exist.  Exiting..."
	exit
fi

echo "Starting $RNODE_NETWORK-$RNODE_NAME backup"

# Check if this script is already running?
if [[ -f "$LOCKFILE" ]]; then
        catch_errors "Previous run $LOCKFILE still exists!  Please remove the file after investigation.  Exiting..."  "$LINENO"
	exit
else
        echo "Creating $LOCKFILE"
        touch $LOCKFILE
fi

echo "Stopping $RNODE_CONTAINER_NAME"
docker stop $RNODE_CONTAINER_NAME && docker rm $RNODE_CONTAINER_NAME

echo "Archiving $RNODE_NAME database into $TARFILE"
(cd $RNODE_DIR;tar -I "pigz --best --recursive" -cvf $TARFILE rnode/{blockstore,dagstorage,rspace,last-finalized-block,casperbuffer})

echo "Starting $RNODE_CONTAINER_NAME"
(cd $RNODE_DIR/..;docker-compose up -d $RNODE_CONTAINER_NAME)

FILESIZE=$(stat -c "%s" $RNODE_DIR/$TARFILE)
echo "Moving $TARFILE (Size=$FILESIZE) to heapdumps bucket"
mkdir -p $BACKUP_DIR
cp $RNODE_DIR/$TARFILE $BACKUP_DIR && rm $RNODE_DIR/$TARFILE && rm $S3FS_DIR/$RNODE_NETWORK/$TARFILE

echo "Cleaning up backup files older then 3 days"
find $BACKUP_DIR -name $RNODE_CONTAINER_NAME*.tar.gz -mtime +3 -print -exec rm {} \;

rm $LOCKFILE
echo "All Done!"

