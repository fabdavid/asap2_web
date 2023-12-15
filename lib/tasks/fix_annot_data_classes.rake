desc '####################### Fix annots data_classes'
task fix_annot_data_classes: :environment do
  puts 'Executing...'

  now = Time.now
   logger = Logger.new("log/exec_run.log")

  parsing_step = Step.find_by_name('parsing')
  h_outputs = Basic.safe_parse_json(parsing_step.output_json, {})
  tmp_dir = '/data/asap2/tmp/' 
  h_steps = {}
  h_expected_outputs = {}
  h_data_class_names_by_annot_name = {}
  Step.all.map{|s| 
    h_steps[s.id] = s
    h_expected_outputs[s.id] = Basic.safe_parse_json(s.output_json, {})['expected_outputs']
     h_data_class_names_by_annot_name[s.id]={}
    if h_expected_outputs[s.id]
      puts "#{s.id}: " + h_expected_outputs[s.id].to_json #h_expected_outputs[s.id].keys.select{|k| h_expected_outputs[s.id][k]['types']}.map{|k| "#{k} => " + h_expected_outputs[s.id][k]['types'].join(",")}.join("\n")
      h_expected_outputs[s.id].each_key do |k|
        annot_name = h_expected_outputs[s.id][k]["dataset"]
        h_data_class_names_by_annot_name[s.id][annot_name] = h_expected_outputs[s.id][k]["types"] if annot_name
      end				
    end
  }

  h_data_classes = {}
  DataClass.all.map{|dc| h_data_classes[dc.name] = dc}

  h_data_types = {}
  DataType.all.map{|dt| h_data_types[dt.name] = dt}

  h_std_methods = {}
  StdMethod.all.map{|s| h_std_methods[s.id] = s}  

  Project.where(:id => [7637, 7663]).order("id desc").all.select{|p| p.annots.map{|a| a.data_class_ids == '' or !a.data_class_ids}.size > 0}.each do |p|
#  Project.where(:id => 7663).order("id desc").all.each do |p|
    puts "Project #{p.key}..."    
    
    #    while([2, 3].include? p.archive_status_id)
    #      p = Project.find(p.id)
    #      sleep 10
    #    end
    
    if p.archive_status_id == 3
      p.unarchive
    end
    
    h_tmp_data_class_names = h_data_class_names_by_annot_name.dup
    
    h_runs = {}
    p.runs.map{|r| h_runs[r.id] = r}

    ### get list of imported metadata
    project_dir = Pathname.new(APP_CONFIG[:user_data_dir]) + p.user_id.to_s + p.key    
    parsing_dir = project_dir + 'parsing'
    
    ### potentially add /attrs/LOOM_SPEC_VERSION if missing for parsing
    loom_spec_versions = Annot.where(:project_id => p.id, :name => '/attrs/LOOM_SPEC_VERSION').all 
    parsing_step = Step.where(:version_id => p.version_id, :name => 'parsing').first
    parsing_run = Run.where(:project_id => p.id, :step_id => parsing_step.id).first
    count_loom_spec_version_parsing = Annot.where(:project_id => p.id, :step_id => parsing_step.id, :name => '/attrs/LOOM_SPEC_VERSION').count
    first_loom_spec_version = loom_spec_versions.first 	      
    if first_loom_spec_version and count_loom_spec_version_parsing == 0
      puts "Missing /attrs/LOOM_SPEC_VERSION!" 
      parsing_loom_spec_version = first_loom_spec_version.attributes
      parsing_loom_spec_version[:step_id] = parsing_step.id
      parsing_loom_spec_version[:run_id] = parsing_run.id
      parsing_loom_spec_version[:filepath] = "parsing/output.loom"
      parsing_loom_spec_version[:data_class_ids] = "11"
      parsing_loom_spec_version[:data_type_id] = 4
      parsing_loom_spec_version[:imported] = false
      #      h_annot = {
      #        :project_id => p.id,
      #        :step_id => parsing_step.id,
      #        :run_id => parsing_run.id,
      #        :store_run_id => parsing_run.id,
      #        :filepath => "parsing/output.loom",
      #        :data_type_id => 4
      #      }
      parsing_loom_spec_version[:id]=nil
      new_annot = Annot.new(parsing_loom_spec_version)
      puts new_annot.to_json
