# 🌀 Change Data Capture (CDC) with PostgreSQL, Debezium, and Redpanda

This project demonstrates a minimal setup to capture database changes (CDC) from PostgreSQL using **Debezium**, and stream those changes to **Redpanda**, a Kafka-compatible event streaming platform.

> ✅ This guide is meant as both a learning report and a practical reference for future implementation.

---

## 📊 Architecture Overview

```
+-------------+      WAL Stream      +-------------------+       Kafka Protocol       +-------------+
|             | -------------------> |                   | -----------------------> |             |
|  PostgreSQL |                      | Kafka Connect w/  |                         |  Redpanda   |
| (wal_level= | <------------------- |    Debezium       | <----------------------- | (Kafka API) |
|   logical)  |    Acknowledgements  |                   |       Topic Events       |             |
+-------------+                      +-------------------+                         +-------------+
                                                 |
                                                 | REST API (Port 8083)
                                                 v
                                          Register Connector JSON
```

---

## 📚 Concepts

### ✅ PostgreSQL WAL (Write-Ahead Logging)
- PostgreSQL logs every change in its **WAL** to ensure durability and recovery.
- **Logical replication** reads WAL changes and outputs row-level insert/update/delete.
- `pg_waldump` allows inspecting WAL segment files manually.

**Terms:**
- **WAL Segment:** 16MB binary files in `pg_wal/` directory.
- **LSN (Log Sequence Number):** A pointer to a location in the WAL stream.

### ✅ Debezium
- A CDC tool that reads changes from the database’s WAL and publishes them to Kafka topics.
- It runs as a plugin inside **Kafka Connect**.

### ✅ Kafka Connect
- A framework for connecting Kafka with external systems (like databases).
- Debezium runs inside Kafka Connect as a plugin.

### ✅ Redpanda
- A Kafka-compatible streaming platform — no Zookeeper, single binary, lightweight.
- Works out-of-the-box with Kafka tooling (e.g., Kafka Connect, rpk).

---

## 💻 System Requirements

- Docker + Docker Compose
- cURL
- PostgreSQL client (e.g. `psql`)
- Optional: pg_waldump (comes with `postgres` package)

---

## 🚀 Getting Started

### 1. Start the Stack

```bash
docker compose up -d
```

This spins up:
- PostgreSQL (v16.2-alpine)
- Redpanda (v25.1.9)
- Kafka Connect with Debezium (2.7.3.Final)

---

### 2. Configure PostgreSQL for CDC

Connect to the container:

```bash
docker exec -it postgres psql -U postgres
```

Inside `psql`, set WAL settings using SQL:

```sql
ALTER SYSTEM SET wal_level = 'logical';
ALTER SYSTEM SET max_replication_slots = 4;
ALTER SYSTEM SET max_wal_senders = 4;
```

Then restart the container:

```bash
docker restart postgres
```

✅ Check settings:

```sql
SHOW wal_level;
SHOW max_replication_slots;
SHOW max_wal_senders;
```

---

### 3. Inspect WAL with `pg_waldump` (Optional)

Get current WAL position:

```bash
docker exec -it postgres psql -U postgres -c "SELECT pg_current_wal_lsn(), pg_walfile_name(pg_current_wal_lsn());"
```

Inspect WAL logs:

```bash
docker exec -it postgres pg_waldump -p /var/lib/postgresql/data/pg_wal -s <START_LSN>
```

Filter for changes:

```bash
... | grep -E 'Heap|Btree|XLOG'
```

Find your table’s OID:

```sql
SELECT oid, relname FROM pg_class WHERE relname = 'your_table_name';
```

---

### 4. Create a Replication Slot

```bash
docker exec -it postgres psql -U postgres -c "SELECT * FROM pg_create_logical_replication_slot('debezium', 'pgoutput');"
```

If needed, grant replication:

```bash
docker exec -it postgres psql -U postgres -c "ALTER USER postgres WITH REPLICATION;"
```

---

## 🔗 Connect Debezium to PostgreSQL

### Connector Config (JSON)

Save this as `register-postgres-connector.json`:

```json
{
  "name": "postgres-connector",
  "config": {
    "connector.class": "io.debezium.connector.postgresql.PostgresConnector",
    "plugin.name": "pgoutput",
    "database.hostname": "postgres",
    "database.port": "5432",
    "database.user": "postgres",
    "database.password": "postgres",
    "database.dbname": "postgres",
    "database.server.name": "dbserver1",
    "topic.prefix": "dbserver1",
    "slot.name": "debezium",
    "publication.autocreate.mode": "all_tables",
    "tombstones.on.delete": "false",
    "include.schema.changes": "false",
    "key.converter": "org.apache.kafka.connect.json.JsonConverter",
    "value.converter": "org.apache.kafka.connect.json.JsonConverter"
  }
}
```

### Register the Connector

```bash
curl -X POST -H "Content-Type: application/json" \
  localhost:8083/connectors \
  -d @register-postgres-connector.json
```

### Update Config (if needed)

Save as `update-config.json` and send via:

```bash
curl -X PUT -H "Content-Type: application/json" \
  http://localhost:8083/connectors/postgres-connector/config \
  -d @update-config.json
```

Check status or restart:

```bash
curl http://localhost:8083/connectors/postgres-connector/status
curl -X POST http://localhost:8083/connectors/postgres-connector/restart
```

---

## 🧪 Testing the Pipeline

### 1. Insert Data into PostgreSQL

```bash
docker exec -it postgres psql -U postgres -c "INSERT INTO test_table (id, name) VALUES (1, 'baz');"
```

### 2. Consume Topic from Redpanda

```bash
docker exec -it redpanda rpk topic list
docker exec -it redpanda rpk topic consume dbserver1.public.test_table -o end -f json --pretty-print
```

📥 Example Event:
```json
{
  "before": null,
  "after": {
    "id": 1,
    "name": "baz"
  },
  "source": {
    "connector": "postgresql",
    "db": "postgres",
    "schema": "public",
    "table": "test_table"
  },
  "op": "c",
  "ts_ms": 1753954218243
}
```

---

## 🛠 Troubleshooting

| Symptom | Cause | Fix |
|--------|-------|-----|
| `connectors/pg-src/config` returns 500 | Missing topic config | Ensure `CONFIG_STORAGE_TOPIC`, etc. exist |
| No topics appear | Redpanda doesn’t auto-create topics | Enable: `rpk cluster config set auto_create_topics_enabled true` |
| WAL changes don’t appear | Incorrect `wal_level` or no logical slot | Check `wal_level`, restart container, re-create slot |
| JSON config upload fails | Invalid structure or bad curl path | Validate JSON with a linter and try `POST` or `PUT` |

---

## 🔍 References

- [Debezium Docs](https://debezium.io/documentation/reference/stable/)
- [Redpanda Docs](https://docs.redpanda.com)
- [Kafka Connect Overview](https://kafka.apache.org/documentation/#connect)
- [PostgreSQL WAL](https://www.postgresql.org/docs/current/wal-intro.html)
- [pg_waldump](https://www.postgresql.org/docs/current/pgwaldump.html)

---

## ✅ Summary

This setup captures real-time changes from PostgreSQL and streams them to Redpanda topics using Debezium and Kafka Connect. You can inspect WAL files manually, customize your connector config, and observe the events in real-time via Redpanda’s Kafka API.

---

Happy streaming! 🌊
