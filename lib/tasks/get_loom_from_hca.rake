desc '####################### Get loom from HCA'
task :get_loom_from_hca, [:project_key] => [:environment] do  |t, args|
  
  require 'net/http'
  require 'net/https'
  require 'mechanize'
  puts 'Executing...'
  
  start_time = Time.now
 
  fu_dir = Pathname.new(APP_CONFIG[:upload_data_dir])
 
  p = Project.where(:key => args[:project_key]).first
 
  project_dir = Pathname.new(APP_CONFIG[:user_data_dir]) + p.user_id.to_s + p.key
  h_attrs = JSON.parse(p.parsing_attrs_json)
  puts h_attrs.to_json
  post_url = "https://matrix.data.humancellatlas.org/v0/matrix"

  output_json_file = File.open(project_dir + 'parsing' + 'get_loom_from_hca.json', "w")
  h_output= {}

  version = p.version
  asap_docker_image = Basic.get_asap_docker(version)
  # parsing_step = Step.where(:version_id => p.version_id, :name => 'parsing').first
  parsing_step = Step.where(:docker_image_id => asap_docker_image.id, :name => 'parsing').first   
  
  if h_attrs['provider_project_id'] and h_attrs['provider_project_id']!=''
    
#    matrix_location = "https://data.humancellatlas.org/project-assets/project-matrices/#{h_attrs['provider_project_id']}.loom"
#    matrix_location = "https://service.azul.data.humancellatlas.org/repository/files/#{h_attrs['provider_project_filekey']}"
    matrix_location = h_attrs['provider_project_fileurl']
    #   id | project_id | upload_type | name | status | upload_file_name | upload_content_type | upload_file_size |   
    #   upload_updated_at | visible | created_at | updated_at | project_key | user_id | url                                
    h_fu = {
      :project_id => p.id,
      :status => 'new',
      :upload_type => 1,
      :upload_file_name => "HCA_" + h_attrs['provider_project_filename'] + ".loom",
      :url => matrix_location
    }
    
    fu = Fu.new(h_fu)
    puts h_fu.to_json
    fu.save!
    
    puts "next"
    input_file = fu_dir + fu.id.to_s + fu.upload_file_name 
    
    ### create directory if it doesn't exist yet
    Dir.mkdir(fu_dir + fu.id.to_s) if !File.exist?(fu_dir + fu.id.to_s)
    ### delete file if it exists
    File.delete(input_file) if File.exist? input_file
    ### download file 
    cmd = "wget -O #{input_file} '#{matrix_location}'"
    puts "Downloading..."
    puts cmd
    `#{cmd}`
    
    ### delete symlink in project if it exists
    File.delete project_dir + 'input.loom' if File.exist? project_dir + 'input.loom'
    ### create symlink in project
    File.symlink input_file, project_dir + 'input.loom'
    
    ### update fu with file size
    fu.update_attributes({:status => 'downloaded', :upload_file_size => File.size(input_file)})
    
  end
  
  ### preparse file and update ncells et ngenes in the attributes
  if input_file and File.exist? input_file and File.size(input_file) > 0
    
    cmd = "java -jar lib/ASAP.jar -T Preparsing -sel 'matrix' -organism #{p.organism_id} -f #{input_file} -o #{fu_dir + fu.id.to_s} 2>&1 > #{fu_dir + fu.id.to_s + 'preparsing.log'}"
    `#{cmd}`  
    puts cmd
        
    ### get results
    preparsing_output_json_file = fu_dir + fu.id.to_s + "output.json"
    h_params = JSON.parse(File.read(preparsing_output_json_file))
    
    if h_params["displayed_error"]
      
      h_output[:error] = h_params["displayed_error"]
      h_output[:status_id] = 4
    else
      
      h_output = h_params
      h_output[:status_id] = 3

      puts h_params.to_json
      puts h_params['list_groups'][0]['nber_cols'];
      puts h_params['list_groups'][0]['nber_rows'];
      
      ### update project attributes
      #    ['nb_cells', 'nb_genes'].each do |k|