#      exit
      new_annot.save
      loom_spec_versions.update_all({:data_type_id => 4, :data_class_ids => "11", :imported => false})
    end
    
    ### add imported annots if missing 
    if p.extension == 'loom'
      puts "LOOM file"
      fu = Fu.where(:id => p.fu_id).first
      if fu
        upload_dir = Pathname.new(APP_CONFIG[:data_dir]) +  'fus' + fu.id.to_s
        output_file = upload_dir + "output.json"
        output_path = project_dir + "parsing" + "output.#{p.extension}"
        ori_fu_path = Pathname.new(APP_CONFIG[:upload_data_dir]) + fu.id.to_s + fu.upload_file_name
        
        output_json =  project_dir + 'parsing' + 'output.json'
        h_parsing = Basic.safe_parse_json(File.read(output_json), {})
        h_parsing_metadata = {}
        puts h_parsing.to_json
        h_parsing['metadata'].each do |meta|
          h_parsing_metadata[meta['name']] = 1
        end
        
        puts ori_fu_path
        if File.exist? output_file
          h_preparsing = Basic.safe_parse_json(File.read(output_file), {}) 
          puts h_preparsing.to_json
          puts "bla"
          if h_preparsing["detected_format"] == "LOOM" and h_preparsing["list_groups"][0]["existing_metadata"]
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
	    puts output
            h_res = Basic.safe_parse_json(output, {})
            if list_metadata = h_res['list_meta']
              relative_filepath = Basic.relative_path(p, output_path)
              list_metadata.each do |meta|
                meta['imported'] = true
                Basic.load_annot(parsing_run, meta, relative_filepath, h_data_types, h_data_classes, logger)
              end
            end
          end
        end
      end
    else
      puts "File #{output_file} doesn't exist"      
    end

    ## fix parsing_annots
    # p.annots.each do |a| #select{|a| h_steps[a.step_id].name == 'parsing'}.each do |a|
    p.annots.select{|a| a.data_class_ids == nil or a.data_class_ids == ''}.each do |a|
      
      h_var = {
        'run_num' => h_runs[a.run_id].num,
        'std_method_name' => h_std_methods[h_runs[a.run_id].std_method_id].name,
        'step_tag' => h_steps[a.step_id].tag
      }
      h_attrs = Basic.safe_parse_json(h_runs[a.run_id].attrs_json, {})
      h_attrs.each_key do |k|
        h_var[k] = h_attrs[k]
      end
      h_new_data_class_names = {}
      h_tmp_data_class_names[a.step_id].each_key do |k|
        new_k = k
        h_var.each_key do |k2|
          #          puts "new_k: " + new_k.to_json
          #          puts "k2: " + k2.to_s + " => " + h_var[k2].to_s
          new_k = new_k.gsub(/\#\{#{k2.to_s}\}/, h_var[k2].to_s) if h_var[k2]
          #	  puts "new_k: " + new_k.to_json
        end
        if new_k == a.name
          h_new_data_class_names[new_k] = h_tmp_data_class_names[a.step_id][k]
        end
      end
      h_new_data_class_names.each_key do |k|
        h_tmp_data_class_names[a.step_id][k] = h_new_data_class_names[k]
      end

      #      puts "Annot: " + a.name + " : " + a.step_id.to_s
      h_annot = {}
      if h_tmp_data_class_names[a.step_id][a.name]
        puts "#{a.name} => #{h_tmp_data_class_names[a.step_id][a.name]}"
        h_annot[:data_class_ids] = h_tmp_data_class_names[a.step_id][a.name].map{|e| h_data_classes[e].id}.join(",")
      end
      
      puts "Update:" + h_annot.to_json
      a.update_attributes(h_annot)
      
    end

    p.annots.select{|a| a.data_class_ids == nil or a.data_class_ids == ''}.each do |a|
      #  t = a.name.split(/\//)
      #      if a.data_class_ids == nil
      puts "Checking #{a.name}"
      
      h_annot = {}
      #get parsing step annot
      ori_annot = Annot.where(:project_id => p.id, :name => a.name).order("run_id asc").first
      #if a.dim == 1 or a.dim == 2
      #  h_annot[:data_class_ids] = a.data_class_ids.split(",").reject{|e| [2, 9, 10].include? e.to_i}.join(",")
      # if h_annot[:data_class_ids] != a.data_class_ids
      #   puts "Changed data_class_ids: #{a.data_class_ids} => #{h_annot[:data_class_ids]}"
      # end
      # els
      if a.name == '/col_attrs/_StableID'
        h_annot[:data_class_ids] = '1,3,4,5'
      elsif a.name == '/row_attrs/_StableID'
        h_annot[:data_class_ids] = '1,3,5,8'
      elsif ori_annot
        h_annot[:imported] = ori_annot.imported
        h_annot[:data_class_ids] = ori_annot.data_class_ids
        h_annot[:data_type_id] = ori_annot.data_type_id
      end
      if a.data_class_ids == nil or a.data_class_ids == '' or a.data_type_id == nil #h_annot[:imported] == true 	
        puts "Update:" + h_annot.to_json
	a.update_attributes(h_annot)
      end
      #        h_outputs.each_key do |k|
      #          h_outputs[k].each_key do |k2|
      #            puts h_outputs[k][k2]
      #            if h_outputs[k][k2]['dataset'] == a.name
      #              puts "Name: " + h_outputs[k][k2]['dataset'] + " => " + h_outputs[k][k2]['types'] 
      #            end
      #          end
      ##        end
      #        
      #        puts "#{data_class_ids}"
      #	a.update_attributes({:data_class_ids => data_class_ids}) 
      #end
      
    end

    p.annots.each do |a|
     h_annot = {}
      if a.dim == 1 or a.dim == 2 and a.data_class_ids
        h_annot[:data_class_ids] = a.data_class_ids.split(",").reject{|e| [2, 9, 10].include? e.to_i}.join(",")
        if h_annot[:data_class_ids] != a.data_class_ids
          puts "Changed data_class_ids: #{a.data_class_ids} => #{h_annot[:data_class_ids]}"
        end
      end
      a.update_attributes(h_annot)	
    end


  end
  
end
