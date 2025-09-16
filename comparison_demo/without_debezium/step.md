# POSTGRES

## dump the source
pg_dump -U your_user -h your_host -Fc your_database > db.dump
pg_dump -U palm -h 206.189.144.36 -Fc malut > db.dump

## create the container
docker run -d \
  --name malut_clone \
  -e POSTGRES_USER=admin \
  -e POSTGRES_PASSWORD=admin \
  -e POSTGRES_DB=palm \
  -p 5432:5432 \
  postgres:16

## configure the wal
ALTER SYSTEM SET wal_level = 'logical';
ALTER SYSTEM SET max_replication_slots = 4;
ALTER SYSTEM SET max_wal_senders = 4;

## create the role
docker exec -it malut_clone psql -U admin -d palm
CREATE ROLE developer LOGIN;
CREATE ROLE postgres LOGIN;
CREATE ROLE palm LOGIN;

## copy and restore the db
docker cp ./db/db.dump malut_clone:/db.dump
docker exec -it malut_clone pg_restore -U admin -d palm /db.dump

## check user privileges
The replication user needs the following permissions:
REPLICATION privilege
CONNECT privilege on the target database
SELECT privilege on the tables to be replicated
Permission to create publications (if publication.create.enable is enabled)


# RISINGWAVE

You’ll use CREATE SOURCE to create a shared source, and then create multiple tables from it, each representing a table in the upstream PostgreSQL database.

```sql
-- Create a shared CDC source
CREATE SOURCE pg_source WITH (
    connector='postgres-cdc',
    hostname='localhost',
    port='5432',
    username='admin',
    password='admin',
    database.name='palm',
    schema.name='public' -- Optional, defaults to 'public'
)
FORMAT DEBEZIUM ENCODE JSON;

-- Create a table from the source, representing a specific PostgreSQL table
CREATE TABLE my_table (
    id INT PRIMARY KEY,
    name VARCHAR
)
WITH (
    snapshot='true' -- If false, disables the initial snapshot (backfill) of the table. Only new changes will be ingested.
)
FROM pg_source TABLE 'public.my_upstream_table';
```

Create the materialized view:
```sql
CREATE MATERIALIZED VIEW attendance_fact AS
SELECT 
    a.id AS attendance_id, 
    EXTRACT(EPOCH FROM a.check_in)::BIGINT AS check_in_epoch,
    EXTRACT(EPOCH FROM a.check_out)::BIGINT AS check_out_epoch,
    a.company_id,
    ss.id AS schedule_id,
    EXTRACT(EPOCH FROM ss.schedule_date)::BIGINT AS schedule_date_epoch,
    EXTRACT(EPOCH FROM ss.clock_in_time)::INT AS clock_in_time_sec,
    EXTRACT(EPOCH FROM ss.clock_out_time)::INT AS clock_out_time_sec,
    sr.id AS shift_rule_id,
    sr.name AS shift_rule_name,
    sr.location_address,
    sr.location_name,
    EXTRACT(EPOCH FROM sr.clock_in_time)::INT  AS sr_cit_sec,
    EXTRACT(EPOCH FROM sr.clock_out_time)::INT AS sr_cot_sec,
    u.id AS user_id,
    u.nip,
    u.fullname,
    muo.id AS unor_id,
    muo.unit_organisasi,
    muo.parent_id,
    mg.id AS grade_id,
    mg.name AS grade_name,
    mp.nama_jabatan,
    mpt.id AS position_type_id,
    mpt.jenis_jabatan
FROM attendances_source a
JOIN shift_schedule_source ss ON ss.id = a.shift_schedule_id
JOIN shift_rules_source sr ON sr.id = ss.shift_rule_id
JOIN users_source u ON a.user_id = u.id
JOIN master_unit_organization_source muo ON muo.id = u.unor_id
LEFT JOIN user_grade_source ug ON ug.user_id = u.id
LEFT JOIN master_grade_source mg ON mg.id = ug.grade_id
LEFT JOIN user_position_source up ON up.user_id = u.id
LEFT JOIN master_position_source mp ON mp.id = up.position_id
LEFT JOIN master_position_type_source mpt ON mpt.id = mp.position_type_id;
```

Create sink for clickhouse:
```sql
CREATE SINK sink_attendance_fact
FROM attendance_fact
WITH (
    connector = 'clickhouse',
    type = 'upsert',
    "clickhouse.url" = 'http://clickhouse:8123',
    "clickhouse.database" = 'default',
    "clickhouse.table" = 'attendance_fact',
    "clickhouse.user" = 'default',
    "clickhouse.password" = 'admin',
    "primary_key" = 'attendance_id',
    "clickhouse.delete.column" = 'is_deleted'
);
```

You can done all the above command by creating a init sql file to be run when starting a container or entering the container using the `psql -h 127.0.0.1 -p 4566 -U root -d dev` and run the command one by one.
```sh
psql -h 127.0.0.1 -p 4566 -U root -d dev -f ./init_risingwave.sql
```

# CLICKHOUSE

- ClickHouse is append-only by design. It doesn’t handle row-level deletes directly in real time. That’s why RisingWave’s sink connector needs a workaround:
- If you need delete capability in clickhouse, add new rows (i.e. `is_deleted`)
  into the clickhouse table. You dont have to add this for risingwave MV table.
  The deletion will be triggered if any of the related table for the MV is deleted.
  In this example, if `users` row is deleted, because it need to be joined with the
  `attendance` table, the entire row with the particular user is deleted in 
  clickhouse (or to be precise, marked as deleted)

Enter ClickHouse client:

```bash
docker exec -it clickhouse clickhouse-client
```

Then create the table:

```sql
-- In ClickHouse
CREATE TABLE IF NOT EXISTS attendance_fact (
    attendance_id       BIGINT,
    check_in_epoch      BIGINT,
    check_out_epoch     Nullable(BIGINT),
    company_id          BIGINT,
    schedule_id         BIGINT,
    schedule_date_epoch BIGINT,
    clock_in_time_sec   Nullable(Int32),
    clock_out_time_sec  Nullable(Int32),
    shift_rule_id       BIGINT,
    shift_rule_name     Nullable(String),
    location_address    Nullable(String),
    location_name       Nullable(String),
    sr_cit_sec          Nullable(Int32),
    sr_cot_sec          Nullable(Int32),
    user_id             BIGINT,
    nip                 Nullable(String),
    fullname            Nullable(String),
    unor_id             Nullable(Int32),
    unit_organisasi     Nullable(String),
    parent_id           Nullable(BIGINT),
    grade_id            Nullable(BIGINT),
    grade_name          Nullable(String),
    nama_jabatan        Nullable(String),
    position_type_id    Nullable(Int32),
    jenis_jabatan       Nullable(String),
	is_deleted          UInt8 -- auto filled by Risingwave when deletion happens
) ENGINE = ReplacingMergeTree(is_deleted)
ORDER BY (attendance_id);
-- use MergeTree() engine for append only
-- use ReplacingMergeTree() for upsert
```

- You can also run this by default on docker compose 


# Test the insertion
```sql
INSERT INTO attendances (
    user_id,
    shift_schedule_id,
    company_id,
    check_in,
    check_out
)
SELECT
    18204,                                  
    44734,                                  
    75,                                     
    '2025-07-10 09:16:16.000'::timestamp,   
    '2025-07-10 15:55:51.000'::timestamp
FROM generate_series(1, 100);  
```