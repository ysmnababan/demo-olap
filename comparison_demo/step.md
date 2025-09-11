
# dump the source
pg_dump -U your_user -h your_host -Fc your_database > db.dump
pg_dump -U palm -h 206.189.144.36 -Fc malut > db.dump

# create the container
docker run -d \
  --name malut_clone \
  -e POSTGRES_USER=admin \
  -e POSTGRES_PASSWORD=admin \
  -e POSTGRES_DB=palm \
  -p 5432:5432 \
  postgres:16

# configure the wal
ALTER SYSTEM SET wal_level = 'logical';
ALTER SYSTEM SET max_replication_slots = 4;
ALTER SYSTEM SET max_wal_senders = 4;

# create the role
docker exec -it malut_clone psql -U admin -d palm
CREATE ROLE developer LOGIN;
CREATE ROLE postgres LOGIN;
CREATE ROLE palm LOGIN;

# copy and restore the db
docker cp ./db/db.dump malut_clone:/db.dump
docker exec -it malut_clone pg_restore -U admin -d palm /db.dump

# create network, and connect to the postgres
docker network create olap_network
docker network connect <network_name> <container_name_or_id>
docker network connect olap_network malut_clone
----
# db query example => as a attendance_fact
```sql
select * from attendances a;

select * from users u;

select * from shift_schedule ss ;

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