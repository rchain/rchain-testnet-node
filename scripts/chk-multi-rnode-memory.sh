#!/bin/bash
#
#  Script checks if rnode memory exceeds MEM_THRESHOLD %, and if it does, forces jvm to run full garabage collection
#
set -e

# Redirect all outout to syslog and stderr
exec 1> >(logger -s -t $(basename $0)) 2>&1

MEM_THRESHOLD=75.0

# Get all nodes status
docker stats --no-stream | grep -v "^CONTAINER" | while read nodestats; do
	NODE_NAME=$(echo $nodestats | awk '{print $2}' )
	if [[ $NODE_NAME == *"revproxy"* ]]; then
		continue;
	fi
	MEM_USED=$(echo $nodestats | awk '{print $7}' | sed -e 's/%//')
	MEM_LIMIT=$(echo "$MEM_USED > $MEM_THRESHOLD"|bc -l)
	echo "Node <$NODE_NAME> used $MEM_USED% memory.  Threshold is set at $MEM_THRESHOLD."

	if [[ $MEM_LIMIT -eq 1 ]]
	then
		PID=$(docker inspect $NODE_NAME --format "{{.State.Pid}}")
        	echo "rnode % memory $MEM_USED > $MEM_THRESHOLD.  Running 'jcmd $PID GC.run'"
        	jcmd $PID GC.run
		MEM_USED=$(docker stats $NODE_NAME --no-stream --format "{{.MemPerc}}")
       	 	echo "rnode memory now=$MEM_USED"
	fi
done



#MEM_USED=$(docker stats --no-stream --format "{{.MemPerc}}" rnode|sed -e 's/%//')
#MEM_LIMIT=$(echo "$MEM_USED > $MEM_THRESHOLD"|bc -l)
#
#echo "rnode used $MEM_USED% memory.  Threshold set at $MEM_THRESHOLD."
#if [[ $MEM_LIMIT -eq 1 ]]
#then
#        PID=$(jcmd | grep -v jcmd | awk '{print $1}')
#        echo "rnode % memory $MEM_USED > $MEM_THRESHOLD.  Running 'jcmd $PID GC.run'"
#        jcmd $PID GC.run
#        MEM_USED=$(docker stats --no-stream --format "{{.MemPerc}}" rnode|sed -e 's/%//')
#        echo "rnode memory now=$MEM_USED%"
#fi
