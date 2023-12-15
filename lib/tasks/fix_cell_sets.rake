desc '####################### Fix cell sets'
task fix_cell_sets: :environment do
  puts 'Executing...'

  now = Time.now
    
  f = File.open("log/fix_cell_sets.err", "w")

  logger = Logger.new("log/fix_cell_sets_logger.log")
  h_data_types = {}
  DataType.all.map{|e| h_data_types[e.id] = e; h_data_types[e.name] = e}
  h_data_classes = {}
  DataClass.all.map{|e| h_data_classes[e.id] = e; h_data_classes[e.name] = e}
  

  Project.where(:key => '6gyxze').all.order(:id).each do |p|
  puts p.id			        

  

    project_dir = Pathname.new(APP_CONFIG[:user_data_dir]) + p.user_id.to_s + p.key
  
    fu = Fu.where(:project_id => p.id, :upload_type => 1).first
    upload_dir = Pathname.new(APP_CONFIG[:data_dir]) +  'fus' + fu.id.to_s
    ori_fu_path = Pathname.new(APP_CONFIG[:upload_data_dir]) + fu.id.to_s + fu.upload_file_name


    output_json = File.read(Pathname.new(project_dir) + 'parsing' + 'output.json')
    h_output = Basic.safe_parse_json(output_json, {})
    list_metadata = h_output['metadata']
    h_metadata = {}
    list_metadata.each do |meta|
      h_metadata[meta['name']] = meta
    end		       
    
    annots = p.annots.select{|a| a.dim == 1 and a.data_type_id == 3 and a.ori_run_id == a.run_id}
    annot_cell_sets = AnnotCellSet.where(:annot_id => annots.map{|e| e.id}).all
    h_annot_cell_sets = {}
    annot_cell_sets.map{|a| h_annot_cell_sets[a.annot_id] = a}
    project_cell_set = p.project_cell_set #ProjectCellSet.where(:project_cell_set_id => p.project_cell_set_id).first

    if !project_cell_set
      error = "ERROR: project_cell_set missing for #{p.key}"
      f.write(error + "\n")
    end

    output_path = project_dir + "parsing" + "output.loom"
    # relative_path = Basic.relative_path(p, output_path)

    tmp_dir = Pathname.new(project_dir) + 'parsing'
    metadata_list_file = tmp_dir + 'list_metadata_to_copy.json'
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
     # relative_filepath = Basic.relative_path(p, output_path)
      list_metadata.each do |meta|
        meta['imported'] = true
        h_metadata[meta['name']] = meta
        #  Basic.load_annot(annot.run, annot, relative_filepath, h_data_types, h_data_classes, logger)
      end
      
    end
    

    
    annots.each do |annot|
      
       relative_filepath = annot.filepath

      if !h_annot_cell_sets[annot.id]
        error = "ERROR: annot_cell_set missing for PROJECT ##{p.id} [#{p.key}] => #{annot.name}"
        f.write(error + "\n")
#        meta = annot.attributes
	 
        if h_metadata[annot.name]
          Basic.load_annot(annot.run, h_metadata[annot.name], relative_filepath, h_data_types, h_data_classes, logger)
        else
          puts "#{annot.name} not found in metadata in output.json file"
        end
      end
      
    end


  end


  f.close

end
