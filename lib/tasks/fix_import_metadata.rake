desc '####################### Fix import_metadata'
task fix_import_metadata: :environment do
  puts 'Executing...'

  now = Time.now
  logger = Logger.new("log/exec_run.log")

 h_data_types = {}
  DataType.all.map{|dt| h_data_types[dt.name] = dt}

  h_data_classes = {}
  DataClass.all.map{|dt| h_data_classes[dt.name] = dt}



  Project.order("id desc").all.each do |p|
      
    project_dir = Pathname.new(APP_CONFIG[:data_dir]) + "users" + p.user_id.to_s + p.key
    output_path = project_dir + 'parsing' + 'output.loom'
    metadata_list_file2 = project_dir + 'parsing' + 'list_metadata_to_copy2.json'
    
    if File.exist? output_path and File.exist? metadata_list_file2

      run = Run.joins(:step).where(:project_id => p.id, :steps => {:name => 'parsing'}).first
      
      if run

        cmd = "java -jar lib/ASAP.jar -T ExtractMetadata -no-values -loom #{output_path} -metaJSON #{metadata_list_file2}"
        puts cmd
        output = `#{cmd}`
        h_res = Basic.safe_parse_json(output, {})
        puts output
        puts h_res.to_json
        if list_metadata = h_res['list_meta']
          relative_filepath = Basic.relative_path(p, output_path)
          list_metadata.each do |meta|
            meta['imported'] = true
            puts "add annot #{meta.to_json}"
            Basic.load_annot(run, meta, relative_filepath, h_data_types, h_data_classes, logger)
	    Annot.where(:name => meta['name'], :project_id => p.id).all.each do |annot|
            		      puts "annot: " + meta['type']
	      annot.update_attribute(:data_type_id, ((dt = h_data_types[meta['type']]) ? dt.id : nil))
	    end		      
          end
        end
      end	
    end
    
  end
  
end
