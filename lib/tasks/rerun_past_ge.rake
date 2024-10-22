desc '####################### Rerun past GE'
task rerun_past_ge: :environment do
  puts 'Executing...'

  now = Time.now

  base_old_ge_dir = Pathname.new("/data/asap2/old_ge_results") ## to store old results as a backup

  # get steps
  h_steps = {}
  Step.all.map{|s| h_steps[s.id] = s}

  list_projects = []

  Project.where(:key => '6gyxze').all.each do |p|

    ge_runs = p.runs.select{|r| h_steps[r.step_id].name == 'ge'} # and r.command_json.match(/_filtered.json/)}

    list_projects.push p if ge_runs.size > 0

  end

  puts	"Projects to be updated: #{list_projects.size}"
  puts list_projects.map{|p| p.key}.join(", ")

  list_projects.each do |p|
  puts "Working on project #{p.key}..."
    ## unarchive if necessary                                                                                                                                                                                                         
    unarchived = false
    if p.archive_status_id == 3
      p.unarchive
      unarchived = true
    end
#    unarchived = true
    
    project_dir = Pathname.new(APP_CONFIG[:data_dir]) + 'users' + p.user_id.to_s + p.key

    tmp_old_ge_run_dir = base_old_ge_dir + p.key 
    Dir.mkdir tmp_old_ge_run_dir if !File.exist? tmp_old_ge_run_dir
    
    ge_runs = p.runs.select{|r| h_steps[r.step_id].name == 'ge' and !File.exist?( project_dir + 'ge' + ge_run.id.to_s + 'output.json')} # and r.command_json.match(/_filtered.json/)}#.select{|r| r.command_json.match(/\{"opt"\:"\-f","param_key"\:null,"value"\:".+?_filtered.json"\}/)}

    ge_runs.each do |ge_run|

      old_ge_run_dir = tmp_old_ge_run_dir + ge_run.id.to_s
      ge_run_dir = project_dir + 'ge' + ge_run.id.to_s
      
      if File.exist? ge_run_dir
        
        if ! File.exist? old_ge_run_dir 
          puts "copy #{ge_run_dir} to #{tmp_old_ge_run_dir}" 
          FileUtils.cp_r ge_run_dir, tmp_old_ge_run_dir
        end
        
        puts "RUN_COMMAND: #{ge_run.command_json}" 
        
        ## filter de results
        h_attrs = JSON.parse(ge_run.attrs_json, {})
        puts "ATTRS: " + h_attrs.to_json
        
        if h_attrs["input_de"] and h_attrs["input_de"]["run_id"]
          
          de_run = Run.where(:id => h_attrs["input_de"]["run_id"]).first 
	  if de_run          
            cmd = "lib/filter_de '#{project_dir}' #{h_attrs['fdr_cutoff']} #{h_attrs['fc_cutoff']} ge_form #{ge_run.user_id} '#{de_run.id}' > ./log/filter_de.log"
            
            #  File.open("#{project_dir + "tmp" + "tmp_de_script.sh"}", "w") do |f2|
            #    f2.write(cmd)
            #  end
            
            `#{cmd}` # #{project_dir + "tmp" + "tmp_de_script.sh"}`
            # cmd = "docker run  --name asap_dev_416942 --network=asap2_asap_network -e HOST_USER_ID=$(id -u) -e HOST_USER_GID=$(id -g) --entrypoint '/bin/sh' --rm -v /data/asap2:/data/asap2  -v /srv/asap_run/srv:/srv fabdavid/asap_run:v#{docker_version} -c "sh -c 'java -jar /srv/ASAP.jar -T Enrichment -loom #{h_attrs['input_de']['output_filename']} -m fet -f #{project_dir}/tmp/1_#{h_attrs['input_de']['run_id']}_#{h_attrs['fc_cutoff']}_#{h_attrs['fdr_cutoff']}_filtered_ids.json -o #{project_dir}/ge/#{run.id}/output.json -max 500 -min 15 -adj fdr -geneset 671 -h postgres:5434/asap2_data_v#{database_version}  1> /data/asap2/users/1/bpjlc8/ge/416942/exec.out 2> /data/asap2/users/1/bpjlc8/ge/416942/exec.err'"'
            filtered_de_filename = "#{project_dir}/tmp/#{ge_run.user_id}_#{h_attrs['input_de']['run_id']}_#{h_attrs['fc_cutoff']}_#{h_attrs['fdr_cutoff']}_filtered_ids.json"
            if m = ge_run.command_json.match(/\/data\/asap2\/users\/(\d+)\/(\w+)\/(.+)/)
              if m[2] != p.key
                puts "Wrong project key: #{m[1]} instead of #{p.key}"
                
              else 
              end
            end
            
            #       if m = ge_run.command_json.match(/\/data\/asap2\/users\/(\d+)\/(\w+)\//)
            #          if (m[1] != ge_run.user_id.to_s and ge_run.user_id) or m[1] != p.key
            #             ge_run.command_json.gsub!(/\/data\/asap2\/users\/(\d+)\/(\w+)\//,
            #          end
            
            
            #       end
            
            #	if ge_run.command_json.match(/\{"opt"\:"\-f","param_key"\:null,"value"\:".+?_filtered.json"\}/)        
            new_command_json = ge_run.command_json.gsub(/\{"opt"\:"\-f","param_key"\:null,"value"\:".+?_filtered.json"\}/, "{\"opt\":\"-f\",\"param_key\":null,\"value\":\"#{filtered_de_filename}\"}")
            puts new_command_json
            ge_run.update_column(:command_json, new_command_json)
         
            #          cmd = "rails exec_run[#{ge_run.id}]"
            #          puts cmd
            #          `#{cmd}`
            
            #        cmd = "docker run  --name asap_dev_#{ge_run.id} --network=asap2_asap_network -e HOST_USER_ID=$(id -u) -e HOST_USER_GID=$(id -g) --entrypoint '/bin/sh' --rm -v /data/asap2:/data/asap2  -v /srv/asap_run/srv:/srv fabdavid/asap_run:v5 -c \"time -o '${project_dir}/ge/412699/exec_run_details.log' -f 'U=%U,S=%S,E=%E,P=%P,X=%X,D=%D,M=%M,K=%K,t=%t,I=%I,O=%O,F=%F,R=%R,W=%W'  sh -c 'java -jar /srv/ASAP.jar -T Enrichment -loom ${project_dir}/parsing/output.loom -m fet -f ${project_dir}/tmp/1142_412639_filtered.json -o ${project_dir}/ge/412699/output.json -max 500 -min 15 -adj fdr -geneset 3138 -h postgres:5434/asap2_data_v5  1> $PROJECT_DIR/ge/#{}/exec.out 2> $PROJECT_DIR/ge/412699/exec.err'""
            h_cmd = Basic.safe_parse_json(ge_run.command_json, {})
            if h_cmd.keys.size == 0
              all_displayed_errors.push("Not valid command")
            else
              cmd = Basic.build_cmd(h_cmd)
              puts cmd
              `#{cmd}`
            end
          end
          #       end
        end
      end
    end

    # compute filter                                                                                                                               
    #    cmd = "echo '#{ge_runs.map{|r| r.id}.join("\n")}' | xargs -P 24 -I '{}' lib/filter_ge '#{project_dir}' 0.05 ge_results 1 '{}' > #{project_dir + 'toto_ge.txt'}"
    #    puts "ge_filter cmd : #{cmd}"
    #    script_file = project_dir + "tmp" + "1_ge_script.sh"
    #    File.open(script_file, "w") do |f2|
    #      f2.write(cmd)
    #    end
    #
    #    `sh #{script_file}`
  #  File.delete() if File.exist?

    #    filtered_stats_file = project_dir + 'tmp' + "#{(current_user) ? current_user.id : 1}_ge_filtered_stats.json"
    if File.exist? project_dir + 'tmp'	   
      filter_files = Dir.entries(project_dir + 'tmp').select{|e| e.match(/_ge_filtered_stats.json/)}
      puts filter_files
      filter_files.map{|e| File.delete(project_dir + 'tmp' + e)}
    end
    ## rearchive if was unarchived
    if unarchived == true
      puts "Archiving..."
      logfile = "./log/fix_ge_results_archive.log"
      errfile = "./log/fix_ge_results_archive.err"
      cmd = "rails archive[#{p.key}] --trace 1> #{logfile.to_s} 2> #{errfile.to_s}"
      puts cmd
      `#{cmd}`
    end
    

  end		    


end
