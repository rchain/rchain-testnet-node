#!/bin/bash
#
#  Script checks if rnode memory exceeds MEM_THRESHOLD %, and if it does, forces jvm to run full garabage collection
#
set -e

# Redirect all outout to syslog and stderr
exec 1> >(logger -s -t $(basename $0)) 2>&1

MEM_THRESHOLD=75.0
MEM_USED=$(docker stats --no-stream --format "{{.MemPerc}}" rnode|sed -e 's/%//')
MEM_LIMIT=$(echo "$MEM_USED > $MEM_THRESHOLD"|bc -l)

echo "rnode used $MEM_USED% memory.  Threshold set at $MEM_THRESHOLD."
if [[ $MEM_LIMIT -eq 1 ]]
then
        PID=$(jcmd | grep -v jcmd | awk '{print $1}')
        echo "rnode % memory $MEM_USED > $MEM_THRESHOLD.  Running 'jcmd $PID GC.run'"
        jcmd $PID GC.run
        MEM_USED=$(docker stats --no-stream --format "{{.MemPerc}}" rnode|sed -e 's/%//')
        echo "rnode memory now=$MEM_USED%"
fi