#      h_attrs['nber_cols']=h_params['list_groups'][0]['nb_cells']
#      h_attrs['nber_rows']=h_params['list_groups'][0]['nb_genes']
      h_attrs['nber_cols']=h_params['list_groups'][0]['nber_cols']   
      h_attrs['nber_rows']=h_params['list_groups'][0]['nber_rows']       

      ## predict parsing time
      puts parsing_step.to_json                                                                                                                                                                                                         
      std_method = StdMethod.where(:step_id => parsing_step.id).first
      puts std_method.to_json
      docker_name = asap_docker_image.full_name
      asap_docker_version = nil
      if m = asap_docker_image.tag.match(/v(\d+)/)
        asap_docker_version = m[1]
      end

#      cmd = "docker run --entrypoint '/bin/sh' --rm -v /data/asap2:/data/asap2 -v /srv/asap_run/srv:/srv fabdavid/asap_run:v#{p.version_id} -c 'Rscript prediction.tool.2.R predict /data/asap2/pred_models/#{p.version_id} #{std_method.id} #{h_attrs['nber_rows']} #{h_attrs['nber_cols']} 2>&1'"

      cmd = "docker run --entrypoint '/bin/sh' --rm -v /data/asap2:/data/asap2 -v /srv/asap_run/srv:/srv #{docker_name} -c 'Rscript prediction.tool.2.R predict /data/asap2/pred_models/#{asap_docker_version} #{std_method.id} #{h_attrs['nber_rows']} #{h_attrs['nber_cols']} 2>&1'"
      puts "PRED_CMD: #{cmd}"
      pred_results_json = `#{cmd}`.split("\n").first #.gsub(/^(\{.+?\})/, "\1")                                                                                                                                                      
      h_pred_results = Basic.safe_parse_json(pred_results_json, {})
      h_params['list_groups'][0]['pred_max_ram'] =  (h_pred_results['predicted_ram'] == 'NA') ? '' : h_pred_results['predicted_ram']
      h_params['list_groups'][0]['pred_process_duration'] = (h_pred_results['predicted_time'] == 'NA') ? '' : h_pred_results['predicted_time']
      
      ## rewrite output.json
      File.open(preparsing_output_json_file, 'w') do |fw|
        fw.write(h_params.to_json)
      end
      #            h_pred_results = Basic.safe_parse_json(pred_results_json, {})                                                                                                                                                      
      
    #  @current_dataset['detected_format'] = @h_json['detected_format']
    #  @current_dataset['pred_max_ram'] = (h_pred_results['predicted_ram'] == 'NA') ? '' : h_pred_results['predicted_ram']
    #  @current_dataset['pred_process_duration'] = (h_pred_results['predicted_time'] == 'NA') ? '' : h_pred_results['predicted_time']

      
      # h_attrs[k]=h_params[k]
      #    end	     
      p.update_attributes({:nber_cols => h_attrs['nber_cols'], :nber_rows => h_attrs['nber_rows'], :parsing_attrs_json => h_attrs.to_json})
      
      # update attrs_json of the run
      run = Run.where(:project_id => p.id, :step_id => parsing_step.id).first
      h_run_attrs = Basic.safe_parse_json(run.attrs_json, {})
      h_run_attrs['nber_cols'] = h_attrs['nber_cols']
      h_run_attrs['nber_rows'] = h_attrs['nber_rows']
      run.update_attributes({:attrs_json => h_run_attrs.to_json})

      # load HCA metadata if found

      a = Mechanize.new { |agent|
        agent.user_agent_alias = 'Mac Safari'
      }
      
      #      project_url = "https://data.humancellatlas.org/explore/projects/" + h_attrs['provider_project_id'] + "/project-metadata"
      #      puts "Add metadata..."
      #      puts project_url
      #      html = `wget -O - '#{project_url}'`
      #      puts html
      #      metadata_link = nil
      #      if m = html.match(/(https:\/\/service\.azul\.data\.humancellatlas\.org\/manifest\/files.+?\.tsv)"/)
      #        metadata_link = m[1]
      #      end  
      
      metadata_link = nil
      url = "https://service.azul.data.humancellatlas.org/fetch/manifest/files?catalog=dcp13&filters=%7B%22projectId%22:%7B%22is%22:%5B%22#{h_attrs['provider_project_id']}%22%5D%7D%7D&format=compact"
      json = `wget -O - "#{url}"`
      h_json = Basic.safe_parse_json(json, {})
      puts h_json['Location'].to_json
      metadata_list_filepath = project_dir + 'tmp' + 'hca_list_metadata.tsv'
      cmd = "wget -O \"#{metadata_list_filepath}\" \"#{h_json['Location']}\""
      puts cmd
      `#{cmd}`
      ## identify the csv files and import each of them
      options = ["-header true", "-col first", '-d ","']
      File.open(metadata_list_filepath, "r") do |f|
        while(l= f.gets) do
          t = l.chomp.split("\t")
          if t[7] == 'csv'
            ## get file 
            csv_filename = t[6]
            metadata_filepath =  project_dir + 'tmp' + 'hca_metadata.csv'
            cmd = "wget -O \"#{metadata_filepath}\" \"#{t[16]}\""
	    puts cmd 
	    `#{cmd}`
	    ## replace first line
            header = `head -1  #{metadata_filepath}`
            t_header = header.chomp.split(",")
