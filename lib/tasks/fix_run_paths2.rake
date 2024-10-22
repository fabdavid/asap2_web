desc '####################### Fix paths in runs2'
task fix_run_paths2: :environment do
  puts 'Executing...'

  now = Time.now

  h_problem = {}

  h_steps = {}
  Step.all.map{|s| h_steps[s.id] = s}

  h_projects = {}

  cannot_correct = []

  def get_runs p, h_runs, h_runs_by_p

    #    puts "Project #{p.id} cloned from #{p.cloned_project_id}"
    # puts "cloned from #{cloned_project.cloned_project_id}" if cloned_project and cloned_project.cloned_project_id
    # cloned_project_runs = (cloned_project.runs.sort + cloned_project.del_runs.sort) if cloned_project
    # root_project = Project.where(:id => p.root_project_id).first
    # puts "original project: #{root_project.id}" if root_project
    # root_project_runs = (root_project.runs.sort + root_project.del_runs.sort) if root_project
    # if p.cloned_project_id
    h_runs_by_p[p.id] = {}
    #Run.where(:id => p.runs.map{|r| r.cloned_run_id }.compact)
    p.runs.map{|r| h_runs[r.id] = r; h_runs_by_p[p.id][r.id] = r }
    #DelRun.where(:id => p.runs.map{|r| r.cloned_run_id }.compact).all
    p.del_runs.map{|r| h_runs[r.id] = r; h_runs_by_p[p.id][r.id] = r }
    # end
    return {
      :h_runs => h_runs,
      :h_runs_by_p => h_runs_by_p
    }

  end

  Project.where("cloned_project_id is not null").all.sort.reverse.each do |p|
    h_projects[p.key] = p

    puts "Project #{p.key} [#{p.id}] <- cloned from #{p.cloned_project_id}"

    current_p = p

    h_runs = {}
    list_p = []
    h_runs_by_p = {}
    h = get_runs(current_p, h_runs, h_runs_by_p)
    h_runs_by_p = h[:h_runs_by_p]
    h_runs = h[:h_runs]
    list_p.push current_p

    while cloned_project = Project.where(:id => current_p.cloned_project_id).first

      list_p.push cloned_project
      puts "push!"
      h = get_runs(cloned_project, h_runs, h_runs_by_p)      
      h_runs_by_p = h[:h_runs_by_p]
      h_runs = h[:h_runs]
      current_p = cloned_project
      
    end

    #    if !cloned_project

    #    list_p.reverse! # get the list of projects from original to latest clone
    puts "LIST: " + list_p.map{|e| e.id}.join(",")
    first_clone_project = list_p[0] ## first clone

    puts "H_RUNS: " + h_runs.keys.join(",")

    #    puts "Project #{p.id} cloned from #{p.cloned_project_id}"
    #    puts "cloned from #{cloned_project.cloned_project_id}" if cloned_project and cloned_project.cloned_project_id 
    #   cloned_project_runs = (cloned_project.runs.sort + cloned_project.del_runs.sort) if cloned_project
    #   root_project = Project.where(:id => p.root_project_id).first
    #  puts "original project: #{root_project.id}" if root_project
    #    root_project_runs = (root_project.runs.sort + root_project.del_runs.sort) if root_project
    
    # h_runs = {}
    # Run.where(:id =>  p.runs.map{|r| r.cloned_run_id }.compact).all.map{|r| h_runs[r.id] = r }
    # DelRun.where(:id =>  p.runs.map{|r| r.cloned_run_id }.compact).all.map{|r| h_runs[r.id] = r }
    
    #    h_cloned_project_runs = {}
    h_ori = {}
    h_all_ori = {}
    list_groups = []
    
    list_p.reverse.each do |tmp_p|
      tmp_project_runs = (tmp_p.runs.sort + tmp_p.del_runs.sort) if tmp_p
      if tmp_project_runs	
        tmp_project_runs.map{|r|
          if h_runs[r.cloned_run_id] and tmp_p.cloned_project_id == h_runs[r.cloned_run_id].project_id #and tmp_p.cloned_project_id == h_runs[r.cloned_run_id].project_id and !h_ori[r.cloned_run_id]
            h_ori[r.cloned_run_id] ||= r.id
            #            h_all_ori[r.cloned_run_id] ||=[]
            #            h_all_ori[r.cloned_run_id].push r.id
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
            
            puts "MAP: #{r.cloned_run_id} => #{r.id}"
          end
        }
      end
      # DelRun.where(:id =>  
      # cloned_project_runs.map{|r| r.cloned_run_id}.compact).all.map{|r| h_runs[r.id] = r; h_map[r.cloned_run_id] = r.id }
    end

    puts "LIST_GROUPS: " + list_groups.map{|e| e.keys.join(", ")}.join("\n")
    
