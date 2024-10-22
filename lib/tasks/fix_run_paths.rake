
desc '####################### Fix paths in runs'
task fix_run_paths: :environment do
  puts 'Executing...'

  now = Time.now


  h_steps = {}
  Step.all.map{|s| h_steps[s.id] = s}

  Project.where("cloned_project_id is not null").all.sort.each do |p|

    cloned_project = Project.where(:id => p.cloned_project_id).first 
    
    cloned_project_runs = cloned_project.runs.sort if cloned_project
    #  puts cloned_project_runs.map{|r| "#{r.id}[#{r.std_method_id}]"}.join(",")
    h_ori_runs = {}
    
    # cloned_project_runs.each do |r|
    #   k = [r.step_id, r.std_method_id, r.attrs_json]
    #   h_ori_runs[k] = r
    # end
    
    puts p.key + " <- cloned from #{(cloned_project) ? cloned_project.key : 'NA'}" 
    project_dir = Pathname.new(APP_CONFIG[:user_data_dir]) + p.user_id.to_s + p.key
    puts project_dir
    
    runs = [p.runs.sort, p.del_runs.sort].flatten #.select{|r| h_steps[r.step_id].name == 'ge' and r.status_id == 3}
 #   del_runs = p.del_runs.sort
    h_runs = {}
    puts runs.map{|r| h_runs[r.id] = r; "#{r.id}[#{r.std_method_id}]"}.join(",")
 #   puts del_runs.map{|r| h_runs[r.id] = r; "#{r.id}[#{r.std_method_id}]"}.join(",")
    
    h_cloned_runs = {}

    if runs.size > 0 
      runs.select{|r| !r.cloned_run_id}.each do |r|
        
        #        puts r.id
        #	puts "User: #{r.user_id}"              
	
        command = Basic.safe_parse_json(r.command_json, {})
        #	puts command.to_json        
	if command['time_call'] and m = command['time_call'].match(/\/data\/asap2\/users\/(\d+)\/(\w+)\/.+?\/(\d+)/)
          #	puts "#{m[3]}"
          h_cloned_runs[r.id] = m[3].to_i if r.id != m[3].to_i
	end  
         if command['exec_stdout'] and m = command['exec_stdout'].match(/\/data\/asap2\/users\/(\d+)\/(\w+)\/.+?\/(\d+)/)
          h_cloned_runs[r.id] = m[3].to_i if r.id != m[3].to_i
        end

	
      end
    end

    #   puts h_cloned_runs.to_json

    h_cloned_runs.each_key do |run_id|
      h_runs[run_id].update_columns(:cloned_run_id => h_cloned_runs[run_id]) 
    end
    #    exit

  end
end

        
   #     if m = r.command_json.match(/\/data\/asap2\/users\/(\d+)\/(\w+)\//)
   #       if (m[1] != r.user_id.to_s and r.user_id) or m[1] != p.key
   #         r.command_json.gsub!(/\/data\/asap2\/users\/(\d+)\/(\w+)\//, "/data/asap2/users/#{r.user_id}/#{p.key}/")
   #       end
   #       
   #       command = Basic.safe_parse_json(r.command_json, {})
   #       puts  command.to_json
   #       command['exec_stdout'].gsub!(/\/#{p.key}\/(\d+)\//, "/#{p.key}/#{r.id}/") if command['exec_stdout']
   #       command['exec_stderr'].gsub!(/\/#{p.key}\/(\d+)\//, "/#{p.key}/#{r.id}/") if  command['exec_stderr']
    #      command['time_call'].gsub!(/\/#{p.key}\/(\d+)\//, "/#{p.key}/#{r.id}/") if  command['time_call']
    ##      puts command.to_json
    #      exit
    #      
    #      
    #    end
#      end
#    end
#  end
#end

