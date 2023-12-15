create table project_cell_sets(
id serial,
key text,
nber_cells text,
created_at timestamp,
updated_at timestamp,
primary key (id)
);

create index key_project_cell_sets on  project_cell_sets (key);

create table docker_images(
id serial,
name text,
tag text,
full_name text,
version int,
tools_json text,
created_at timestamp,
updated_at timestamp,
primary key (id)
);

create table hcoa_terms(
id serial,
hcoa_id int,
name text,
description text,
primary key (id)
);

create table orcid_users(
id serial,
name text,
key text,
created_at timestamp,
updated_at timestamp,
primary key (id)
);

create table users(
orcid_user_id int references orcid_users
displayed_name text,
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
activated bool default false,
beta bool default true,
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
warnings text,
rank int,
color text, 
multiple_runs bool default true,
-- method_obj_name text,
-- is_std_step bool,
has_std_dashboard bool default true,
has_std_form bool default true,
has_std_view bool default true,
attrs_json text default '{}', -- optional attributes for each step
method_attrs_json text default '{}', -- global properties of standard method attributes
method_output_json text default '{}', -- global properties of standard method outputs
command_json text default '{}',
dashboard_card_json text default '{}',
show_view_json text default '{}',
-- action_button_name text,
version_id int references versions (id),
docker_image_id int references docker_images, -- link to the main docker asap_run
primary key (id)
);

