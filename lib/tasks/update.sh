## OBSOLETE

## update DrugBank
docker-compose exec website sh -c 'RAILS_ENV=data && rails update_drugbank'

## update genes
docker-compose exec website sh -c 'RAILS_ENV=data && rails update_genes'
===> update gene_names
docker-compose exec website sh -c 'RAILS_ENV=data && rails update_gene_names'
===> update flybase gene names
docker-compose exec website sh -c 'RAILS_ENV=data && rails update_droso_gene_names'
====> add some secondary flyable ID in alt_names - if Ensembl is not up to date
docker-compose exec website sh -c "RAILS_ENV=data_v5 && rails update_from_flybase"
==> compute GO lineages
docker-compose exec website rails compute_go_lineage
==> update species
### edit version number in get_ensembl_species.rake
nohup sh -c 'RAILS_ENV=data && rails get_ensembl_species' 2>&1 > log/get_ensembl_species.5.log &
==> update organism_tags
docker-compose exec website sh -c 'RAILS_ENV=data && rails update_organism_tag'
OR
nohup sh -c `RAILS_ENV=data && rails update_organism_tag' 2>&1 > log/update_organism_tag.5.log &
==> update xrefs
docker-compose exec website sh -c 'RAILS_ENV=data && rails update_xrefs'
OR to do it in the background: 
 docker-compose exec website bash 
 nohup sh -c `RAILS_ENV=data && rails update_xrefs' 2>&1 > log/update_xrefs.log &
##update_drugbank
 docker-compose exec website bash 
 nohup sh -c `RAILS_ENV=data && rails update_drugbank' 2>&1 > log/update_drugbank.5.log &
 nohup sh -c `RAILS_ENV=data && rails update_gene_sets' 2>&1 > log/update_gene_sets.log &
## postgresql asap_data_vX dump
/usr/pgsql-10/bin/pg_dump -p5433 -h localhost --user "postgres"  asap2_data_v4 > public/dumps/asap_data_v4.sql
