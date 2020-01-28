desc '####################### Clean'
task clean_de_tmp_files: :environment do
  puts 'Executing...'

  now = Time.now
  
  def delete f
  if File.exist? f
    puts "Delete #{f}"
    File.delete f
  end
  end


  Project.all.each do |project|
    project_dir =  Pathname.new(APP_CONFIG[:user_data_dir]) + project.user_id.to_s + project.key
    if File.exist?(project_dir + "tmp")
      Dir.new(project_dir + "tmp").entries.each do |e|
        delete(project_dir + e) if File.directory?(project_dir + e) == false
      end
    end	
    delete(project_dir + "de" + "filtered_stats.json")
    project.runs.select{|r| r.step_id == 6}.each do |r|	
      run_dir = project_dir + 'de' + r.id.to_s		
      delete(run_dir + "output.txt")		
      delete(run_dir + "filtered_up.json")	
      delete(run_dir + "filtered_down.json")
    end   		  
  end
  
end
