desc '####################### Clean'
task upgrade_output_json: :environment do
  puts 'Executing...'

  now = Time.now
  
  Project.all.each do |p|
    
    project_dir =  Pathname.new(APP_CONFIG[:user_data_dir]) + p.user_id.to_s + p.key
    
    p.runs.each do |r|

      annots = Annot.where(:run_id => r.id).all
      h_annots = {}
      annots.each do |annot|
        h_annots[annot.filepath]||={}
        h_annots[annot.filepath][annot.name]= annot
      end

      
#      step = r.step
#      run_dir = project_dir + step.name
#      if r.step.multiple_runs == true
#        run_dir = project_dir + step.name + r.id.to_s
#      end
      
#      if File.exist? run_dir + "output.json"
#        h_output = Basic.safe_parse_json(File.read(run_dir + "output.json"), {})
      
      # puts h_output.to_json				           
#      if h_output["nber_cols"]
      #  puts h_output.to_json
      
      h_outputs = Basic.safe_parse_json(r.output_json, {})
         
      dataset = nil
      loom_file = ''
      ['output_annot', 'output_matrix'].each do |field|
        if h_outputs and h_outputs[field]
          puts "OLD: " + h_outputs.to_json
          h_outputs[field].keys.each do |output_key|
            t = output_key.split(":")
            if t.size > 1
              loom_file = t[0]
              dataset = t[1]
	      if  h_annots[loom_file] and annot = h_annots[loom_file][dataset]
                h_outputs[field][output_key]["nber_cols"] = annot.nber_cols if annot.nber_cols
                h_outputs[field][output_key]["nber_rows"] = annot.nber_rows if annot.nber_rows
		h_outputs[field][output_key]["dataset_size"] = annot.mem_size if annot.mem_size
              end
            end
          end
#          puts "NEW: " + h_outputs.to_json
          puts "Update #{r.id}" 
	  puts  h_outputs.to_json
          r.update_attribute(:output_json, h_outputs.to_json)
#          exit

        end
      end
    end
    #   end
  end
  
end
