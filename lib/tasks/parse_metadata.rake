desc '####################### Parse metadata'
task :parse_metadata, [:run_id] => [:environment] do |t, args|
  puts 'Executing...'

  now = Time.now
 logger = Logger.new("log/exec_run.log")

  puts args[:run_id]

  run = Run.where(:id => args[:run_id]).first
  project = run.project
  version = project.version
  h_env = JSON.parse(version.env_json)
  asap_docker_image = Basic.get_asap_docker(version)

  db_conn = "postgres:5434/asap2_data_v" + project.version_id.to_s

  
  project_dir = Pathname.new(APP_CONFIG[:user_data_dir]) + project.user_id.to_s + project.key
  output_dir = project_dir + 'import_metadata'
  Dir.mkdir(output_dir) if !File.exist?(output_dir)
  output_dir += run.id.to_s
  Dir.mkdir(output_dir) if !File.exist?(output_dir)

  tmp_dir = project_dir + 'tmp'
  Dir.mkdir(tmp_dir) if !File.exist?(tmp_dir)
  
  h_steps = {}
#  Step.where(:version_id => project.version_id).all.map{|s| h_steps[s.id] = s}
 Step.where(:docker_image_id => asap_docker_image.id).all.map{|s| h_steps[s.id] = s}

  h_data_types = {}
  DataType.all.map{|dt| h_data_types[dt.name] = dt;}
  
  h_metadata_types = {
  '1' => 'CELL',
  '2' => 'GENE' 
  }

  h_data_classes = {}
  DataClass.all.map{|dt| h_data_classes[dt.name] = dt; h_data_classes[dt.id] = dt}

  h_attrs = Basic.safe_parse_json(run.attrs_json, {})

  fu_dir =  Pathname.new(APP_CONFIG[:data_dir]) + 'fus'
  h_res = Basic.safe_parse_json( File.read(fu_dir + h_attrs['fu_id'] + 'output.json'), {})

  #  input_runs = Run.where(:id => h_attrs['input_run_ids'].split(",")).all
  matrices = Annot.where(:run_id => h_attrs['input_run_ids'].split(","), :dim => 3).all
  puts "STEP_IDs: " +  matrices.map{|mat| mat.step_id.to_json}.join(",")
  puts "STEP: " +  h_steps.to_json
  parsing_mat = matrices.select{|mat| h_steps[mat.step_id].name == 'parsing'}.first
  parsing_loom_file = project_dir + parsing_mat.filepath
  options = ["-header true", "-col first"]
  options.push("-metadataType #{h_attrs['metadata_types']}") if h_attrs['metadata_types']
  options.push("-removeAmbiguous") if h_attrs['assign_metadata'] == '0'
  cmd = "java -jar lib/ASAP.jar -T ParseMetadata -which #{h_metadata_types[h_attrs['metadata_type_id']]} -type #{h_res['detected_format']} -loom #{parsing_loom_file} -f #{fu_dir + h_attrs['fu_id'] + h_attrs['input_filename']} -o #{output_dir + 'output.json'} #{options.join(' ')}"
  puts "CMD PARSE_METADATA: " + cmd
  `#{cmd}`
  
  output_json = File.read(output_dir + 'output.json')
  #  outputs.push output_json
  h_output = Basic.safe_parse_json(output_json, {})
  displayed_error = h_output['displayed_error']
  h_output['displayed_error']=[displayed_error] if displayed_error
  File.open(output_dir + 'output.json', 'w') do |fw|
    fw.write(h_output.to_json)
  end
  
  if list_metadata = h_output['metadata']
    list_metadata.each do |meta|
      meta['imported'] = true
      puts "add annot #{meta.to_json}"
      Basic.load_annot(run, meta, parsing_mat.filepath, h_data_types, h_data_classes, logger)
    end
    
    puts "bou"
    h_meta = {:meta => h_output['metadata'].map{|e| e['name']}}
    metadata_list_file = output_dir + 'list_metadata_to_copy.json'
    File.open(metadata_list_file, 'w') do |f|
      f.write(h_meta.to_json)
    end
  
    other_matrices = matrices - [parsing_mat]
    
    outputs = []
    
    other_matrices.each do |mat| # foreach expression matrix
      
      loom_file = project_dir + mat.filepath    
      options = []
      #:metadata_types => params[:opt][:metadata_types].join(","),
      #  :assign_metadata => params[:assign_metadata]
      
      #    options.push("-metadataType #{h_attrs['metadata_types']}") if h_attrs['metadata_types']
      #    options.push("-removeAmbiguous") if h_attrs['assign_metadata'] == '0'
      #    cmd = "java -jar ASAP.jar -T ParseMetadata -loom #{loom_file} -f #{h_attrs['input_filename']} -o #{output_dir} #{options.join(' ')}"
      #    puts "CMD PARSE_METADATA: " + cmd
      #    `#{cmd}`
      
      #    output_json = File.read(output_dir + 'output.json')
      #    outputs.push output_json
      #    h_output = Basic.safe_parse_json(output_json, {})
      
      #    if list_metadata = h_res['metadata']      
      #      list_metadata.each do |meta|
      #        meta['imported'] = true
      #        puts "add annot #{meta.to_json}"
      #        Basic.load_annot(run, meta, mat.filepath, h_data_types, h_data_classes, logger)
      #      end
      #    end
      loom_from = project_dir + parsing_mat.filepath
      loom_to = project_dir + mat.filepath
      cmd = "java -jar lib/ASAP.jar -T CopyMetaData -loomFrom \"#{loom_from}\" -loomTo #{loom_to} -metaJSON #{metadata_list_file}"
      puts cmd
      output = `#{cmd}`
      puts output
      metadata_list_file2 = output_dir + "list_metadata_to_copy2_#{mat.run_id}.json"
      File.open(metadata_list_file2, 'w') do |f|
        f.write(output)
      end
      
      cmd = "java -jar lib/ASAP.jar -T ExtractMetadata -no-values -loom #{loom_to} -metaJSON #{metadata_list_file2}"
      puts cmd
      output = `#{cmd}`
      outputs.push(output)
      h_res = Basic.safe_parse_json(output, {})
      puts output
      puts h_res.to_json
      if list_metadata = h_res['list_meta']
        #relative_filepath = Basic.relative_path(project, output_path)
        list_metadata.each do |meta|
          meta['imported'] = true
#          meta['type'] = nil
          puts "add annot #{meta.to_json}"
          Basic.load_annot(run, meta, mat.filepath, h_data_types, h_data_classes, logger)
        end
      end
    end
  end

  if outputs
    File.open(output_dir + "all_outputs.json", 'w') do |fw|
      fw.write "[" + outputs.join(", \n") + "]"
    end
  end

end			 
