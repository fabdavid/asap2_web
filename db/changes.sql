alter table steps add column rank int;
update steps set rank = id where id < 4;
update steps set rank = id+1 where id > 3;

alter table dim_reductions add column rank int;
update dim_reductions set rank = id;

ALTER SEQUENCE steps_id_seq RESTART WITH 8;
-- add imputation step through the website

alter table dim_reductions add column dim_reduction bool default false;
update dim_reductions set dim_reduction = true where id < 5;

create table normalizations(
id serial,
project_id int references projects (id),
norm_id int references norms,
attrs_json text,
num int,
job_id int references jobs,
pid int,
error text,
status_id int references statuses,
created_at timestamp,
user_id int references users,
primary key (id)
);

create table filterings(
id serial,
project_id int references projects (id),
filter_method_id int references norms,
attrs_json text,
num int,
job_id int references jobs,
pid int,
error text,
status_id int references statuses,
created_at timestamp,
user_id int references users,
primary key (id)
);

create table imputation_methods(
id serial,
name text,
label text,
description  text,
program text,
speed_id smallint references speeds,
is_parallelized bool,
attrs_json text,
hidden bool default false,
created_at timestamp,
updated_at timestamp,
primary key (id)
);

create table imputations(
id serial,
project_id int references projects (id),
imputation_method_id int references imputation_methods,
attrs_json text,
num int,
job_id int references jobs,
pid int,
error text,
status_id int references statuses,
created_at timestamp,
user_id int references users,
primary key (id)
);

-- rename Course to Fu 

alter table courses rename to fus;
alter table fus add column user_id int references users;

-- add fields to monitor space by user
alter table users add column project_space int default 0;
alter table users add column upload_space int default 0;

-- add field to know if the project is archived (after 2 days not viewed by anyone)
alter table projects add column upload_space int default 0;
alter table projects add column viewed_at timestamp default updated_at;

-- add url field in fus
alter table fus add column url text;
