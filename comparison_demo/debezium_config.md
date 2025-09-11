## **1️⃣ Connector name**

```json
"name": "attendance-postgres-connector"
```

* This is the **unique name of your connector in Kafka Connect**.
* You can change it to anything descriptive.
* Important: each connector name creates its **own replication slot** in Postgres.

---

## **2️⃣ Connector class**

```json
"connector.class": "io.debezium.connector.postgresql.PostgresConnector"
```

* Specifies which connector type to use.
* For PostgreSQL, always use this.

---

## **3️⃣ Database connection info**

```json
"database.hostname": "postgres",
"database.port": "5432",
"database.user": "admin",
"database.password": "your_password",
"database.dbname": "your_db"
```

* Replace `postgres` with the **Docker service name** if needed.
* Use the **Postgres user with REPLICATION privileges**.
* `database.dbname` = the name of the DB you want CDC for.

---

## **4️⃣ Logical replication & server identity**

```json
"database.server.name": "pg_server",
"plugin.name": "pgoutput",
"slot.name": "attendance_slot",
"publication.name": "demo_pub"
```

* `database.server.name` → prefix for **Kafka topics**.

  * Example: table `attendances` → topic `pg_server.public.attendances`.
  * You can change this if you want a shorter or more descriptive prefix.

* `plugin.name` → logical decoding plugin. For Postgres 10+, `pgoutput` is standard.

* `slot.name` → replication slot in Postgres.

  * Debezium uses this to track which WAL positions have been read.
  * If you change this, Debezium will **create a new slot**.

* `publication.name` → the Postgres publication to read from.

  * Must include all tables you want CDC for.

---

## **5️⃣ Key/value converters**

```json
"key.converter": "org.apache.kafka.connect.json.JsonConverter",
"value.converter": "org.apache.kafka.connect.json.JsonConverter",
"key.converter.schemas.enable": "false",
"value.converter.schemas.enable": "false"
```

* Converts Debezium events into **Kafka messages**.
* Using JSON is simplest for a demo.
* You can also use Avro (`io.confluent.connect.avro.AvroConverter`) if you want **schema support**.
* `schemas.enable` → if `true`, Debezium includes a schema in the message; if `false`, only raw JSON.

---

## **6️⃣ Heartbeat**

```json
"heartbeat.interval.ms": "10000"
```

* Sends empty events periodically to keep the **replication slot alive**.
* Useful if your table has low activity.
* Can adjust interval based on your load.

---

## **7️⃣ Schema history**

```json
"schema.history.internal.kafka.bootstrap.servers": "redpanda:9092",
"schema.history.internal.kafka.topic": "schema-changes.demo"
```

* Debezium tracks **schema changes** (DDL: ALTER TABLE, ADD COLUMN, etc.) in this topic.
* Ensures the connector **can respond to schema evolution**.
* You can change the topic name or broker if needed.

✅ Important: Make sure **this topic exists or can be auto-created**.

* Debezium uses it to **merge schema changes with events** so your downstream (RisingWave / ClickHouse) can handle new columns.

---

## **8️⃣ CRUD handling**

* Debezium automatically converts **INSERT / UPDATE / DELETE** into Kafka messages.
* Example:

```json
{
  "before": {...},  // previous row state (for update/delete)
  "after": {...},   // new row state (for insert/update)
  "op": "c" | "u" | "d"  // create, update, delete
}
```

* Downstream can apply these **incrementally**.
* No additional config is needed; just make sure **your downstream can interpret the `op` field**.

---

## **9️⃣ Optional tweaks you may want**

| Config                    | Purpose / Notes                                                                                                                   |
| ------------------------- | --------------------------------------------------------------------------------------------------------------------------------- |
| `table.include.list`      | Only include specific tables instead of all in publication. Useful if you don’t want all tables in `demo_pub`.                    |
| `max.batch.size`          | Number of records per Kafka batch. Can tune for throughput.                                                                       |
| `snapshot.mode`           | Controls initial snapshot: `initial` (full table snapshot), `schema_only`, `never`. Recommended `initial` for your existing data. |
| `heartbeat.topics.prefix` | Custom topic prefix for heartbeat events.                                                                                         |
| `decimal.handling.mode`   | How to serialize Postgres numeric/decimal types.                                                                                  |
| `tombstones.on.delete`    | Whether to emit a “tombstone” message for deletes. Useful for downstream compaction.                                              |

---

### ✅ **Key recommendations for your demo**

1. **Initial snapshot**: If your tables already have data, set `snapshot.mode = initial` (default) so Debezium captures existing rows.
2. **Schema evolution**: The `schema.history.internal.kafka.topic` ensures **new columns are propagated** to downstream.
3. **CRUD**: Debezium handles all automatically. RisingWave or ClickHouse just needs to **apply updates/inserts/deletes**.
4. **Topic names**: Keep `database.server.name` meaningful; it helps distinguish multiple Postgres sources.

---
