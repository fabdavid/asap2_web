desc '####################### Fix cloned fo'
task fix_cloned_fo: :environment do
  puts 'Executing...'

  now = Time.now

  warnings = []

  Project.where("cloned_project_id is not null").order("id").all.each do |p|
   
    project_dir =  Pathname.new(APP_CONFIG[:user_data_dir]) + p.user_id.to_s + p.key    
   
    if !File.exist? project_dir
      puts "Unarchive " + p.key
      Basic.unarchive(p.key)
    end

    

    ori_p = Project.where(:id => p.cloned_project_id).first
    if ori_p
      h_runs = {}   
      h_runs2 = {}
      runs = p.runs.map{|r| h_runs[r.step_id.to_s + ":" + r.num.to_s] = r}
      
      ori_runs = ori_p.runs
      
      ori_runs.each do |r|
        cloned_run = h_runs[r.step_id.to_s + ":" + r.num.to_s]
        if cloned_run
          puts "found cloned_run"
          h_runs2[r.id] = cloned_run
        else
          puts "couldn't find cloned_run"
        end
      end		  
      
      
      
      ori_p.fos.each do |fo|
        new_fo = Fo.where(:project_id => p.id, :run_id => fo.run_id, :filepath => fo.filepath).first
	if new_fo
          if h_runs2[fo.run_id]
            h_fo = {
              :run_id => h_runs2[fo.run_id].id,
              :filepath => fo.filepath.gsub(/#{fo.run_id}/, h_runs2[fo.run_id].id.to_s)
            }	    
            if File.exist?(project_dir + h_fo[:filepath])
              h_fo[:filesize] = File.size(project_dir + h_fo[:filepath])
              
              puts "Old => " + fo.to_json
              puts "New => " + new_fo.to_json
              puts "New Change => " + h_fo.to_json 
              if Fo.where(:project_id => p.id, :filepath => h_fo[:filepath]).first
                warnings.push "Fo already exist! #{h_fo[:filepath]} in #{p.id}: delete Fo"
                new_fo.destroy
              else
                new_fo.update_attributes(h_fo)
              end
            else
              warnings.push "File doesnt exist! #{h_fo[:filepath]} in #{p.id}: delete Fo"
              new_fo.destroy
            end
            #      new_fo.update_attributes(h_fo)
          else
            warnings.push "Cannot find original run_id for #{fo.run_id} in #{p.key} (ori = #{ori_p.key} #{ori_p.name})"
            
            if File.exist?(project_dir + fo.filepath)
              h_fo = {
                :filesize => File.size(project_dir + fo.filepath)
              }
              new_fo.update_attributes(h_fo)
            else
              new_fo.destroy
            end
          end
        end
      end
      
      puts "run IDs:" + runs.map{|r| r.id}.join(", ")
      puts "ori_run IDs:" + ori_runs.map{|r| r.id}.join(", ")
    end
  end
  

  puts  warnings.join("\n")

end
