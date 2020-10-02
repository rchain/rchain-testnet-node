#!/bin/bash

# This script monitors a list of mainnet validator and observers to ensure each is getting the latest block.
# Script queries 'validators' API which returns a list of validators available in the network and compares last
# blocks creation time with the current time.  If the block is older then $TIME_THRESHOLD, then concatenates the node name.
# At the end of the script, if there are any nodes whose block time is stale, the script sends a message to the developer
# Discord 'alert' channel

ALERT_URL="https://discordapp.com/api/webhooks/706532851574767666/fLIRySL7IvskyI4-GFYibs9rZPp4zzoCCgM_2II1fvmlvnkxrwVSuE4CYkW42hF-756Y"
PAUSE_SCRIPT_FILE="/opt/rchain/scripts/PAUSE_SCRIPT_monitor_mainnet"
SCRIPT_NAME=$(basename $0)
CURL_TIMEOUT=5
TIME_THRESHOLD=300
	   #observer-eu.services.mainnet.rchain.coop     \
OBSERVERS="observer-asia.services.mainnet.rchain.coop   \
	   observer-us.services.mainnet.rchain.coop     \
	   observer-exch2.services.mainnet.rchain.coop"

# Redirect all outout to syslog and stderr
exec 1> >(logger -s -t ${SCRIPT_NAME}) 2>&1

# if the pause file exists then sleep till it is removed
if [ -f $PAUSE_SCRIPT_FILE ]; then
	$echo "Pausing $SCRIPT_NAME script till $PAUSE_SCRIPT_FILE is removed..."
	exit
fi

echo "Checking..."
now_in_secs=$(date +%s)
alert_msg=""
validators=$(curl -m $CURL_TIMEOUT -sSfL https://status.rchain.coop/api/validators)
rc=$?
if [[ -z $validators || $rc -ne 0 ]]; then
	alert_msg="No validator information available. Curl error $rc\n$alert_msg"
else
	# Traverse through list of validators
	while read i; do
		host=$(echo $i|jq -r .host)
		block_num=$(echo $i|jq .latestBlockNumber)
		block_time=$(expr $(echo $i|jq .timestamp) / 1000)
		time_diff=$(expr $now_in_secs - $block_time)
	
		if [[ $time_diff -gt $TIME_THRESHOLD ]]; then
			alert_msg="Host ${host%%.*} blk# ${block_num} rcvd $(date -d @${block_time})\n$alert_msg"
		fi
	done < <(echo $validators|jq -c '.validators[]')
fi

# Now check list of observers
for host in $OBSERVERS; do
	observer=$(curl -m $CURL_TIMEOUT -sSfL https://$host/api/blocks/1)
	rc=$?
	if [[ -z $observer || $rc -ne 0 ]]; then
		alert_msg="Host ${host%%.*} NOT available. Curl error $rc\n$alert_msg"
	else
		block_time=$(expr $(echo $observer|jq '.[0].timestamp') / 1000)
		block_num=$(echo $observer|jq '.[0].blockNumber')
		time_diff=$(expr $now_in_secs - $block_time)

		if [[ $time_diff -gt $TIME_THRESHOLD ]]; then
			alert_msg="Host ${host%%.*} blk# ${block_num} rcvd $(date -d @${block_time})\n$alert_msg"
		fi
	fi
done

if [[ $alert_msg ]]; then
	echo "Sending alert <$alert_msg>"
	alert_msg="{\"content\": \"$(hostname -f):${SCRIPT_NAME}: *** Last block older than $TIME_THRESHOLD seconds. ***\n${alert_msg}\n\"}"
	curl --silent -H "Content-Type: application/json" -d "$alert_msg" "$ALERT_URL"
fi
