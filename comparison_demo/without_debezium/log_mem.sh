#!/bin/bash

echo "time,risingwave,clickhouse,malut_clone" > mem_log.csv

while true; do
    timestamp=$(date +"%H:%M:%S")
    
    # Get all memory usage in one command
    mems=$(docker stats --no-stream --format "{{.Name}} {{.MemUsage}}" risingwave clickhouse malut_clone)

    # Function to extract and convert memory to integer MiB
    get_mem_int() {
        raw=$(echo "$mems" | grep $1)
        num=$(echo $raw | awk '{print $2}' | sed 's/[^0-9.]//g')
        unit=$(echo $raw | awk '{print $2}' | sed 's/[0-9.]//g')
        if [[ "$unit" == "GiB" ]]; then
            echo $(awk "BEGIN{printf \"%d\", $num*1024}")
        else
            echo $(awk "BEGIN{printf \"%d\", $num}")
        fi
    }

    rising=$(get_mem_int risingwave)
    click=$(get_mem_int clickhouse)
    malut=$(get_mem_int malut_clone)

    echo "$timestamp,$rising,$click,$malut" >> mem_log.csv
    sleep 1
done
