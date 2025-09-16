# 500k rows insert
start 15:06, 16130(initial row count)
      15:08 -> insert 100.000 (became 116.130)
      15:11 -> insert 500.000 (became 616.130)

result:
- rising wave nambah terus memory 487mb -> 5085mb

# 1m rows insert
start 15:26, 616.130 (initial row count)
      15:27 -> run the clickhouse init sql (already use 4GB memory for risingwave)
      15:31 -> insert 1.000.000 (became 1616.130)

result:
- rising wave nambah terus memory 487mb -> 6024mb
