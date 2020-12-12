#!/bin/bash
# 
#  Script checks if rnode memory exceeds MEM_THRESHOLD %, and if it does, forces jvm to run full garabage collection
#
set -e

# Redirect all outout to syslog and stderr
exec 1> >(logger -s -t $(basename $0)) 2>&1

ALERT_URL="https://discord.com/api/webhooks/745631958700261386/lQMlhZw5Q80JrnNLbfpwi-AtDacTEf3-81mcv9rOBOvyRp0TiCmW3uMhHyaPGhq8PUjI"
MEM_THRESHOLD=75.0
MEM_USED=$(docker stats --no-stream --format "{{.MemPerc}}" rnode|sed -e 's/%//')
MEM_LIMIT=$(echo "$MEM_USED > $MEM_THRESHOLD"|bc -l)

echo "rnode used $MEM_USED% memory.  Threshold set at $MEM_THRESHOLD."
if [[ $MEM_LIMIT -eq 1 ]]; then
        PID=$(jcmd | grep -v jcmd | awk '{print $1}')
        echo "rnode % memory $MEM_USED > $MEM_THRESHOLD.  Running 'jcmd $PID GC.run'"
        jcmd $PID GC.run
        NEW_MEM_USED=$(docker stats --no-stream --format "{{.MemPerc}}" rnode|sed -e 's/%//')

        # Check if any memory actually got released
        MEM_LIMIT=$(echo "$NEW_MEM_USED >= $MEM_USED"|bc -l)
        if [[ $MEM_LIMIT -eq 1 ]]; then
                msg="{\"content\": \"$(hostname -f) : $(basename $0) : GC.run didn't release rnode memory $NEW_MEM_USED%\"}"
                /usr/bin/curl --silent -H "Content-Type: application/json" -d "$msg" "$ALERT_URL"
        fi
        echo "Memory now $NEW_MEM_USED%"
fi

