create table users(
);

create table delayed_jobs(
);

create table user_types(
id serial,
name text,
-- max_nber_jobs int,
max_nber_cores int,
max_total_memory int,
primary key (id)
);

create table sessions(
);

create table tool_types(
id serial,
name text,
primary key (id)
);

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

create table versions(
id serial,
release_date timestamp,
description text,
tools_json text,
docker_json text,
env_json text,
created_at timestamp,
updated_at timestamp,
primary key (id)
);

create table steps(
id serial,
obj_name text,
name text,
label text,
description text,
rank int,
multiple_runs bool default true,
-- method_obj_name text,
-- is_std_step bool,
has_std_dashboard bool default true,
has_std_form bool default true,
has_std_view bool default true,
attrs_json text default '{}', -- optional attributes for each step
method_attrs_json text default '{}', -- global properties of standard method attributes
method_output_json text default '{}', -- global properties of standard method outputs
command_json default '{}',
-- action_button_name text,
version_id int references versions (id),
primary key (id)
);

create table tools(
id serial,
name text,
label text,
tool_type_id int references tool_types,
step_ids text,
description text,
created_at timestamp,
updated_at timestamp,
primary key (id)
);


create table db_sets(
id serial,
tool_id int references tools,
label text,
tag text, -- used for filename (databases) 
primary key (id)
);

create table ensembl_subdomains(
id serial,
name text,
latest_ensembl_release int,
primary key (id)
);

create table organisms(
id serial,
name text,
short_name text,
go_short_name text,
genrep_key text,
tax_id int,
tag text,
ensembl_subdomain_id int references ensembl_subdomains (id),
created_at timestamp,
updated_at timestamp,
primary key (id)
);


create table speeds(
id serial,
name text,
color text,
primary key (id)
);

create table cluster_methods(
id serial,
name text,
label text,
description text,
program text,
link text,
speed_id smallint references speeds,
attrs_json text,
warning text,
created_at timestamp,
updated_at timestamp,
primary key (id)
);

--create table cluster_methods(
--id serial,
--name text,
--label text,
--description text,
--program text,
--link text,
--speed_id smallint references speeds,
--attrs_json text,
--created_at timestamp,
--updated_at timestamp,
--primary key (id)
--);


create table diff_expr_methods(
id serial,
name text,
label text,
short_label text,
description  text,
program text,
link text,
speed_id smallint references speeds,
attrs_json text,
handles_log bool default false,
creates_av_norm bool default false,
created_at timestamp,
updated_at timestamp,
primary key (id)
);

create table filter_methods(
id serial,
name text,
label text,
description  text,
program text,
link text,
speed_id smallint references speeds,  
attrs_json text,
handles_log bool default false,
created_at timestamp,
updated_at timestamp,
primary key (id)
);

create table norms(
id serial,
name text,
label text,
description  text,
program text,
speed_id smallint references speeds,
output_is_log bool default true,
attrs_json text,
handles_log bool default false,
hidden bool default false,
created_at timestamp,
updated_at timestamp,
primary key (id)
);

create table statuses(
id serial,
name text,
label text,
img_extension text,
icon_class text, 
primary key (id)
);

create table jobs( --keep history of all 
id serial,
project_id int,
step_id int references steps(id),
status_id int references statuses (id),
command_line text,
duration int,
pid int,
delayed_job_id int,
speed_id int references speeds, -- queue              
user_id int references users,
created_at timestamp,
updated_at timestamp
primary key (id)
);

create table projects(
id serial,
name text,
key varchar(6),
input_filename text,
input_status text,
group_filename text,
organism_id int references organisms (id) default 1,
parsing_attrs_json text,
parsing_job_id int  references jobs,
norm_id int references norms default null,
norm_attrs_json text,
normalization_job_id int  references jobs,
filter_method_id int references filter_methods default null,
filter_method_attrs_json text,
filtering_job_id int  references jobs,
delayed_job_id int,
step_id int references steps default 1,
status_id int references statuses default 1,
duration int,
error_message text,
pid int,
extension varchar(6) default 'txt',
public bool default false,
user_id int references users (id),
cloned_project_id int,
sandbox bool default false,
session_id int,
pmid int,
nber_cells int,
nber_genes int,
diff_expr_filter_json text,
gene_enrichment_filter_json text,
nber_clones int default 0,
version_id int references versions,
created_at timestamp,
updated_at timestamp,
primary key (id)
);

create table uploads(
id serial,
project_id int references projects,
upload_type int,
name text,
status text,
upload_file_name text,
upload_content_type text,
upload_file_size int,
upload_updated_at timestamp,
visible bool,
created_at timestamp,
updated_at timestamp,
primary key (id)
);

