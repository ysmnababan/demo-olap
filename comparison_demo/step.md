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

## create network, and connect to the postgres
docker network create olap_network
docker network connect <network_name> <container_name_or_id>
docker network connect olap_network malut_clone


**db query example => as a attendance_fact**
```sql
select 
	a.id as attendance_id, 
	a.check_in , 
	a.check_out,
	a.company_id,
	ss.schedule_date ,
	ss.clock_in_time ,
	ss.clock_out_time ,
	sr."name" as shift_rule_name,
	sr.location_address ,
	sr.location_name,
	sr.clock_in_time as sr_cit,
	sr.clock_out_time as sr_cot,
	u.id as user_id,
	u.nip ,
	u.fullname,
	muo.unit_organisasi ,
	muo.parent_id ,
	mg."name" as grade_name,
	mp.nama_jabatan,
	mpt.jenis_jabatan 
from 
	attendances a 
join shift_schedule ss on ss.id =a.shift_schedule_id 
join shift_rules sr on sr.id =ss.shift_rule_id
join users u on a.user_id =u.id
join master_unit_organization muo on muo.id = u.unor_id
left join user_grade ug on ug.user_id =u.id 
left join master_grade mg on mg.id = ug.grade_id
left join user_position up on up.user_id =u.id 
left join master_position mp on mp.id =up.position_id
left join master_position_type mpt on mpt.id = mp.position_type_id 
where mpt.jenis_jabatan is null;
```
## check user privileges
required privilege for `DEBEZIUM`:
  REPLICATION (for reading WAL)
  SELECT on all tables in the publication

- grant with this
ALTER USER admin WITH REPLICATION;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO admin;

## create publication for each table
-- List existing publications
SELECT * FROM pg_publication;

-- If missing, create it (change this according to your usage)
CREATE PUBLICATION demo_pub FOR TABLE
    attendances, shift_schedule, shift_rules, users,
    master_unit_organization, user_grade, master_grade,
    user_position, master_position, master_position_type;


---
# DEBEZIUM

## create the debezium config
- adjust the `database.hostname` to your db host
- adjust the db credential
- dont forget to add the `topic.prefix`
look at [here](./debezium_config.md) for more detail

## Deploy the connector to Kafka Connect
- make sure the kafka can connect to application
```sh
curl -X POST -H "Content-Type: application/json" \
     --data @register-postgres-connector.json \
     http://localhost:8083/connectors
```
- if you want to edit the connector after deploying it first,
  you have to do different update procedure like [this](/cdc_demo/README.md#update-config-if-needed)

- verify the connector status
```sh
curl http://localhost:8083/connectors/postgres-connector/status

{"name":"postgres-connector","connector":{"state":"RUNNING","worker_id":"172.26.0.4:8083"},"tasks":[{"id":0,"state":"RUNNING","worker_id":"172.26.0.4:8083"}],"type":"source"}
```
-- you can also restart the connector
curl -X POST http://localhost:8083/connectors/postgres-connector/restart

- debezium create this prefix as topic
<topic.prefix>.<schema>.<table>

# REDPANDA
- check the topic list
docker exec -it redpanda rpk topic list
- consume topic
docker exec -it redpanda rpk topic consume dbserver1.public.attendances

