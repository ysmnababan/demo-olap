-- CREATE SOURCE TABLE
-- Attendances
CREATE TABLE attendances_source (
    id BIGINT PRIMARY KEY,
    user_id BIGINT  ,
    shift_schedule_id BIGINT,
    check_in TIMESTAMP,
    check_out TIMESTAMP,
    check_in_latitude NUMERIC,
    check_in_longitude NUMERIC,
    check_in_picture TEXT,
    status VARCHAR,
    created_at BIGINT,
    created_by BIGINT,
    modified_at BIGINT,
    modified_by BIGINT,
    deleted_at BIGINT,
    deleted_by BIGINT,
    company_id BIGINT
)
WITH (
    connector = 'kafka',
    topic = 'dbserver1.public.attendances',
    properties.bootstrap.server = 'redpanda:29092',
    scan.startup.mode = 'earliest'
)
FORMAT DEBEZIUM ENCODE JSON;

-- Shift Schedule
CREATE TABLE shift_schedule_source (
    id BIGINT PRIMARY KEY,
    company_id BIGINT  ,
    user_id BIGINT  ,
    shift_rule_id BIGINT  ,
    schedule_date DATE  ,
    clock_in_time TIME  ,
    clock_out_time TIME  ,
    is_holiday BOOLEAN,
    is_weekend BOOLEAN,
    status VARCHAR,
    created_at BIGINT,
    created_by BIGINT,
    modified_at BIGINT,
    modified_by BIGINT,
    deleted_at BIGINT,
    deleted_by BIGINT
)
WITH (
    connector = 'kafka',
    topic = 'dbserver1.public.shift_schedule',
    properties.bootstrap.server = 'redpanda:29092',
    scan.startup.mode = 'earliest'
)
FORMAT DEBEZIUM ENCODE JSON;

-- Shift Rules
CREATE TABLE shift_rules_source (
    id BIGINT PRIMARY KEY,
    name TEXT,
    late_time_tolerance BIGINT,
    late_limit BIGINT,
    absence_limit BIGINT,
    early_clock_in BIGINT,
    early_clock_out BIGINT,
    location_name TEXT,
    location_address TEXT,
    latitude NUMERIC,
    longitude NUMERIC,
    radius BIGINT,
    is_picture BOOLEAN,
    is_approval BOOLEAN,
    is_description BOOLEAN,
    is_location BOOLEAN,
    is_active BOOLEAN,
    company_id BIGINT,
    created_at BIGINT,
    created_by BIGINT,
    modified_at BIGINT,
    modified_by BIGINT,
    deleted_at BIGINT,
    deleted_by BIGINT,
    timezone VARCHAR,
    is_saturday_active BOOLEAN,
    is_sunday_active BOOLEAN,
    clock_in_time TIME  ,
    clock_out_time TIME  
)
WITH (
    connector = 'kafka',
    topic = 'dbserver1.public.shift_rules',
    properties.bootstrap.server = 'redpanda:29092',
    scan.startup.mode = 'earliest'
)
FORMAT DEBEZIUM ENCODE JSON;

-- Users
CREATE TABLE users_source (
    id BIGINT PRIMARY KEY,
    nip TEXT,
    fullname TEXT,
    gender TEXT,
    birth_place TEXT,
    date_of_birth TEXT,
    religion TEXT,
    created_at BIGINT,
    created_by BIGINT,
    modified_at BIGINT,
    modified_by BIGINT,
    deleted_at BIGINT,
    deleted_by BIGINT,
    password VARCHAR,
    company_id BIGINT,
    role_id BIGINT,
    phone VARCHAR,
    email VARCHAR,
    unor_id BIGINT,
    fcm_token VARCHAR,
    union_id VARCHAR,
    wallet_id VARCHAR,
    palm_card_number VARCHAR
)
WITH (
    connector = 'kafka',
    topic = 'dbserver1.public.users',
    properties.bootstrap.server = 'redpanda:29092',
    scan.startup.mode = 'earliest'
)
FORMAT DEBEZIUM ENCODE JSON;