create table fus(
id serial,
project_id int references projects,
project_key text,
upload_type int,
name text,
status text,
upload_file_name text,
upload_content_type text,
upload_file_size bigint,
upload_updated_at timestamp,
url text,
visible bool,
created_at timestamp,
updated_at timestamp,
primary key (id)
);

create table dim_reductions(
id serial,
name text,
label text,
description text,
rank int,
program text,
link text,
speed_id smallint references speeds,
attrs_json text,
dim_reduction bool,
created_at timestamp,
updated_at timestamp,
primary key (id)
);

create table project_dim_reductions(
id serial,
project_id int references projects (id),
dim_reduction_id int references dim_reductions (id),
attrs_json text,
job_id int  references jobs,
status_id int references statuses (id),
duration int,
pid int,
created_at timestamp,
primary key (id)
);

create table pipelines(
id serial,
project_id int references projects (id),
name text,
created_at timestamp,
primary key (id)
);

create table std_methods(
id serial,
name text,
label text,
step_id int references steps (id),
description  text,
short_label text,
program text,
link text,
speed_id smallint references speeds,
nber_cores int,
async bool, -- async execution
attrs_json text default '{}',
attr_layout_json text default '[]',
output_json text default '{}', -- describe the outputs (files, annotations)
obj_attrs_json text default '{}', -- object attributes e.g. handles_log for most of methods, or creates_av_norm for de
-- handles_log bool default false,
version_id int references versions (id),
created_at timestamp,
updated_at timestamp,
primary key (id)
);

create table reqs(
id serial,
project_id int references projects (id),
step_id int references steps (id),
std_method_id int references std_methods (id),
-- run_id int references runs (id), -- data origin                                                 
attrs_json text default '{}',
-- output_json text default '{}', -- describe the outputs (files, annotations)                                                            
num int,
pid int,
error text,
created_at timestamp,
user_id int references users,
primary key (id)
);

create table runs( --can be deleted
id serial,
project_id int references projects (id),
step_id int references steps (id),
std_method_id int references std_methods (id),
req_id int references reqs (id),
-- run_id int references runs (id), -- data origin
attrs_json text default '{}',
output_json text default '{}', -- describe the outputs (files, annotations)
num int,
--job_id int references jobs,
command_json text,
duration int,
pid int,
--delayed_job_id int,
--speed_id int references speeds,
nber_cores int,
max_ram float,
error text,
async bool default true,
status_id int references statuses,
-- run_path_json text, -- full path until this std_run
run_parents_json text, -- list the parents with the link properties (which data from each parent is used) = data origin
run_children_json text, -- list the children with the link properties (which data are used by children)
created_at timestamp,
user_id int references users,
primary key (id)
);

create table active_runs( --only active runs (pending + running)              
id serial,
run_id int references runs (id),
project_id int references projects (id),
step_id int references steps (id),
std_method_id int references std_methods (id),
req_id int references reqs (id),
-- run_id int references runs (id), -- data origin                                             
attrs_json text default '{}',
output_json text default '{}', -- describe the outputs (files, annotations)                       
num int, --job_id int references jobs,                                                     
command_json text,
duration int,
pid int,--delayed_job_id int,  
--speed_id int references speeds,
nber_cores int,
max_ram float,
error text,
async bool default true,
status_id int references statuses,
-- run_path_json text, -- full path until this std_run                                           
run_parents_json text, -- list the parents with the link properties (which data from each parent is used) = data origin 
run_children_json text, -- list the children with the link properties (which data are used by children)  
created_at timestamp,
user_id int references users,
primary key (id)
);

create table del_runs( -- deleted project runs, only failed + success
id serial,
run_id int,
project_id, -- int references projects (id),
step_id int references steps (id),
std_method_id int references std_methods (id),
req_id, --int references reqs (id),
-- run_id int references runs (id), -- data origin                         
attrs_json text default '{}',
output_json text default '{}', -- describe the outputs (files, annotations)                                       
num int,--job_id int references jobs,               
command_json text,
duration int,
pid int,
--delayed_job_id int,
--speed_id int references speeds,
nber_cores int,
max_ram float,
error text,
async bool default true,
status_id int references statuses,
-- run_path_json text, -- full path until this std_run  
run_parents_json text, -- list the parents with the link properties (which data from each parent is used) = data origin 
run_children_json text, -- list the children with the link properties (which data are used by children)
created_at timestamp,
user_id int references users,
primary key (id)
)

