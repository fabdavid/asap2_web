--create table tool_types(
--id serial,
--name text,
--primary key (id)
--);

--create table tools(
--id serial,
--name text,
--label text,
--tool_type_id int references tool_types,
--step_ids text,
--description text,
--created_at timestamp,
--updated_at timestamp,
--primary key (id)
--);

create table db_sets(
id serial,
tool_id int, --references tools,
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

create table gene_names(
id serial,
gene_id int references genes,
organism_id int references organisms,
value text,
primary key (id)
);

create index gene_names_value_idx on gene_names (value);


create table gene_sets( -- if project_id null and user_id = 1  => gene sets globaux par organism_id 
                        -- otherwise custom gene sets (partials in function of genes present in a project)
                        -- update can be made only for the name of the gene set
id serial,
--user_id int references users,
--project_id int references projects, -- this field allows to know if it is a global dataset or not
organism_id int, -- references organisms,
--tool_id int references tools, -- external database when it is a global gene set
label text, -- db name if gene set global
original_filename text, -- can be null if imported from de
ref_id int, -- cannot be null : =diff_expr_id if from DE or =db_set_id if from geneset database
nb_items int default 3, -- number of lines in the file = number of sets
asap_data_id int,
latest_ensembl_release int,
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
asap_data_id int,
created_at timestamp,
updated_at timestamp,
primary key (id)
);

create index gene_set_items_gene_set_id_name on gene_set_items (gene_set_id, name);
