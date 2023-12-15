desc '####################### fix metadata propagation'
task fix_metadata_propag: :environment do
  puts 'Executing...'
  
  now = Time.now
  
  data_dir = Pathname.new(APP_CONFIG[:data_dir])
  
  h_steps = {}
  Step.all.each do |s|
    h_steps[s.id] = s
  end

  projects = Project.where(:key => 'kvvxcr').all
  projects.each do |p|
    
    project_dir = data_dir + 'users' + p.user_id.to_s + p.key    

    h_runs = {}
    p.runs.map{|r| h_runs[r.id] = r}

    list_to_destroy = []
    p.annots.each do |annot|
      ori_run_step_name = h_steps[h_runs[annot.ori_run_id].step_id].name
      run_step_name = h_steps[annot.step_id].name
      if ['cell_filtering', 'gene_filtering'].include? run_step_name and ori_run_step_name == 'de' #!['parsing', 'import_metadata', 'cell_filtering', 'gene_filtering', 'normalization', 'removing_covariates', 'scaling'].include? ori_run_step_name
        #    if ('cell_filtering' == run_step_name and !['parsing', 'import_metadata', 'normalisation', 'scaling'].include? ori_run_step_name) or
        #        ('gene_filtering' == run_step_name and !['parsing', 'import_metadata', 'cell_filtering', 'normalisation', 'scaling'].include? ori_run_step_name)
        puts "ALERT metadata to delete: #{annot.to_json}"
        cmd = "java -jar lib/ASAP.jar -T RemoveMetaData -o tmp/ -loom #{project_dir + annot.filepath} -meta #{annot.name} 2>&1 > tmp/bla.txt"
        puts cmd
        `#{cmd}`
        list_to_destroy.push annot
      end
    end

    
    list_to_destroy.map{|e| e.destroy} # if list_to_destroy.size > 0

  end		

end