puts t_header.to_json
            if t_header.size == 2 and t_header[1] == '"x"'
              metadata_name = csv_filename.gsub(/\.csv$/, '')
              new_header = "cell,#{metadata_name}"
              cmd = "sed -i \"1s/.*/#{new_header}/\" #{metadata_filepath}"
              puts cmd
              `#{cmd}`
              cmd = "sed -i \"s/\\\"//g\" #{metadata_filepath}"              
              puts cmd
              `#{cmd}`
#              cmd = "sed -i \"s/[ATGC]+[^,]*//g\" #{metadata_filepath}"
#              puts cmd
#              `#{cmd}`


            end
            # import metadata
            cmd = "java -jar lib/ASAP.jar -T ParseMetadata -which CELL -type RAW_TEXT -loom #{project_dir + 'input.loom'} -f #{metadata_filepath} -o #{project_dir + 'tmp' + 'output_parse_hca_metadata.json'} #{options.join(' ')}"
            puts cmd       
	    `#{cmd}`
          end
        end
      end				
          # options.push("-metadataType #{h_attrs['metadata_types']}") if h_attrs['metadata_types']
      # options.push("-removeAmbiguous") if h_attrs['assign_metadata'] == '0'
      
    
      #        puts "META_LINK: " + metadata_link + "--"
      #	metadata_filepath = project_dir + 'tmp' + 'hca_metadata.tsv'
      #      `wget -O #{metadata_filepath} '#{metadata_link}'`
      #      a.get(project_url) do |page|
      #      puts page.body
      #        search_result = page.form_with(:id => 'gbqf') do |search|
      #          search.q = 'Hello world'
      #        end.submit
      #        
      #        search_result.links.each do |link|
      #          puts link.text
      #        end
      #      end
      
    end
  else 
    h_output[:status_id] = 4
    h_output[:error] = "Download of Loom file from HCA failed."
  end

  h_output['get_loom_time']= Time.now - start_time
  
  puts "H_OUTPUT:" + h_output.to_json
  output_json_file.write(h_output.to_json)
  
  #  case res
  #  when Net::HTTPSuccess, Net::HTTPRedirection
  #    # OK
  #  else
  #    res.value
  #  end
  
end

#    if p['sel_provider_projects']
#      post_url = "https://matrix.staging.data.humancellatlas.org/v0/matrix"
#      ### initialize mechanize agent                                                                                                                  
#      agent = Mechanize.new { |agent|
#        agent.user_agent_alias = 'Mac Safari'
#      }
#      h_p = {
#        :bundle_fqids_url => "https://service.staging.explore.data.humancellatlas.org/manifest/files?filters=#{p['sel_provider_projects']}&format=tarball",
#        :format => "loom"
#        #%7B%22file%22%3A%7B%22project%22%3A%7B%22is%22%3A%5B%22Single+cell+RNAseq+characterization+of+cell+types+produced+over+time+in+an+in+vitro+model+of+human+inhibit#ory+interneuron+differentiation.%22%2C%22Single+cell+transcriptome+analysis+of+human+pancreas%22%5D%7D%2C%22biologicalSex%22%3A%7B%22is%22%3A%5B%22male%22%5D%7D%2C%22fileFormat%22%3A%7B%22is%22%3A%5B%22matrix%22%5D%7D%7D%7D&format=tarball                        
#      }
#      h_headers = {
#        "Content-Type" => "application/json"
#      }
#      agent.post post_url, h_p, h_headers
#    end
#
#
#end
