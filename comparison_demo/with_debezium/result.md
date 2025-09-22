# Comparison 

## With Debezium

<!-- after compose up -->
18:28
docker stats --no-stream
CONTAINER ID   NAME            CPU %     MEM USAGE / LIMIT     MEM %     NET I/O           BLOCK I/O   PIDS
1208a662d55e   kafka-connect   4.60%     503.8MiB / 15.49GiB   3.18%     85.3kB / 70.8kB   0B / 0B     53
21da0709ff28   risingwave      3.84%     175MiB / 15.49GiB     1.10%     34.7kB / 11.7kB   0B / 0B     82
2b608cd2779e   clickhouse      12.58%    479.1MiB / 15.49GiB   3.02%     6.88kB / 4.69kB   0B / 0B     686
99769f09fa39   redpanda        1.41%     288.9MiB / 15.49GiB   1.82%     72.8kB / 83.5kB   0B / 0B     3
4b153121f820   malut_clone     0.01%     162MiB / 15.49GiB     1.02%     14.3MB / 647MB    0B / 0B     10

<!-- after sending debeziumconfig -->
18:29:30


<!-- after init the risingwave -->
18:31:00

<!-- after dumping 1k data -->
18:38:30
1066031->2066031

result:
- rising wave nambah terus memory 0.4gb -> 7gb
- kafka : 300mb =>2100mb
- redpanda: 270mb =>700mb