#    p.runs.select{|r| r.id == 294288}.each do |run|
     p.runs.each do |run| 
      if run.cloned_run_id
        puts "TEST #{run.id} #{run.project_id} #{run.cloned_run_id}"     
        if h_runs[run.cloned_run_id] and h_runs[run.cloned_run_id].project_id != p.cloned_project_id
          puts "PROBLEM with #{p.key}!!!!!!!!!!!!!!!"
          h_problem[p.key] = 1
	  puts "Run #{run.id} [#{run.project_id}] -> Cloned run #{run.cloned_run_id} [#{h_runs[run.cloned_run_id].project_id}] != #{p.cloned_project_id}"
          
          #puts h_map.to_json
	  puts "H_RUNS: " + h_runs_by_p[p.id].keys.map{|k| [k, h_runs[k].cloned_run_id].to_json}.join(",")
          puts "ORI: " + h_ori[run.cloned_run_id].to_s
          puts h_runs[h_ori[run.cloned_run_id]].project_id if h_runs[h_ori[run.cloned_run_id]]
          #         list_p.each do |test_p|
          #           run_ids = h_runs_by_p[test_p.id].keys
          #           if run_ids.include? run.cloned_run_id
          #           if h_runstest_p.id
          #         end
          ## run.cloned_run_id is wrong: it's the id of an older project 
          current_cloned_run_id = run.cloned_run_id
          ori_run_id = h_ori[current_cloned_run_id]
          #  while ori_run_id = h_ori[current_cloned_run_id] and h_runs[ori_run_id] and h_runs[ori_run_id].project_id =! p.cloned_project_id
#          current_cloned_run_id = h_runs[ori_run_id].cloned_run_id
          #  end
          if ori_run_id and h_runs[ori_run_id] and h_runs[ori_run_id].project_id == p.cloned_project_id
            puts "Suggestion: #{ori_run_id} [#{h_runs[ori_run_id].project_id}]"            
            run.update_attribute(:cloned_run_id, ori_run_id)
          else
            can_correct = false
            list_groups.each do |tmp_h|
              if tmp_h[run.cloned_run_id]
                tmp_h.each_key do |k|
                  if h_runs[k].project_id == p.cloned_project_id
                    can_correct = true
                    puts "Can correct #{run.cloned_run_id} => #{k}"
                    run.update_attribute(:cloned_run_id, k)
                    break
                  end
                end
              end
            end
            if can_correct == false
              puts "Cannot correct"
              #            exit
              cannot_correct.push [p.id, run.id, run.cloned_run_id]
              puts "ALL ORI: " + h_all_ori[run.cloned_run_id].to_json
            end
          end
          
	end
      else

        puts run.command_json
        
      end
      
    end

    

  end
  
#  puts h_problem.keys.select{|k| h_projects[k] and h_projects[k].user_id !=1}.map{|k| "[#{h_projects[k].key}, #{h_projects[k].user_id}]"}.join(" ")
  puts "CANNOT CORRECT:"
   puts cannot_correct.map{|e| e.join(",")}.join("\n")

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