create table tools(
id serial,
name text,
label text,
package text,
tool_type_id int references tool_types,
step_ids text,
title text,
description text,
url text,
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

create table cell_ontologies(
id serial,
name text, --HCAO or FlyBase Fly Anatomy
tag text,
file_url text,
url text,
format text,
latest_version text, -- only keep last version
tax_ids text,
created_at timestamp,
updated_at timestamp,
primary key (id)
);

create table cell_ontologies_organisms(
cell_ontology_id int references cell_ontologies,
organism_id int references organisms
);

create table cell_ontology_terms(
id serial,
cell_ontology_id int references cell_ontologies,
identifier text,
alt_identifiers text,
name text,
description text,
content_json text,
obsolete bool default false,
latest_version text,
related_gene_ids text,
node_gene_ids text,
node_term_ids text,
parent_term_ids text,
children_term_ids text,
lineage text,
original bool,
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
rank int,
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
updated_at timestamp,
primary key (id)
);

create table journals(
id serial,
name text,
created_at timestamp,
updated_at timestamp,
primary key (id)
);

create table articles(
id serial,
authors text,
title text,
journal_id int references journals,
pmid int,
volume text,
issue text,
abstract text,
year int,
published_at timestamp,
created_at timestamp,
updated_at timestamp,
primary key (id)
);

create index pmid_articles on articles (pmid);

create table project_types(
id serial,
name text,
tag text,
created_at timestamp,
updated_at timestamp,
primary key (id)
);

create table projects(
id serial,
name text,
key text,
input_filename text,
input_status text,
group_filename text,
organism_id int references organisms (id) default 1,
parsing_attrs_json text,
parsing_job_id int, --  references jobs,
norm_id int references norms default null,
norm_attrs_json text,
normalization_job_id int, --  references jobs,
filter_method_id int references filter_methods default null,
filter_method_attrs_json text,
filtering_job_id int, -- references jobs,
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
root_project_id int,
sandbox bool default false,
session_id int,
pmid int,
--geo_entry_ids text,
nber_cells int,
nber_genes int,
de_filter_json text,
ge_filter_json text,
nber_clones int default 0,
public_id int,
version_id int references versions,
replaced_by_project_key text,
replaced_by_comment text,
nber_cloned int default 0,
nber_views int default 0,
archive_status_id int references archive_statuses,
being_deleted bool default false,
last_day_session_ids text default '',
disk_size_archived bigint,
disk_size bigint,
fu_id int,
technology text,
tissue text,
extra_info text,
description text,
landing_page_json text default '{}',
created_at timestamp,
updated_at timestamp,
public_at timestamp,
frozen_at timestamp,
project_cell_set_id int references project_cell_sets,
project_type_id int references project_types,
primary key (id)
);

create table info_types(
id serial,
name text,
label text,
created_at timestamp,
updated_at timestamp,
primary key (id)
);

create table project_infos(
id serial,
info_type_id int references info_types,
value text,
created_at timestamp,
updated_at timestamp,
primary key (id)
);

create table project_tags(
id serial,
name text,
created_at timestamp,
updated_at timestamp,
primary key (id)
);

create table projects_tags_projects(
 project_tag_id int references project_tags,
 project_id int references projects
);

--create table articles_projects(
--article_id int references articles,
--project_id int references projects
--);

create table data_repos(
id serial,
name text,
created_at timestamp,
updated_at timestamp,
primary key (id)
);

create table exp_entries(
id serial,
identifier text,
identifier_type_id int references identifier_types,
title text,
description text,
pmid int,
contributors text,
identifiers_json text,
--srp text,
--bio_project text,
contact_emails text,
--contact_institute text,
--contact_department text,
--contact_lab text,
-- data_repository_id int references data_repos,
submitted_at timestamp,
created_at timestamp,
updated_at timestamp,
primary key (id)
);

create table identifier_types(
id serial,
name text
pluralizable bool default false,
prefix text,
url_mask text,
created_at timestamp,
updated_at timestamp,
primary key (id)
);

create table exp_entry_identifiers(
id serial,
identifier text,
identifier_type_id int references identifier_types,
exp_entry_id int references exp_entries,
created_at timestamp,
updated_at timestamp,
primary key (id)
);

create table sample_identifiers(
id serial,
identifier_type_id int references identifier_types,
identifier text,
url_mask text,
created_at timestamp,
updated_at timestamp,
primary key (id)
);

create table exp_entries_sample_identifiers(
exp_entry_id int references exp_entries,
sample_identifier_id int references sample_identifiers
);

create table exp_entries_projects(
exp_entry_id int references exp_entries,
project_id int references projects
);

create table providers(
id serial,
name text,
description text,
url text,
url_mask text,
tag text,
attrs_json text default '{}',
primary key (id)
);

--create table hca_projects(
--id serial,
--provider_id int references providers, 
--hca_project_key text,
--primary key (id)
--);

--create table hca_projects_projects(
--project_id int references projects,
--hca_project_id int references hca_projects
--);

create table provider_projects(
id serial,
provider_id int references providers,
key text,
title text,
filename text,
--filename text, -- file
--filekey text, -- file key for the loom file
attrs_json text default '{}',
comment text,
not_add_in_asap bool default false,
primary key (id)
);

create table projects_provider_projects(
project_id int references projects,
provider_project_id int references provider_projects
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

create table upload_types(
id serial,
name text,
created_at timestamp,
updated_at timestamp,
primary key (id)
);

create table fus(
id serial,
project_id int references projects,
project_key text,
upload_type int references upload_types,
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
docker_image_id int references docker_images,
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
delayed_job_id int,
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
pred_params_json text, -- parameters used to feed the execution memory and execution time prediction algorithm 
-- run_path_json text, -- full path until this std_run
run_parents_json text, -- list the parents with the link properties (which data from each parent is used) = data origin
run_children_json text, -- list the children with the link properties (which data are used by children)
created_at timestamp,
submitted_at timestamp, -- time the run execution starts 
user_id int references users,
pred_max_ram int,
pred_process_duration int,
return_stdout bool default false,
pipeline_parent_run_ids text default '',
primary key (id)
);

create table data_types(
id serial,
name text, -- int, float, text
label text,
created_at timestamp,
updated_at timestamp,
primary key (id)
);

create table data_classes(
id serial,
name text, -- dataset, col_annot, row_annot                                       
created_at timestamp,
updated_at timestamp,
primary key (id)
);

create table attr_names(
id serial,
name text, -- dataset, col_annot, row_annot                                                                                                          
created_at timestamp,
updated_at timestamp,
primary key (id)
);

create table output_attrs(
id serial,
name text,
created_at timestamp,
updated_at timestamp,
primary key (id)
)

create table annots(
id serial,
project_id int references projects,
step_id int references steps,
run_id int references runs,
filepath text,
col bool, -- true col, false row
data_type_id int references data_types,
data_class_ids text,
imported bool default false,
name text,
output_attr_id int references output_attrs,
nb_cat int, -- nber of categories (uniq values)
nb_na int,
nb_zero int,
min_val float,
max_val float,
mean_val float,
median_val float,
attrs_json text,
created_at timestamp,
updated_at timestamp,
label text, 
nber_rows int,
nber_cols int, 
dim smallint, 
categories_json text,       
list_cat_json text,
cat_aliases_json text, -- category names in the site
mem_size bigint, 
user_id int, 
store_run_id integer,
ori_run_id int, 
ori_step_id int,
headers_json text,
--nber_clas text, -- json list
--selected_cla_ids text, -- json list
cat_info_json text, -- {"nber_cla" : [], "selected_cla_ids" : []}
--attr_name text, 
--attr_name_id int references attr_names,
primary key (id)
);

create table active_runs( -- only active runs (pending + running)              
id serial,
run_id int references runs (id),
project_id int references projects (id),
step_id int references steps (id),
std_method_id int references std_methods (id),
req_id int references reqs (id),
-- run_id int references runs (id), -- data origin                                             
attrs_json text default '{}',
output_json text default '{}', -- describe the outputs (files, annotations)                       
num int, -- job_id int references jobs,                                                     
command_json text,
duration int,
pid int,-- delayed_job_id int,  
-- speed_id int references speeds,
nber_cores int,
max_ram float,
error text,
async bool default true,
status_id int references statuses,
-- run_path_json text, -- full path until this std_run                                           
run_parents_json text, -- list the parents with the link properties (which data from each parent is used) = data origin 
run_children_json text, -- list the children with the link properties (which data are used by children)  
created_at timestamp,
pred_max_ram int,
pred_process_duration int,
user_id int references users,
return_stdout bool default false,
pipeline_parent_run_ids text default '',
primary key (id)
);

create table del_runs( -- deleted project runs, only failed + success
id serial,
run_id int,
project_id int, -- references projects (id),
step_id int references steps (id),
std_method_id int references std_methods (id),
req_id int, -- references reqs (id),
-- run_id int references runs (id), -- data origin                         
attrs_json text default '{}',
output_json text default '{}', -- describe the outputs (files, annotations)                                       
num int, -- job_id int references jobs,               
command_json text,
duration int,
pid int,
-- delayed_job_id int,
-- speed_id int references speeds,
nber_cores int,
max_ram float,
error text,
async bool default true,
status_id int references statuses,
-- run_path_json text, -- full path until this std_run  
run_parents_json text, -- list the parents with the link properties (which data from each parent is used) = data origin 
run_children_json text, -- list the children with the link properties (which data are used by children)
created_at timestamp,
pred_max_ram int,
pred_process_duration int,
user_id int references users,
return_stdout bool default false,
pipeline_parent_run_ids text default '',
primary key (id)
);

create index project_id_del_runs on del_runs (project_id);

create table fos(
id serial,
 project_id int,
 run_id     int,
 filepath text, 
 filesize  bigint,
 user_id  int,
 updated_at timestamp,
 created_at timestamp,
 ext  text, 
primary key (id)
);

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
ncbi_gene_id int,
name text,
biotype text,
chr text,
gene_length int,
sum_exon_length int,
organism_id int references organisms,
alt_names text,
latest_ensembl_release int,
description text,
created_at timestamp,
updated_at timestamp,
primary key (id)
);

create index genes_ensembl_id_idx on genes (ensembl_id);
create index genes_name_idx on genes (name);

create table tmp_genes(
id serial,
ensembl_id text,
ncbi_gene_id int,
name text,
biotype text,
chr text,
gene_length int,
sum_exon_length int,
organism_id int references organisms,
alt_names text,
obsolete_alt_names text,
latest_ensembl_release int,
description text,
created_at timestamp,
updated_at timestamp,
primary key (id)
);

create index tmp_genes_ensembl_id_idx on tmp_genes (ensembl_id);
create index tmp_genes_name_idx on tmp_genes (name);


create table gene_names(
id serial,
gene_id int references genes,
organism_id int references organisms,
value text,
primary key (id)
);

create index gene_names_value_idx on gene_names (value);


create table selections(
id serial,
label text, --"Manual x / Cluster x.y"
manual_num int, -- identifier in case of manual selection else null
--obj_id int,-- references clusters, -- null if manual selection
--obj_num int, --null if manual selection
ori_run_id int references runs,     -- run origin
ori_annot_id int references annots, -- annot origin
run_id int references runs, -- run of the selection
annot_id int references annots, -- annot where the selection is stored
cluster int, -- cluster number
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

create table gene_set_items(
id serial,
gene_set_id int references gene_sets,
identifier text,
name text,
content text,
-- url text,
created_at timestamp,
updated_at timestamp,
primary key (id)
);

create index gene_set_items_gene_set_id_name on gene_set_items (gene_set_id, name);

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

create table docker_patches(
id serial,
version_id int references versions,
container_name text,
tag int,
description text,
std_method_ids text,
step_ids text,
activated_at timestamp,
created_at timestamp,
updated_at timestamp,
primary key (id)
);

create table figures(
);

create table comments(
);

-- create table services(
-- id serial,
-- user_id int references users,
-- created_at timestamp,
-- updated_at timestamp,
-- primary key (id)
-- );

create table ips(
id serial,
ip text,
key text,
primary key (id)
);

create table ips_users(
ip_id int references ips,
user_id int references users
);

create table cla_sources(
id serial,
name text, -- ASAP manual, SCope manual, 
label text,
url text, 
created_at timestamp,
updated_at timestamp,
primary key (id)
);

--create table cla_methods(
--id serial,
--name 
--);

create table cell_sets(
id serial,
key text,
--dataset_key text,
project_cell_set_id int references project_cell_sets,
nber_cells int,
nber_clas int,
cla_id int, -- references clas, -- remove the foreign keep to be able to delete
created_at timestamp,
updated_at timestamp,
primary key (id)
);

create index project_cell_set_id_key_cell_sets on  cell_sets (project_cell_set_id, key);


create table annot_cell_sets(
id serial,
project_id int references projects,
cell_set_id int references cell_sets,
annot_id int references annots,
cat_idx int,
created_at timestamp,
updated_at timestamp,
primary key (id)
);

create index cell_set_id_annot_cell_sets on  annot_cell_sets (cell_set_id);

create table clas( -- cluster annotations
id serial,
num int,
name text,
comment text,
cell_set_id int references cell_sets, -- optional => only for public projects
project_id int --references projects,
clone_id int references clas,
annot_id int --references annots, -- ASAP clustering or imported discrete annotation
cat text,
cat_idx int, -- group idx in list_cats of the metadata
cell_ontology_term_ids text,
sorted_cell_ontology_term_ids text,
-- cell_ontology_term_json text, -- several ontologies [{"identifier" : "CL:0000343"}, ...]
--cell_ontology_term_json text,
up_gene_ids text, --comma-separated list of gene_id (genes stored in asap_data)
sorted_up_gene_ids text,
down_gene_ids text,
sorted_down_gene_ids text,
orcid_user_id int references orcid_users,
user_id int references users,
cla_source_id int references cla_sources,
--cla_method_id int references cla_methods,
-- votes_json text, -- {"agree" : [{"user_id" : 4}], "disagree" : [{"user_id" : 3, "comment" : "Not happy with this annotation"}]}
nber_agree int default 0,
nber_disagree int default 0,
obsolete bool default false,
created_at timestamp,
updated_at timestamp,
primary key (id)
);

create table cla_votes(
id serial,
cla_source_id int references cla_sources, --vote source
cla_id int references clas,
orcid_user_id int references orcid_users,
user_name text, --optional
user_id int references users,
comment text,
voter_key text, --optional
agree bool,
created_at timestamp,
updated_at timestamp,
primary key (id)
);