create index project_id_del_runs on del_runs (project_id);

create table heatmaps(
id serial,
project_id int references projects (id),
-- covariate_method_id int references covariate_methods,
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

create table trajectories(
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

create table correlations(
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

create table covariates(
id serial,
project_id int references projects (id),
-- covariate_method_id int references covariate_methods,
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

--create table visualizations(
--id serial,
--project_id int references projects (id),
--dim_reduction_id int references dim_reductions,
--attrs_json text,
--num int,
--job_id int references jobs,
--pid int,
--error text,
--created_at timestamp,
--user_id int references users,
--primary key (id)
--);


create table clusters(
id serial,
num int, --identifier for a given project
label text,
project_id int references projects (id),
dim_reduction_id int references dim_reductions (id),
step_id int references steps (id),
cluster_method_id int references cluster_methods (id),
attrs_json text,
status_id int references statuses,
duration int,
job_id int references jobs,
pid int,
error text,
created_at timestamp,
updated_at timestamp,
user_id int references users,
primary key (id)
);

create table diff_exprs(
id serial,
project_id int references projects (id),
diff_expr_method_id int references diff_expr_methods (id),
selection1_id int, -- references selections,      
md5_sel1 text,
md5_sel2 text,
nb_cells_sel1 int,
nb_cells_sel2 int,
selection2_id int, -- references selections,  
--step_id int references steps,
attrs_json text,
nber_up_genes int,
nber_down_genes int,
status_id int references statuses (id),
duration int,
label text,
num int,
job_id int references jobs,
pid int,
error text,
created_at timestamp,
user_id int references users,
primary key (id)
);

create table gene_enrichments(
id serial,
num int, --identifier for a given project   
label text,
project_id int references projects (id),
--dim_reduction_id int references dim_reductions (id),
--step_id int references steps (id),
--cluster_method_id int references cluster_methods (id),
diff_expr_id int references diff_exprs (id),
attrs_json text,
nber_pathways int,
status_id int references statuses,
duration int,
pid int,
job_id int references jobs,
error text,
created_at timestamp,
updated_at timestamp,
user_id int references users,
primary key (id)
);

create table genes(
id serial,
ensembl_id text,
name text,
biotype text,
chr text,
gene_length int,
sum_exon_length int,
organism_id int references organisms,
alt_names text,
latest_ensembl_release int,
created_at timestamp,
primary key (id)
);

create index genes_ensembl_id_idx on genes (ensembl_id);
create index genes_name_idx on genes (name);

create table gene_names(
id serial,
gene_id int references genes,
organism_id int references organisms,
value text,
primary key (id)
);

create table selections(
id serial,
label text, --"Manual x / Cluster x.y"
manual_num int, -- identifier in case of manual selection else null
obj_id int,-- references clusters, -- null if manual selection
obj_num int, --null if manual selection
md5 text,
nb_items int,
project_id int references projects,
edited bool default false,
selection_type_id int default 1,
created_at timestamp,
updated_at timestamp,
user_id int references users,
primary key (id)
);

create table project_steps(
id serial,
project_id int references projects,
step_id int references steps,
status_id int references statuses,
job_id int references jobs,
error_message text,
created_at timestamp,
updated_at timestamp,
primary key (id)
);

create table gene_sets(	-- if project_id null and user_id = 1  => gene sets globaux par organism_id                                        
             		-- otherwise custom gene sets (partials in function of genes present in a project)                                 
		        -- update can be made only for the name of the gene set                                                            
id serial,
user_id int references users,
project_id int references projects, -- this field allows to know if it is a global dataset or not
organism_id int references organisms,
--tool_id int references tools, -- external database when it is a global gene set
label text, -- db name if gene set global                                                                                                   
original_filename text, -- can be null if imported from de                                                                                 
ref_id int, -- cannot be null : =diff_expr_id if from DE or =db_set_id if from geneset database                                                               
nb_items int default 3, -- number of lines in the file = number of sets
created_at timestamp,
updated_at timestamp,
primary key (id)
);

create table shares(
id serial,
project_id int references projects,
user_id int references users, -- can be null,
email text,
view_perm bool,
analyze_perm bool,
-- clone_perm bool,
-- download_perm bool,
export_perm bool,
created_at timestamp,
updated_at timestamp,
primary key (id)
);

--create table gene_set_names(
--id serial,
--gene_set_id int references gene_sets,
--identifier text,
--name text,
--num int,
--nb_items int,
--user_id int references users,
--created_at timestamp,
--updated_at timestamp,
--primary key (id)
--);

create table figures(
);

create table comments(
);
