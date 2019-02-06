alter table steps add column rank int;
update steps set rank = id where id < 4;
update steps set rank = id+1 where id > 3;
--alter table steps add column group_name text;
--alter table steps add column method_obj_name text;
--alter table steps add column is_std_step bool default true;
alter table steps add column attrs_json text default '{}';
alter table steps add column method_attrs_json text default '{}';
alter table steps add column has_std_dashboard bool default true;
alter table steps add column has_std_form bool default true;
alter table steps add column has_std_view bool default true;
alter table steps add column command_json default '{}';
alter table steps add column version_id int references versions,

alter table genes add column latest_ensembl_release int;

alter table versions add column env_json text default {};

create table ensembl_subdomains(
id serial,
name text,
primary key (id)
);

alter table organisms add column ensembl_subdomain_id int references ensembl_subdomains (id);

alter table dim_reductions add column rank int;
update dim_reductions set rank = id;

ALTER SEQUENCE steps_id_seq RESTART WITH 8;
-- add imputation step through the website

alter table dim_reductions add column dim_reduction bool default false;
update dim_reductions set dim_reduction = true where id < 5;

create table std_methods(
id serial,
name text,
label text,
step_id int references steps (id),
description  text,
--program text,
link text,
--speed_id smallint references speeds,
nber_cores int,
attrs_json text default '{}', -- object instance attributes
attr_layout_json text default '[]'
obj_attrs_json text default '{}', -- optional object attributes e.g. handles_log for most of methods, or  creates_av_norm for de         
command_json text default '{}',
-- handles_log bool default false,                                                                  
version_id int references versions,
created_at timestamp,
updated_at timestamp,
primary key (id)
);

create table runs(
id serial,
project_id int references projects (id),
step_id int references steps (id),
std_method_id int references std_methods (id),
-- run_id int references runs (id), -- data origin                                                          
attrs_json text default '{}',
output_json text default '{}', -- describe the outputs (files, annotations)   
num int,
job_id int references jobs,
pid int,
error text,
status_id int references statuses,
--run_path_json text, -- full path until this std_run                         
nber_cores int, 
run_parents_json text, -- list the parents with the link properties (which data from each parent is used) = data origin      
run_children_json text, -- list the children with the link properties (which data are used by children)                       
created_at timestamp,
user_id int references users,
primary key (id)
);



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

create table cell_filterings(
id serial,
project_id int references projects (id),
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

create table gene_filterings(
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
alter table projects add column version_id int references versions;

-- add url field in fus
alter table fus add column url text;

create table file_formats(
id serial,
label text,
description text,
child_format text,
color text,
many_files bool,
parsing_mandatory_sel bool,
primary key (id)
);
