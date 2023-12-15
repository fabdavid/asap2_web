desc '####################### Import metadata'
task :import_metadata, [:project_key, :filepath, :metadata_type] => [:environment] do |t, args|
  puts 'Executing...'

#  args[:project_keys].split(":").each do |project_key|  
    
  project = Project.find_by_key(args[:project_key])
  version = project.version
  asap_docker_image = Basic.get_asap_docker(version)
  
    project_dir = Pathname.new(APP_CONFIG[:user_data_dir]) + project.user_id.to_s + project.key
    parsing_loom_file = project_dir + 'parsing' + 'output.loom'
       
    fus_dir = Pathname.new(APP_CONFIG[:data_dir]) + 'fus'
    # total_nber_operations = Run.joins("join steps on (step_id = steps.id)").where(:steps => {:name => 'import_metadata'}, :project_id => @project.id).all.size                                                                                                
    filename = args[:filepath].split("/").last

    h_metadata_types = {'CELL' => '1', 'GENE' => '2'}
    
    ## preparse
    
    h_fu = {
      :project_id => project.id,
      :project_key => project.key,
      :status => 'new',
      :upload_type => 2,
      :upload_file_name => filename,
      :upload_content_type => 'text/plain',
      :user_id => 1 #current_user.id
    }
    
    fu = Fu.new(h_fu)
    fu.save
    
    if fu
      
      delimiters = ["\n", "\t", " ", ";", ","]
      fu_dir = fus_dir + fu.id.to_s
      Dir.mkdir fu_dir
      new_filepath = fu_dir + filename
      FileUtils.cp args[:filepath], new_filepath #(fu_dir + filename)
      
      #  File.open(filepath, 'w') do |f|
      #      if args[:input_type_id] == '2'
      #        f.write(params[:content])
      #      elsif args[:input_type_id] == '1'
      #        f.write("genes\t#{params[:name]}\n")
      #        params[:content].split(/#{delimiters[params[:delimiter].to_i]}+/).each do |e|
      #          f.write("#{e}\t1\n")
      #        end
      #        end
      #      end
      if File.exist? new_filepath and File.size(new_filepath) > 0
        h_upd = {
          :status => 'written',
          :upload_file_size => File.size(new_filepath),
          :upload_updated_at => Time.now
        }
        
        fu.update_attributes(h_upd)
        #    fu.broadcast                                                                                                                                        
      end

      ##preparse
      options = ["-col first", "-header true"]
      cmd = "java -jar #{APP_CONFIG[:local_asap_run_dir]}/ASAP.jar -T PreparseMetadata #{options.join(" ")} -loom #{parsing_loom_file} -f \"#{new_filepath}\" -o #{fu_dir + 'output.json'} -which #{args[:metadata_type]} 2> #{fu_dir + 'output.err'}"
      `#{cmd}`
	puts cmd
    
      ## parse
      
      last_run =  Run.joins("join steps on (step_id = steps.id)").where(:steps => {:name => 'import_metadata'}, :project_id => project.id).order("num asc").last
      
      #      import_metadata_step = Step.where(:version_id => project.version_id, :name => 'import_metadata').first
      import_metadata_step = Step.where(:docker_image_id => asap_docker_image.id, :name => 'import_metadata').first 
      #     std_method = StdMethod.where(:version_id => project.version_id, :name => 'add_meta').first
      std_method = StdMethod.where(:docker_image_id => asap_docker_image.id, :name => 'add_meta').first
      
      h_run = {
        :project_id => project.id,
        :step_id => import_metadata_step.id,
        :std_method_id => std_method.id,
        :status_id => 6, #status_id, # set as running                                
        :num => (last_run) ? last_run.num + 1 : 1,
        :user_id => 1, #current_user.id,
        :command_json => {}, #h_cmd.to_json,                  
        :attrs_json => {}, #self.parsing_attrs_json,       
        :output_json => {}, #h_outputs.to_json,         
        :lineage_run_ids => '', #lineage_run_ids.join(","),        
        :submitted_at => Time.now
      }
      
      new_run = Run.new(h_run)
      new_run.save
      #input_filename = args[:filepath] #"tmp/import_metadata_#{new_run.id}"
      #input_filepath = project_dir + input_filename
      
      # fu = Fu.where(:id =>params[:fu_id]).first      

      
      upload_filename = fus_dir + fu.id.to_s + fu.upload_file_name
      #  File.symlink upload_filename, input_filepath
      
      #      h_res = Basic.safe_parse_json( File.read(fu_dir + params[:fu_id] + 'output.json'), {})                                                                
      #metadata_types = params[:metadata_types]
      h_attrs = {
        :input_run_ids => Run.joins(:step).where(:project_id => project.id, :steps => {:name => ['parsing', 'cell_filtering', 'gene_filtering']}).all.map{|r| r.id}.join(","), # to be defined when the job is executed or then prevent creating new filtering if an import metadata is pending or running              
        #:file_type => h_res['detected_format'],                                                
        # :ori_filename => input_filename,                          
        :ori_filename => fu.upload_file_name,
        :input_filename => filename, #Basic.relative_path(@project, input_filename),                  
        :metadata_type_id => h_metadata_types[args[:metadata_type]],
        :fu_id => fu.id.to_s,
        #:input_filepath => input_filepath,
        #:metadata_types => metadata_types.join(","),
        #:assign_metadata => params[:assign_metadata]
      }
      
      h_command = {
        :program => "rake parse_metadata[#{new_run.id}]",
        :host_name => "localhost",
        :opts => [],
        :args => []
      }
      
      new_run.update_attributes({:status_id => 1, :command_json => h_command.to_json, :attrs_json => h_attrs.to_json})
      
      #run_dir = metadata_dir + new_run.id.to_s                                                                                                              
      #Dir.mkdir(run_dir) if !File.exist? run_dir                                                                                                            
    end
    
#  end
  
end
