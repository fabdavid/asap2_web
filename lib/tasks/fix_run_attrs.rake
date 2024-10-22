$not_found_errors = []
$changes = []
desc '####################### Fix run attrs'
task fix_run_attrs: :environment do
  puts 'Executing...'

  now = Time.now

  h_problem = {}

  h_steps = {}
  Step.all.map{|s| h_steps[s.id] = s}

  def get_runs p, h_runs, h_runs_by_p

    h_runs_by_p[p.id] = {}
    p.runs.map{|r| h_runs[r.id] = r; h_runs_by_p[p.id][r.id] = 1 }
    p.del_runs.map{|r| h_runs[r.id] = r; h_runs_by_p[p.id][r.id] = 1 }
    return {
      :h_runs => h_runs,
      :h_runs_by_p => h_runs_by_p
    }

  end


  def clone_replace_attr cloned_project, p, run, attr, h_runs, list_groups, h_runs_by_p
    #    puts "Replace..."
    attr.each_key do |k|
      if k != 'run_id' and k !='annot_id'
        #     puts "Treating key #{k}"
        if m = attr[k].to_s.match(/\/(\d+)\/(\w+)\/\w+?\/(\d+)\/?/)
          user_id = m[1]
          project_key = m[2]
          run_id = m[3]
          new_run_id = identify_new_run_id(run_id.to_i, p, list_groups, h_runs_by_p)
          if new_run_id
            #	  puts "Change run_id #{run_id} => #{new_run_id}"
            attr[k].gsub!(/\/#{run_id}\//, "/#{new_run_id}/")
             attr[k].gsub!(/\/#{run_id}$/, "/#{new_run_id}")
            if attr[k].to_s.match(/\/#{project_key}\//)
              attr[k].gsub!(/\/#{project_key}\//, "/#{p.key}/")
              attr[k].gsub!(/\/#{user_id}\//, "/#{p.user_id}/")
            end
            
          else
            $not_found_errors.push [p.key, run.id]
          end
        end

      end
    end
    return attr
  end

  def identify_new_run_id run_id, p, list_groups, h_runs_by_p    
    
    # identify
    # puts "PROJECT_ID: #{p.id}"
    #  puts "RUN_ID: #{run_id}"
    group = {}
    list_groups.each do |tmp_g|
      #puts "TMP_G: " + tmp_g.keys.to_json	      
       group = tmp_g if tmp_g[run_id]
    end
    #     puts h_runs_by_p.to_json
    
    l = group.keys & h_runs_by_p[p.id].keys
    #     puts "GROUP: " + group.keys.to_json
    #     puts "H_RUNS: " + h_runs_by_p[p.id].keys.to_json
    if l.size > 1
      puts "ERROR: several run_ids: #{l.to_json}"
      exit 
    end
    puts "FOUND: #{l.first}"
    return (l) ? l.first : nil
  end
  
  h_projects = {}
  
  Project.where("cloned_project_id is not null and user_id != 1").all.sort.each do |p|
    h_projects[p.key] = p
    cloned_project = Project.where(:id => p.cloned_project_id).first
    if cloned_project
      #  h_runs = {}
      #  h_map_clone = {}
      #  p.runs.map{|r| h_map_clone[r.cloned_run_id] = r.id;}
      #  p.del_runs.map{|r| h_map_clone[r.cloned_run_id] = r.id;}
       
     #  p.runs.map{|r| h_runs[r.cloned_run_id] = r}
     #  p.del_runs.map{|r| h_runs[r.cloned_run_id] = r}
       
       
       puts "Project #{p.key} [#{p.id}] <- cloned from #{p.cloned_project_id}"
       current_p = p
       h_runs = {}
       list_p = []
       h_runs_by_p = {}
       h = get_runs(current_p, h_runs, h_runs_by_p)
       h_runs_by_p = h[:h_runs_by_p]
       h_runs = h[:h_runs]
       list_p.push current_p
       
       while tmp_cloned_project = Project.where(:id => current_p.cloned_project_id).first         
         list_p.push tmp_cloned_project
     #    puts "push!"
         h = get_runs(tmp_cloned_project, h_runs, h_runs_by_p)
         h_runs_by_p = h[:h_runs_by_p]
         h_runs = h[:h_runs]
         current_p = tmp_cloned_project         
       end
       

       list_groups = []
#       puts list_p.to_json       
       list_p.reverse.each do |tmp_p|
         tmp_project_runs = (tmp_p.runs.sort + tmp_p.del_runs.sort) if tmp_p
         if tmp_project_runs
           tmp_project_runs.map{|r|
             if h_runs[r.cloned_run_id] and tmp_p.cloned_project_id == h_runs[r.cloned_run_id].project_id #and tmp_p.cloned_project_id == h_runs[r.cloned_run_id].project_id and !h_ori[r.cloned_run_id]    
               #               h_ori[r.cloned_run_id] ||= r.id
               
               found_group = false
               list_groups.each do |tmp_group|
                 if tmp_group[r.id] or tmp_group[r.cloned_run_id]
                   tmp_group[r.id] = 1
                   tmp_group[r.cloned_run_id] = 1
                   found_group = true
                 end
               end
               if found_group == false
                 tmp_h = {r.id => 1, r.cloned_run_id => 1}
                 list_groups.push(tmp_h)
               end
#               
 #              puts "MAP: #{r.cloned_run_id} => #{r.id}"
             end
           }
         end
       end

#       puts "LIST_GROUPS:"
#       puts list_groups.to_json
       
       p.runs.select{|r| ![118, 119].include? r.std_method_id}.each do |run|
         
        new_run_id = nil
         
         if run.cloned_run_id
           new_command = Basic.safe_parse_json(run.command_json, {})
           ['time_call', 'exec_stdout', 'exec_stderr'].each do |k|
             if new_command[k]
               # logger.debug("TIME_CALL_DEBUG")
               # logger.debug(run_dir.to_s)
               #       logger.debug(new_run_dir.to_s)
               if m = new_command[k].to_s.match(/\/(\d+)\/(\w+)\/\w+?\/(\d+)\/?/)
                 user_id = m[1]
                 project_key = m[2]
                 run_id = m[3]
                 
                 new_run_id = identify_new_run_id(run_id.to_i, p, list_groups, h_runs_by_p)
                 if new_run_id
                   #                   new_command[k].gsub!(/\/#{run_id}\//, "/#{h_runs[run_id.to_i].cloned_run_id}/")
                   new_command[k].gsub!(/\/#{run_id}\//, "/#{new_run_id}/")
                   new_command[k].gsub!(/\/#{run_id}$/, "/#{new_run_id}")
                   new_command[k].gsub!(/\/#{project_key}\//, "/#{p.key}/")
                   new_command[k].gsub!(/\/#{user_id}\//, "/#{p.user.id}/")
                 end
               end
             end
           end
        
           new_attrs = Basic.safe_parse_json(run.attrs_json, {})
           new_attrs.each_key do |k|
             if new_attrs[k].is_a? Hash
               new_attrs[k] = clone_replace_attr(cloned_project, p, run, new_attrs[k], h_runs, list_groups, h_runs_by_p)
 #              puts "NEW_ATTRS: #{new_attrs[k].to_json}"
             elsif new_attrs[k].is_a? Array
               new_attrs[k].each_index do |i|
                 new_attrs[k][i] = clone_replace_attr(cloned_project, p, run, new_attrs[k][i], h_runs, list_groups, h_runs_by_p)
               end
             elsif !['annot_id', 'run_id'].include? k
  #             puts "TEST!!! #{k}"
               #            logger.debug("test_clone: " + new_attrs[k].to_s)
               if m = new_attrs[k].to_s.match(/users\/(\d+)\/(\w+?)\/\w+?\/(\d+)\/?/)
                 user_id = m[1]
                 project_key = m[2]
                 run_id = m[3]
                 new_run_id = identify_new_run_id(run_id.to_i, p, list_groups, h_runs_by_p)
   #              puts "TEST: #{run_id} => #{new_run_id}"
                 if new_run_id #h_runs[run_id.to_i]
                    puts "TEST2: #{run_id} => #{new_run_id}"
                   #        new_attrs[k].gsub!(/\/#{run_id}\//, "/#{h_runs[run_id.to_i].cloned_run_id}/")
                   new_attrs[k].gsub!(/\/#{run_id}\//, "/#{new_run_id}/") 
                   new_attrs[k].gsub!(/\/#{run_id}$/, "/#{new_run_id}")
                 else
                   
                   $not_found_errors.push [p.key, run.id]
                 end
               end
               if m = new_attrs[k].to_s.match(/\/data\/asap2\/users\/(\d+)\/(\w+)\/?/)
                 user_id = m[1]
                 project_key = m[2]
                 new_attrs[k].gsub!(/\/#{project_key}\//, "/#{p.key}/")
                 new_attrs[k].gsub!(/\/#{user_id}\//, "/#{p.user_id}/")
               end
               
             end
           end

	   $changes.push [run.attrs_json, new_attrs.to_json] if run.attrs_json != new_attrs.to_json
           $changes.push [run.command_json, new_command.to_json] if run.command_json != new_command.to_json
           run.update_attributes({
                                   :attrs_json => new_attrs.to_json,
                                   :command_json => new_command.to_json
                                 })
           puts "RUN: #{run.id}"
           puts run.attrs_json
           puts " => "
           puts new_attrs.to_json
           
           
         end
         
       end
    end

    

  end
  
#  puts h_problem.keys.select{|k| h_projects[k] and h_projects[k].user_id !=1}.map{|k| "[#{h_projects[k].key}, #{h_projects[k].user_id}]"}.join(" ")

#   puts cannot_correct.map{|e| e.join(",")}.join("\n")

   puts $changes.map{|e| e.join("\n=>\n")}.join("\n")
   puts $not_found_errors.map{|e| e.join(", ")}.join("\n")

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

