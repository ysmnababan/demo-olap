# Comparison 

## With Debezium

<!-- while idle -->
docker stats --no-stream
CONTAINER ID   NAME            CPU %     MEM USAGE / LIMIT     MEM %     NET I/O           BLOCK I/O   PIDS
abd507df1186   kafka-connect   1.03%     1.532GiB / 15.49GiB   9.89%     46.6MB / 178MB    0B / 0B     59
2968966fa34d   risingwave      7.70%     946.3MiB / 15.49GiB   5.97%     135MB / 9.52MB    0B / 0B     160
149fcdc96c93   clickhouse      5.62%     767.4MiB / 15.49GiB   4.84%     1.34MB / 1.03MB   0B / 0B     709
fb20c7a8edb9   redpanda        1.95%     459.3MiB / 15.49GiB   2.90%     186MB / 139MB     0B / 0B     3
4b153121f820   malut_clone     0.01%     91.05MiB / 15.49GiB   0.57%     7.17MB / 489MB    0B / 0B     11


docker stats --no-stream --format "table {{.Name}}\t{{.MemUsage}}"
NAME            MEM USAGE / LIMIT
kafka-connect   1.533GiB / 15.49GiB
risingwave      953.7MiB / 15.49GiB
clickhouse      782.5MiB / 15.49GiB
redpanda        459.3MiB / 15.49GiB
malut_clone     91.05MiB / 15.49GiB


concern
- rising wave nambah terus memory 1.2gb -> 5gb