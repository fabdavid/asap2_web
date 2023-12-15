desc '####################### Parse'
task :parse, [:project_key] => [:environment] do |t, args|
  puts 'Executing...'
  
  now = Time.now
  logger = Logger.new("log/exec_run.log")
  puts args[:project_key]

  project_key = args[:project_key]  
  project = Project.where(:key => project_key).first
  version = project.version
  h_env = JSON.parse(version.env_json)

  asap_docker_image = Basic.get_asap_docker(version)

# puts h_env.to_json
#exit

  db_conn = "postgres:5434/asap2_data_v" + h_env['asap_data_db_version'].to_s #project.version_id.to_s 
  
  project_dir = Pathname.new(APP_CONFIG[:user_data_dir]) + project.user_id.to_s + project.key	
  tmp_dir = project_dir + 'parsing'
  Dir.mkdir(tmp_dir) if !File.exist?(tmp_dir)

#  parsing_step = Step.where(:version_id => project.version_id, :name => 'parsing').first
  puts "ASAP_DOCKER_IMAGE_ID:" + asap_docker_image.id.to_s
  parsing_step = Step.where(:docker_image_id => asap_docker_image.id, :name => 'parsing').first
  run = Run.where(:project_id => project.id, :step_id => parsing_step.id).first
  
  h_data_types = {}
  DataType.all.map{|dt| h_data_types[dt.name] = dt}
  
  h_data_classes = {}
  DataClass.all.map{|dt| h_data_classes[dt.name] = dt; h_data_classes[dt.id] = dt}
  
#  f_log = File.open("./log/delayed_job_parsing2.log", "w")

#   exit

  if project
    puts "parse"
  
    p = JSON.parse(project.parsing_attrs_json) if project.parsing_attrs_json

    output_json_file = project_dir + 'parsing' + "output.json"
    
    filepath = project_dir + ("input." + project.extension)
    
    
    ### write file from hca                                                                                                                                                                      
    h_output_hca = nil
    # if p['sel_provider_projects'] and p['sel_provider_projects'] != '{}'                                                                                                                                 
    if p['provider_project_id'] and p['provider_project_id'] != ''      