-- Master Unit Organization
CREATE TABLE master_unit_organization_source (
    id INT PRIMARY KEY,
    unit_organisasi TEXT,
    parent_id BIGINT,
    created_at BIGINT,
    created_by BIGINT,
    modified_at BIGINT,
    modified_by BIGINT,
    deleted_at BIGINT,
    deleted_by BIGINT,
    company_id BIGINT
)
WITH (
    connector = 'kafka',
    topic = 'dbserver1.public.master_unit_organization',
    properties.bootstrap.server = 'redpanda:29092',
    scan.startup.mode = 'earliest'
)
FORMAT DEBEZIUM ENCODE JSON;

-- User Grade
CREATE TABLE user_grade_source (
    id BIGINT PRIMARY KEY,
    user_id BIGINT,
    grade_id BIGINT,
    start_at BIGINT,
    company_id BIGINT,
    created_at BIGINT,
    created_by BIGINT,
    modified_at BIGINT,
    modified_by BIGINT,
    deleted_at BIGINT,
    deleted_by BIGINT
)
WITH (
    connector = 'kafka',
    topic = 'dbserver1.public.user_grade',
    properties.bootstrap.server = 'redpanda:29092',
    scan.startup.mode = 'earliest'
)
FORMAT DEBEZIUM ENCODE JSON;

-- Master Grade
CREATE TABLE master_grade_source (
    id BIGINT PRIMARY KEY,
    name TEXT,
    is_active BOOLEAN,
    count BIGINT,
    company_id BIGINT,
    created_at BIGINT,
    created_by BIGINT,
    modified_at BIGINT,
    modified_by BIGINT,
    deleted_at BIGINT,
    deleted_by BIGINT
)
WITH (
    connector = 'kafka',
    topic = 'dbserver1.public.master_grade',
    properties.bootstrap.server = 'redpanda:29092',
    scan.startup.mode = 'earliest'
)
FORMAT DEBEZIUM ENCODE JSON;

-- User Position
CREATE TABLE user_position_source (
    id BIGINT PRIMARY KEY,
    user_id BIGINT,
    position_id BIGINT,
    start_at BIGINT,
    company_id BIGINT,
    created_at BIGINT,
    created_by BIGINT,
    modified_at BIGINT,
    modified_by BIGINT,
    deleted_at BIGINT,
    deleted_by BIGINT
)
WITH (
    connector = 'kafka',
    topic = 'dbserver1.public.user_position',
    properties.bootstrap.server = 'redpanda:29092',
    scan.startup.mode = 'earliest'
)
FORMAT DEBEZIUM ENCODE JSON;

-- Master Position
CREATE TABLE master_position_source (
    id INT PRIMARY KEY,
    nama_jabatan TEXT,
    created_at BIGINT,
    created_by BIGINT,
    modified_at BIGINT,
    modified_by BIGINT,
    deleted_at BIGINT,
    deleted_by BIGINT,
    company_id BIGINT,
    position_type_id BIGINT
)
WITH (
    connector = 'kafka',
    topic = 'dbserver1.public.master_position',
    properties.bootstrap.server = 'redpanda:29092',
    scan.startup.mode = 'earliest'
)
FORMAT DEBEZIUM ENCODE JSON;

-- Master Position Type
CREATE TABLE master_position_type_source (
    id INT PRIMARY KEY,
    jenis_jabatan TEXT,
    created_at BIGINT,
    created_by BIGINT,
    modified_at BIGINT,
    modified_by BIGINT,
    deleted_at BIGINT,
    deleted_by BIGINT,
    company_id BIGINT
)
WITH (
    connector = 'kafka',
    topic = 'dbserver1.public.master_position_type',
    properties.bootstrap.server = 'redpanda:29092',
    scan.startup.mode = 'earliest'
)
FORMAT DEBEZIUM ENCODE JSON;


-- CREATE MATERIALIZED VIEW
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


-- -- CREATE SINK FOR CLICKHOUSE
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