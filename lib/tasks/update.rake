desc '####################### Update'
task update: :environment do
  puts 'Executing...'

  now = Time.now
  
  #    require 'yaml'
  
  ## set version
  
  v = Version.last
  
  ## create new version if last one is already active
  if v.activated == true
    tmp_v = v.dup
    tmp_v.activated = false
    tmp_v.save
    puts "Created " + tmp_v.to_json
    v = tmp_v
    #  h_version = {
    #    :activated => false
    #  }
    #  v = Version.new(h_version)
    #  v.save
  end
  
  previous_version_id = v.id - 1
  previous_version = Version.where(:id => previous_version_id).first
  
  ## get env
  h_env_previous = Basic.safe_parse_json(previous_version.env_json, {})
  
  new_db_version = h_env_previous['asap_data_db_version'] + 1
  
  puts new_db_version
  
  exit
  #### the following procedure should be run manually, checking each result step carefully this way:
  # sudo docker-compose exec website bash
  # nohup sh -c 'RAILS_ENV=data && rails update_xrefs 2>&1 > log/update_xrefs.log' &
  
  #  ## make a dump of the previous version
  #  cmd = "/usr/pgsql-10/bin/pg_dump -p5433 -h localhost --user 'postgres' asap2_data_v#{h_env_previous['asap_data_db_version']} > public/dumps/asap_data_previous.sql"
  #  `#{cmd}`
  #
  ## drop new db                                                                                                                                                         
  #  cmd = "/usr/pgsql-10/bin/dropdb -p5433 -h localhost --user 'postgres' asap2_data_v#{new_db_version}"       
  #  `#{cmd}`    
  
  ## create new db
  #  cmd = "/usr/pgsql-10/bin/createdb -p5433 -h localhost --user 'postgres' asap2_data_v#{new_db_version}"
  #  `#{cmd}`
  #
  #
  #  ## load previous version dump
  #  cmd = "/usr/pgsql-10/bin/psql -p5433 -h localhost --user 'postgres' -f public/dumps/asap_data_previous.sql asap2_data_v#{new_db_version}"
  #  `#{cmd}`
  
  ## edit database.yml
#  db_config_file = 'config/database.yml'
#  conf = YAML.load_file(db_config_file)
#  conf['data'] = {"url"=>"<%= ENV['DATABASE_URL'].gsub('?', '_data_v#{new_db_version}?') %>", "pool"=>10}
#  
#  File.open(db_config_file, "w") do |file| 
#    file.write(conf.to_yaml) 
#  end

  ## UPDATE 2024
  # manually take the dump for previous version, edit the database name with vi and save the sql
  # load the sql: docker-compose exec website psql -h postgres -p 5434 --user postgres -f /data/asap2/dumps/2024_12_24_asap2_data_vX_initial_load.sql
  # edit manually the database.conf file to edit data_vX, data_tmp and data
  
  ### This tools_versions.json is used as a tmp json. the final version is save at the end in the version.env_json field
  ## remove tool_versions.json
  output_json = Pathname.new(APP_CONFIG[:data_dir]) + 'tmp' + 'tool_versions.json'
  File.delete(output_json) if File.exist? output_json
  #  h_tool_version = Basic.safe_parse_json(File.read(output_json), {})
  #  puts h_tool_version.to_json
  #########################################

  ## edit Ensembl versions in update_genes (the automated script to find the version is failing because the format changes all the time in the README to extract the release number => just commented it out and edit the version manually)
  
  ## update genes                                                                                                                                                            
    cmd = "RAILS_ENV=data && rails update_genes 2>&1 > log/update_genes.log"
    puts cmd
  `#{cmd}`
  
 # ## update DrugBank => this is obsolete =< Drugbank xrefs data are retrieved from Ensembl                                                                  
 # cmd = "docker-compose exec website sh -c 'RAILS_ENV=data && rails update_drugbank'  2>&1 > log/update_drugbank.log"
 # `#{cmd}`
  
  ## update flybase gene names
  cmd = "RAILS_ENV=data && rails update_droso_gene_names 2>&1 > log/update_droso_gene_names.log"
  puts cmd
  `#{cmd}`
  	
  ## add some secondary flybase ID in alt_names - if Ensembl is not up to date
  cmd = "RAILS_ENV=data && rails update_from_flybase  2>&1 > log/update_from_flybase.log"
  puts cmd
  `#{cmd}`

  ## compute GO lineages
  cmd = "RAILS_ENV=data && rails compute_go_lineage 2>&1 > log/compute_go_lineage.log"
  puts cmd
  `#{cmd}`
  
  ## update species
  ### edit version number in get_ensembl_species.rake  
#  cmd = "RAILS_ENV=data && rails get_ensembl_species 2>&1 > log/get_ensembl_species.log"
#  puts cmd
#  `#{cmd}`

#exit
  
  ## update organism_tags from KEGG
  cmd = "RAILS_ENV=data && rails update_organism_tag 2>&1 > log/update_organism_tag.log"
  puts cmd
  `#{cmd}`

  ## the same in the main db
  cmd = "rails update_organism_tag 2>&1 > log/update_organism_tag.log"
  puts cmd
  `#{cmd}`

  
  ## update xrefs                                                  
  cmd = "RAILS_ENV=data && rails update_xrefs 2>&1 > log/update_xrefs.log"
  puts cmd
  `#{cmd}`

  ## update panglaodb ## no updated data since 2020
  cmd = "RAILS_ENV=data && rails update_panglaodb 2>&1 > log/update_panglaodb.log"
  puts cmd
  `#{cmd}`
  
  ## update ontologies
  cmd = "RAILS_ENV=development && rails load_ontologies 2>&1 > log/load_ontologies.log"
  puts cmd
  `#{cmd}`
  
  ## extract ids from ontologies
  cmd = "RAILS_ENV=development && rails extract_ids_from_ontologies 2>&1 > log/extract_ids_from_ontologies.log"
  puts cmd
  `#{cmd}`
  
  ## update ontologies in gene sets
  cmd = "RAILS_ENV=data && rails load_ontologies_in_gene_sets 2>&1 > log/load_ontologies_in_gene_sets.log"
  puts cmd
  `#{cmd}`

  ## update latest Version object instance: set the correct version of database and asap_run in the web interface (in admin mode)
  
  ## update tools
  cmd = "RAILS_ENV=development && rails update_tools 2>&1 > log/update_tools.log"
  puts cmd
  `#{cmd}`
  
  #  exit
  
  #OR to do it in the background:                                                                                                                                                      
  # docker-compose exec website bash                                                                                                                                                   
  #cmd = "docker-compose exec website sh -c `RAILS_ENV=data && rails update_xrefs' 2>&1 > log/update_xrefs.log"                                                                      # `#{cmd}`                            
  ##update_drugbank                                                                                                                                                                   
  # docker-compose exec website bash                                                                                                                                                   
  #cmd = "docker-compose exec website sh -c `RAILS_ENV=data && rails update_drugbank' 2>&1 > log/update_drugbank.5.log"
  #`#{cmd}`
  
  ## postgresql asap_data_vX dump                                                                                                                                                     
  cmd = "/usr/pgsql-10/bin/pg_dump -p5433 -h localhost --user 'postgres'  asap2_data_v#{new_db_version} > public/dumps/asap_data_v#{new_db_version}.sql"                  
  
end