#      start_download_hca = Time.now
      cmd = "rails get_loom_from_hca[#{project.key}] 2>&1 > #{tmp_dir + 'get_loom_from_hca.log'}"
      `#{cmd}`
      #      f_log.write("CMDx: " + cmd)
      puts "CMDx: " + cmd
      hca_output_json_file = project_dir + 'parsing' + "get_loom_from_hca.json"
      if File.exist? hca_output_json_file
        h_output_hca = JSON.parse(File.read(hca_output_json_file))
      else
        h_output_hca = {'status_id' => 4, 'error' => 'An error occured while getting Loom file from HCA'}
      end

      ### download json
      
      #h_hca[:projects]['hits'].map{|e| e['projects'].map{|e2| e2.keys}}.to_json #"arrayExpressAccessions","geoSeriesAccessions","insdcProjectAccessions","insdcStudyAccessions","supplementaryLinks" 
      #h_q = {"fileFormat" => {"is" => ["matrix"]}}
      #q_txt = URI::encode(h_q.to_json)

      #url = "https://service.explore.data.humancellatlas.org/repository/projects?filters=#{q_txt}"
      #cmd = "wget -U 'Safari Mac' -q -O - '#{url}'"
      #puts "CMD: #{cmd}"
      #res = `#{cmd}`
      #puts "RES: " + res.to_json      
      #h_hca = JSON.parse(res) #Basic.safe_parse_json(res, {})
      #puts "HCA: #{h_hca.to_json}"
            
      #accession_types = ["arrayExpressAccessions", "geoSeriesAccessions"]    
      #h_accessions = {}
      #accession_types.each do |acc_type|
      #  h_accessions[acc_type] = []
      #end
      
      #if h_hca['hits']
      #  h_hca['hits'].each do |hit|
      #    if hit["entryId"] == p['provider_project_id']
      #      puts "entry: " + hit["projects"][0]["arrayExpressAccessions"].to_json #e['projects'][0].to_json
      #      accession_types.each do |k|
      #        if h_accessions[k] and hit["projects"][0][k]
      #          h_accessions[k] = hit["projects"][0][k]
      #        end
      #      end
      #    end
      #  end
      #end

      #puts "ACCESSIONS: " + h_accessions.to_json

      #Fetch.add_upd_exp_codes({
      #                          :project => project,
      #                          :geo_codes => h_accessions["geoSeriesAccessions"].join(", "),
      #                          :array_express_codes => h_accessions["arrayExpressAccessions"].join(", ")}
      #                        )      
      
    end

    
    puts h_output_hca.to_json


    
    if !h_output_hca or h_output_hca['status_id'] != 4

      ### update run with predictions
      fu = Fu.where(:project_id => project.id, :upload_type => 1).first
      upload_dir = Pathname.new(APP_CONFIG[:data_dir]) +  'fus' + fu.id.to_s
      output_file = upload_dir + "output.json"
      puts output_file
      h_preparsing = Basic.safe_parse_json(File.read(output_file), {})
      puts h_preparsing.to_json
      if list_group = h_preparsing['list_groups'][0]
        run.update_attributes({
                                :pred_max_ram => (list_group['pred_max_ram'] != '') ? list_group['pred_max_ram'] : nil, 
                                :pred_process_duration => (list_group['pred_process_duration']) ? list_group['pred_process_duration'] : nil
                              })
      end

       project.broadcast parsing_step.id	

      ### get parameters (potentially updated by get_loom_from_hca)                                                                                                                              
      #      puts "BLA"
      puts project.id

      project = Project.find(project.id)
      p = JSON.parse(project.parsing_attrs_json) if project.parsing_attrs_json
      #f_log.write("h_params2: " + p.to_json)	 
      puts "h_params2: " + p.to_json

      opts = []
      #      if !h_output_hca
      p['sel_name'] = 'mtx' if p["file_type"] == 'MEX'
      opts.push({'opt' => "-sel", 'value' => p['sel_name']}) if p['sel_name'] 
      opts.push({'opt' => "-col", 'value' => p["gene_name_col"]}) if p["gene_name_col"]
      opts.push({'opt' => "-d", 'value' => p["delimiter"]}) if p["delimiter"] and p['delimiter'] != ''
      opts.push({'opt' => "-header", 'value' => ((p['has_header'] and p['has_header'].to_i == 1) ? 'true' : 'false')}) if  p['has_header']
      opts.push({'opt' => '--row-names', 'value' => p['rowname_metadata']}) if p['rowname_metadata']
      opts.push({'opt' => '--col-names', 'value' => p['colname_metadata']}) if p['colname_metadata']
      #      end
      opts += [
               {'opt' => "-ncells", 'value' => p["nber_cols"]},
               {'opt' => "-ngenes", 'value' => p["nber_rows"]},
               {'opt' => "-type", 'value' => (p["file_type"] == 'MEX') ? "H5_10x" : p["file_type"]},
               #  {:opt => "-project_key", 'value' => project.key},
               #  {:opt => "-step_id", 'value' => 1},
               {'opt' => '-T', 'value' => "Parsing"},
               {'opt' => "-organism", 'value' => project.organism_id},
               {'opt' => "-o", 'value' => tmp_dir},
               {'opt' => "-f", 'value' => filepath},
               {'opt' => '-h', 'value' => db_conn}
              ]
      
      mem = p["nber_cols"].to_i * p["nber_rows"].to_i * 128 / (31053 * 1474560) # project sample = gi6qfz                                                                                        
      h_env_docker_image = h_env['docker_images']['asap_run']
      image_name = h_env_docker_image['name'] + ":" + h_env_docker_image['tag']
            
      h_cmd_parse = {
        'host_name' => "localhost",
        	         'time_call' => h_env["time_call"].gsub(/\#output_dir/, tmp_dir.to_s),
        'container_name' => APP_CONFIG[:asap_instance_name] + "_" + run.id.to_s,
        'docker_call' => h_env_docker_image['call'].gsub(/\#image_name/, image_name),
        'program' => "java -jar ASAP.jar",  #(mem > 10) ? "java -Xms#{mem}g -Xmx#{mem}g -jar /srv/ASAP.jar" : 'java -jar /srv/ASAP.jar',                      
        'opts' => opts,
        'args' => []
      }

      output_file = tmp_dir + "output.loom"
      output_json = tmp_dir + "output.json"

      puts h_cmd_parse
      cmd_parse = Basic.build_cmd(h_cmd_parse)
      puts "CMD_JAVA:" + cmd_parse      
      `#{cmd_parse}`
      h_parsing = Basic.safe_parse_json(File.read(output_json), {})
      if  p["file_type"] == 'MEX'
        h_parsing['detected_format'] = 'MEX'
        File.open(output_json, 'w') do |fw|
          fw.write(h_parsing.to_json)
        end
      end

      ## 
      puts "Define project cell set"
      Basic.upd_project_cell_set(project)
      puts "=> " + project.project_cell_set.key

      h_parsing_metadata = {}
      puts h_parsing.to_json
      if h_parsing['metadata']
        h_parsing['metadata'].each do |meta|
          h_parsing_metadata[meta['name']] = 1
        end
      end
      fu = Fu.where(:project_id => project.id, :upload_type => 1).first
      upload_dir = Pathname.new(APP_CONFIG[:data_dir]) +  'fus' + fu.id.to_s
      output_file = upload_dir + "output.json"
     # output_path = project_dir + "parsing" + "output.#{project.extension}"
      output_path = project_dir + "parsing" + "output.loom"
      ori_fu_path = Pathname.new(APP_CONFIG[:upload_data_dir]) + fu.id.to_s + fu.upload_file_name
      # f_log.write(ori_fu_path)
      puts ori_fu_path
      h_preparsing = Basic.safe_parse_json(File.read(output_file), {})
      # f_log.write(h_preparsing.to_json)
      puts h_preparsing.to_json
      puts "bla"
      if h_preparsing["detected_format"] == "H5AD" #and h_preparsing["list_groups"][0]["metadata"]
        list_metadata = h_parsing["existing_metadata"].select{|e| !h_parsing_metadata[e]}
        if list_metadata
#puts "output_path: " + output_path.to_s
          relative_filepath = Basic.relative_path(project, output_path)
          list_metadata.each do |meta|
            meta['imported'] = true
            puts "add annot #{meta.to_json}"
            Basic.load_annot(run, meta, relative_filepath, h_data_types, h_data_classes, logger)
          end
        end
        
      elsif h_preparsing["detected_format"] == "LOOM" and h_preparsing["list_groups"][0]["existing_metadata"]
        puts "bou"
        h_meta = {:meta => h_preparsing["list_groups"][0]["existing_metadata"].select{|e| !h_parsing_metadata[e]}}
        metadata_list_file = tmp_dir + 'list_metadata_to_copy.json'
        File.open(metadata_list_file, 'w') do |f|
          f.write(h_meta.to_json)
        end
        cmd = "java -jar lib/ASAP.jar -T CopyMetaData -loomFrom \"#{ori_fu_path}\" -loomTo #{output_path} -metaJSON #{metadata_list_file}"
        puts cmd
        output = `#{cmd}`
	metadata_list_file2 = tmp_dir + 'list_metadata_to_copy2.json'
        File.open(metadata_list_file2, 'w') do |f|
          f.write(output)
        end
        cmd = "java -jar lib/ASAP.jar -T ExtractMetadata -no-values -loom #{output_path} -metaJSON #{metadata_list_file2}"
	puts cmd
        output = `#{cmd}`
        h_res = Basic.safe_parse_json(output, {})
	puts output 
	puts h_res.to_json
	if list_metadata = h_res['list_meta'] 
	
          relative_filepath = Basic.relative_path(project, output_path)
          list_metadata.each do |meta|
            meta['imported'] = true
	    puts "add annot #{meta.to_json}" 
            Basic.load_annot(run, meta, relative_filepath, h_data_types, h_data_classes, logger)
          end
        end
        #h_preparsing["list_groups"][0]["existing_metadata"].each do |annot_name|
        #  cmd = "java -jar lib/ASAP.jar -T CopyMetaData -loomFrom #{ori_fu_path} -loomTo #{output_path} -meta #{annot_name}"
	#  puts "#{cmd}"
        #  output = `#{cmd}`
        #  puts "OUTPUT!!! #{output}"
        #end        
      end


      ## add run for find_markers
    #  project_dir = Pathname.new(APP_CONFIG[:user_data_dir]) + @project.user_id.to_s + @project.key
      #    fu_dir = Pathname.new(APP_CONFIG[:data_dir]) + 'fus'
      # total_nber_operations = Run.joins("join steps on (step_id = steps.id)").where(:steps => {:name => 'import_metadata'}, :project_id => @project.id).all.size                                                              
#      last_run =  Run.joins("join steps on (step_id = steps.id)").where(:steps => {:name => 'import_metadata'}, :project_id => @project.id).order("num asc").last

       # the following was moves to Basic.load_annot
#      if project.user_id == 1 and project.sandbox == false
#        
#        cell_metadata = project.annots.select{|a| a.data_type_id ==3 and a.dim == 1}
#        cell_metadata.each do |meta|
#          Basic.find_markers(logger, project, meta, run.user_id)
#        end
#      end

    else

      h_output = {"displayed_error" => ["Error retrieving data from HCA", h_output_hca["error"]]}
            
      ##write HCA error in output.json                                                                                                                                                           
      File.open(output_json_file, 'w') do |f|
        f.write h_output.to_json
      end
      
      # f_log.write("k1")
      # h_outputs = {:output_json => { "parsing/output.json" => {:types => ["json_file"]}}}
       
    end
    
  end
end
