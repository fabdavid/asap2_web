desc '####################### fix_ge_output_json'
task fix_ge_output_json: :environment do
  puts 'Executing...'

  now = Time.now

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

    ge_runs = p.runs.select{|r| h_steps[r.step_id].name == 'ge' and File.exist?( project_dir + 'ge' + r.id.to_s + 'output.json')} # and r.command_json.match(/_filtered.json/)}#.select{|r| r.command_json.match(/\{"opt"\:"\-F","param_key"\:null,"value"\:".+?_filtered.json"\}/)}

    	    
    ge_runs.each do |ge_run|
puts "Run #{ge_run.id}..."
   
      ge_run_dir = project_dir + 'ge' + ge_run.id.to_s
      output_json = ge_run_dir + 'output.json'
      if File.exist? output_json
        json = File.read(output_json)
        if json.match(/\"\\N\"/)
	puts "found Null"
          File.open(output_json, 'w') do |fw|
            fw.write(json.gsub(/\"\\N\"/, "null"))
#            puts json.gsub(/\"\\N\"/, "null")
          end
        end
      end
      
    end
    
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
