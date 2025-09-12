# PostgreSQL → RisingWave → ClickHouse CDC Pipeline (Safe Copyable Version)

This README explains how to set up a CDC pipeline using:

- PostgreSQL as the source DB
- Debezium for CDC streaming
- Redpanda as the Kafka broker
- RisingWave for stream processing
- ClickHouse for analytics

---

## 1. Connect to RisingWave

Run this to open a SQL client:

```bash
docker run --rm -it --network clickhouse_demo_default \
  postgres:16 psql -h risingwave -p 4566 -U root -d dev
```

---

## 2. Create Source Table in RisingWave

Make sure to include the key for Debezium support:

```sql
CREATE TABLE IF NOT EXISTS test_table_source (
  id INT PRIMARY KEY,
  name TEXT
)
WITH (
  connector = 'kafka',
  topic = 'dbserver1.public.test_table',
  properties.bootstrap.server = 'redpanda:29092',
  scan.startup.mode = 'earliest'
)
FORMAT DEBEZIUM ENCODE JSON;
```

---

## 3. Create Materialized View in RisingWave

Transforms the data to uppercase:

```sql
CREATE MATERIALIZED VIEW uppercase_names AS
SELECT
  id,
  UPPER(name) AS name_upper
FROM test_table_source;
```

---

## 4. Prepare ClickHouse Table

Enter ClickHouse client:

```bash
docker exec -it clickhouse clickhouse-client
```

Then create the table:

```sql
CREATE TABLE uppercase_names (
  id Int32,
  name_upper String,
  is_deleted UInt8 DEFAULT 0
)
ENGINE = ReplacingMergeTree
ORDER BY id;
```

---

## 5. Create Sink in RisingWave (to ClickHouse)

```sql
CREATE SINK clickhouse_uppercase_sink
FROM uppercase_names
WITH (
  connector = 'clickhouse',
  type = 'upsert',
  "clickhouse.url" = 'http://clickhouse:8123',
  "clickhouse.database" = 'default',
  "clickhouse.table" = 'uppercase_names',
  "clickhouse.user" = 'default',
  "clickhouse.password" = 'admin',
  "primary_key" = 'id',
  "clickhouse.delete.column" = 'is_deleted'
);
```

---

## 6. Test

Make changes to your PostgreSQL table. RisingWave will process the changes and propagate them to ClickHouse in real-time.

Use:

```sql
SELECT * FROM uppercase_names;
```

In ClickHouse to confirm data ingestion.

---

## Notes

- Make sure Debezium connector in Redpanda is active and correctly configured.
- Restart RisingWave if schema changes don't propagate as expected.
- Use `ReplacingMergeTree` with `version` column if you want more robust deduplication.

