desc '####################### Fix GE results'
task fix_ge_results: :environment do
  puts 'Executing...'

  now = Time.now


  h_steps = {}
  Step.all.map{|s| h_steps[s.id] = s}

  Project.where(:archive_status_id == 3).all.sort.reverse.each do |p|
  
    puts p.key
    project_dir = Pathname.new(APP_CONFIG[:user_data_dir]) + p.user_id.to_s + p.key
    puts project_dir

    runs = p.runs.select{|r| h_steps[r.step_id].name == 'ge' and r.status_id == 3}

    if runs.size > 0
      
      ## unarchive if necessary
      unarchived = false
      if p.archive_status_id == 3
        p.unarchive
        unarchived = true
      end
      
      runs.each do |r|
        
        puts r.id

        ## filter de
        h_attrs = JSON.parse(r.attrs_json, {})
        puts h_attrs.to_json

        cmd = "lib/filter_de '#{project_dir}' #{h_attrs['fdr_cutoff']} #{h_attrs['fc_cutoff']} ge_form 1 '#{r.id}' > #{project_dir + 'toto.txt'}"
        
      #  File.open("#{project_dir + "tmp" + "tmp_de_script.sh"}", "w") do |f2|
      #    f2.write(cmd)
      #  end

        `#{cmd}` # #{project_dir + "tmp" + "tmp_de_script.sh"}`

        #cmd = "docker run  --name asap_dev_416942 --network=asap2_asap_network -e HOST_USER_ID=$(id -u) -e HOST_USER_GID=$(id -g) --entrypoint '/bin/sh' --rm -v /data/asap2:/data/asap2  -v /srv/asap_run/srv:/srv fabdavid/asap_run:v#{docker_version} -c "sh -c 'java -jar /srv/ASAP.jar -T Enrichment -loom #{h_attrs['input_de']['output_filename']} -m fet -f #{project_dir}/tmp/1_#{h_attrs['input_de']['run_id']}_#{h_attrs['fc_cutoff']}_#{h_attrs['fdr_cutoff']}_filtered_ids.json -o #{project_dir}/ge/#{run.id}/output.json -max 500 -min 15 -adj fdr -geneset 671 -h postgres:5434/asap2_data_v#{database_version}  1> /data/asap2/users/1/bpjlc8/ge/416942/exec.out 2> /data/asap2/users/1/bpjlc8/ge/416942/exec.err'"'
        filtered_de_filename = "#{project_dir}/tmp/1_#{h_attrs['input_de']['run_id']}_#{h_attrs['fc_cutoff']}_#{h_attrs['fdr_cutoff']}_filtered_ids.json"
        if m = r.command_json.match(/\/data\/asap2\/users\/(\d+)\/(\w+)\/(.+)/)
          if m[2] != p.key
            puts "Wrong project key: #{m[1]} instead of #{p.key}"
          end
        end
        #	if m = r.command_json.match(/\/data\/asap2\/users\/(\d+)\/(\w+)\//)
        #          if (m[1] != r.user_id.to_s and r.user_id) or m[1] != p.key
        #             r.command_json.gsub!(/\/data\/asap2\/users\/(\d+)\/(\w+)\//,  
        #          end
        

        #	end
	
        puts r.command_json.gsub(/\{"opt"\:"\-f","param_key"\:null,"value"\:".+?_filtered.json"\}/, "{\"opt\":\"-f\",\"param_key\":null,\"value\":\"#{filtered_de_filename}\"}")
	

          

        exit

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

end
