desc '####################### Fix pred_params_json'
task :fix_pred_params_json, [:list_runs_ids] => :environment do |t, args|
  puts 'Executing...'

  now = Time.now
  list_run_ids = (args[:list_run_ids]) ? args[:list_run_ids].split(",") : []
  h_run_ids = {}
  list_run_ids.map{|rid| h_run_ids[rid] = 1}
  #  data_dir = Pathname.new(APP_CONFIG[:data_dir])
  
  h_steps = {}
  Step.all.each do |s|
    h_steps[s.id] = s
  end		
  h_std_methods = {}
  StdMethod.all.each do |s|
    h_std_methods[s.id] = s
  end

# just once

#  h_std_methods.each_key do |sid|
#    h_command = Basic.safe_parse_json(h_std_methods[sid]['command_json'], {})
#    if h_command["predict_params"] == ["nb_cols","nb_rows","std_method_name"]
#      h_command["predict_params"] = ["nber_cols","nber_rows","std_method_name"]      
#      puts h_command["predict_params"].to_json
#      h_std_methods[sid].update_attribute(:command_json,  h_command.to_json)
#    end
#    if h_command["predict_params"]
#      h_command["predict_params"].each_index do |i|
#        if h_command["predict_params"][i] == 'nber_clusters'
#          h_command["predict_params"][i] = 'k'
#          h_std_methods[sid].update_attribute(:command_json,  h_command.to_json)
#        end
#      end
#    end
#  end

  Project.all.each do |p|
    
    project_dir =  Pathname.new(APP_CONFIG[:user_data_dir]) + p.user_id.to_s + p.key
    if File.exist? project_dir    
      h_runs = {}
#      p.runs.select{|r| r.pred_params_json and (list_run_ids.size == 0 or h_runs_ids[r.id])}.each do |run|
      p.runs.select{|r| r.status_id == 3}.each do |run| 
        #     p.runs.each do |run|
        h_runs[run.id] = run
      end
      
#      p.annots.select{|a| h_runs[a.run_id]}.sort{|a, b| a.run_id <=> b.run_id}.each do |a|
      p.runs.select{|r| r.status_id == 3}.each do |run|
        step = h_steps[run.step_id]
#	run = h_runs[a.run_id]
	
        h_predict_params = Basic.set_predict_params(p, run, h_std_methods[run.std_method_id], h_runs, h_steps)

        puts "H_PRED_PARAMS:" + h_predict_params.to_json
        run.update_attribute(:pred_params_json, h_predict_params.to_json)
        
      end
    end
  end
  
end
