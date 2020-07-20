#!/bin/bash
MEM_THRESHOLD=85.0
MEM_USED=$(docker stats --no-stream --format "{{.MemPerc}}" rnode|sed -e 's/%//')
MEM_LIMIT=$(echo "$MEM_USED > $MEM_THRESHOLD"|bc -l)
if [[ $MEM_LIMIT -eq 1 ]]
then
        PID=$(jcmd | grep -v jcmd | awk '{print $1}')
        echo "rnode % memory $MEM_USED > $MEM_THRESHOLD.  Running 'jcmd $PID GC.run'"
        jcmd $PID GC.run
        MEM_USED=$(docker stats --no-stream --format "{{.MemPerc}}" rnode|sed -e 's/%//')
        echo "rnode % memory now=$MEM_USED"
fi

