desc '####################### Fix paths in runs3'
task fix_run_paths3: :environment do
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

  Project.where("cloned_project_id is not null and id=31829").all.sort.reverse.each do |p|
    h_projects[p.key] = p

    puts "Project #{p.key} [#{p.id}] <- cloned from #{p.cloned_project_id}"

    h_runs = {}
    Run.all.map{|r| h_runs[r.id] = r}

    annots = p.annots
    annots.map{|a| a.run.id}

  end
  
#  puts h_problem.keys.select{|k| h_projects[k] and h_projects[k].user_id !=1}.map{|k| "[#{h_projects[k].key}, #{h_projects[k].user_id}]"}.join(" ")

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

