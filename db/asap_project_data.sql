create table gene_sets( -- if project_id null and user_id = 1  => gene sets globaux par organism_id 
                        -- otherwise custom gene sets (partials in function of genes present in a project)
                        -- update can be made only for the name of the gene set
id serial,
user_id int, --references users,
--project_id int references projects, -- this field allows to know if it is a global dataset or not
organism_id int, --references organisms,
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
