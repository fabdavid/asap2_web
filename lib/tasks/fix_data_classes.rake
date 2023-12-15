desc '####################### Fix data_classes'
task fix_data_classes: :environment do
  puts 'Executing...'
  
  now = Time.now
  
#  h_tr = {
#    'annot' => 'attr', 
#    'col_annot' => 'col_attr', 
#    'row_annot' => 'row_attr',
#    'numeric_annot' => 'numeric_attr',
#    'discrete_annot' => 'discrete_attr',
#    'string_annot' => 'string_attr'
#  }
  
  h_data_classes = {}
  DataClass.all.map{|dc| 
    #    dc.update_attribute(:name, dc.name.gsub(/annot/, "attr"))
    h_data_classes[dc.name] = dc}
  
  #  h_std_methods = {}
  #  StdMethod.all.map{|s| h_std_methods[s.id] = s}  
  
  h_steps = {}
  Step.all.each do |s|
  puts "[ step " + s.name + " #{s.id}" + " ]"
    h_steps[s.id] = s
    h_upd = {
      :attrs_json => s.attrs_json.gsub(/global_attr/, "global_mdata").gsub(/input_annot/, "input_de").gsub(/group_annot/, "groups").gsub(/annot/, "mdata").gsub(/mdataation/, "metadata"),
      :command_json => s.command_json.gsub(/global_attr/, "global_mdata").gsub(/input_annot/, "input_de").gsub(/batch_annot/, "covariates").gsub(/group_annot/, "groups"),
      :method_attrs_json => s.method_attrs_json.gsub(/global_attr/, "global_mdata").gsub(/batch_annot/, "covariates").gsub(/input_annot/, "input_de").gsub(/Input annotation/, "Input DE").gsub(/group_annot/, "groups").gsub(/annot/, "mdata").gsub(/mdataation/, "metadata"),
      :dashboard_card_json => s.dashboard_card_json.gsub(/group_annot/, "groups").gsub(/annot/, "mdata"),
      :output_json => s.output_json.gsub(/global_attr/, "global_mdata").gsub(/group_annot/, "groups").gsub(/annot/, "mdata")
    }
    if s.attrs_json !=  h_upd[:attrs_json] or s.output_json != h_upd[:output_json] or s.method_attrs_json !=  h_upd[:method_attrs_json]
      puts h_upd.to_json
#      s.update_attributes(h_upd)
    end
  end

  StdMethod.all.each do |s|
  puts "[ std_method " + s.name + " #{s.id}" + " ]"
    h_upd = {
      :command_json => s.command_json.gsub(/input_annot/, "input_de").gsub(/group_annot/, "groups").gsub(/_annot/, "_mdata"),
      :attrs_json => s.attrs_json.gsub(/input_annot/, "input_de").gsub(/group_annot/, "groups").gsub(/annot/, "mdata").gsub(/mdataation/, "metadata"),
      :attr_layout_json => s.attr_layout_json.gsub(/input_annot/, "input_de").gsub(/group_annot/, "groups").gsub(/_annot/, "_mdata")
    }
    if s.attrs_json != h_upd[:attrs_json] or s.attr_layout_json != h_upd[:attr_layout_json] or s.command_json != h_upd[:command_json]
      puts h_upd.to_json
           s.update_attributes(h_upd)
    end
  end
  
  DataClass.all.each do |dc|
    puts "[ data_class " + dc.name + " #{dc.id}" + " ]"
    h_upd={
      :name => dc.name.gsub(/attr/, 'mdata').gsub(/annot/, 'mdata')
    }
    puts h_upd.to_json
    #dc.update_attributes(h_upd)
  end
  
  exit
  Project.order("id desc").all.each do |p|
    puts "Project #{p.key}..."    
    
    project_dir = Pathname.new(APP_CONFIG[:user_data_dir]) + p.user_id.to_s + p.key
       
    p.runs.each do |r|
      h_upd = {
        :attrs_json => r.attrs_json.gsub(/batch_annot/, "covariates").gsub(/input_annot/, "input_de").gsub(/group_annot/, "groups").gsub(/annot/, "mdata"),
        :output_json => r.output_json.gsub(/global_attr/, "global_mdata").gsub(/batch_annot/, "covariates").gsub(/input_annot/, "input_de").gsub(/group_annot/, "groups").gsub(/annot/, "mdata")
      }
      if r.attrs_json !=  h_upd[:attrs_json] or r.output_json != h_upd[:output_json]
        puts h_upd.to_json
        r.update_attributes(h_upd)       
      end
      
      step = h_steps[r.step_id]
      
      if !['de', 'ge'].include? step.name  
        
        step_dir = project_dir + step.name
        run_dir = (step.multiple_runs == true) ? (step_dir + r.id.to_s) : step_dir
        
        output_json_file = run_dir + 'output.json'
        puts output_json_file
        if File.exist?(output_json_file)
          output_json = File.read(output_json_file)
          new_output_json = output_json.gsub(/global_attr/, "global_mdata").gsub(/batch_annot/, "covariates").gsub(/input_annot/, "input_de").gsub(/group_annot/, "groups").gsub(/annot/, 'mdata')
          if output_json != new_output_json
            puts new_output_json
            File.open(output_json_file, 'w') do |f|
              f.write(new_output_json)
            end
          end
        end
      end
      
    end
    
  end
end
