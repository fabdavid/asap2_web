desc '####################### Create new asap_data_vX version'
task create_new_asap_data_version: :environment do
  puts 'Executing...'

  now = Time.now
  
  ### new release of the database asap_data_vX
  release_num = 4
  asap2_data_dbname = "asap2_data_v#{release_num}"
  dump_file = "/data/asap2/tmp/asap_dump.sql"
  ### make a dump of the database

  cmd = "PGPASSWORD='5Evba56' pg_dump -p5434  -h postgres --user postgres asap2_development > #{dump_file}"
  `#{cmd}`
  
  cmd = "PGPASSWORD='5Evba56' dropdb -p5434  -h postgres --user postgres #{asap2_data_dbname}"
  `#{cmd}`
  
  cmd = "PGPASSWORD='5Evba56' createdb -p5434  -h postgres --user postgres #{asap2_data_dbname}"
  `#{cmd}`
  
  cmd = "PGPASSWORD='5Evba56' psql -p5434 -h postgres --user postgres -f #{dump_file} #{asap2_data_dbname}"
  `#{cmd}`

  ## drop tables ### just once
# 
#  seqs = [
#          :active_runs_id_seq, :annnots_id_seq, :archive_statuses_id_seq, :cell_filterings_id_seq, :cluster_methods_id_seq, :clusters_id_seq, :correlations_id_seq, 
#          :courses_id_seq, :covariates_id_seq, :data_type_id_seq, :del_runs_id_seq, :delayed_jobs_id_seq, :diff_expr_methods_id_seq,
#          :diff_exprs_id_seq, :diff_exprs_id_seq, :dim_reductions_id_seq, :file_formats_id_seq, :filterings_id_seq, :filters_id_seq, :fos_id_seq, :fus_id_seq, 
#          :fos_id_seq, :gene_enrichments_id_seq, :provider_projects_id_seq, :heatmaps_id_seq, :imputation_methods_id_seq, :imputations_id_seq, 
#          :normalizations_id_seq, :norms_id_seq, :project_dim_reductions_id_seq, :project_steps_id_seq, :projects_id_seq, :reqs_id_seq, 
#          :runs_id_seq, :selections_id_seq, :sessions_id_seq, :shares_id_seq, :speeds_id_seq, :statuses_id_seq, :std_methods_id_seq, 
#          :std_runs_id_seq, :steps_id_seq, :tmp_genes_id_seq, :todo_types_id_seq, :todo_votes_id_seq, :todos_id_seq, :trajectories_id_seq, 
#          :upload_type_id_seq, :uploads_id_seq, :user_types_id_seq, :versions_id_seq 
#         ]
#  
#  tables = [:user_types, :versions, :users, :projects, :active_runs, :annots, :archive_statuses, :cell_filterings, :cluster_methods, :clusters,
#            :correlations, :covariates, :data_types, :del_runs, :delayed_jobs, :diff_expr_methods,
#            :diff_exprs, :dim_reductions, :file_formats, :filter_methods, :fos, :fus, :gene_enrichments,
# 	    :provider_projects, :provider_projects_projects, :heatmaps, :imputation_methods, :imputations, :jobs, :normalizations, :norms, :project_dim_reductions, 
#	    :project_steps, :reqs, :runs, :selections, :sessions, :shares, :speeds, :statuses, :std_methods, :std_runs, :steps, :tmp_genes, 
#	    :todo_types, :todo_votes, :todos, :trajectories, :upload_types, :uploads]
#  
#  tables.each do |t|
#    puts "Drop table #{t}..."
#    cmd = "PGPASSWORD='5Evba56' psql -p5434 -h postgres --user postgres -c 'drop table #{t}' #{asap2_data_dbname}"               
#    `#{cmd}`  
#  end


end
