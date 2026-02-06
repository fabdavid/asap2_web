desc '####################### Clean'
task clean: :environment do
  puts 'Executing...'
  
  now = Time.now
  
  ## remove old sandbox projets
  
  Project.where("sandbox is true or (public is false and user_id = 1 and cloned_project_id is not null)").all.each do |p|
    if u = (p.session) ?  p.session.updated_at : p.updated_at		 
      d = now - u
      if d > 24 * 60 * 60 * 15
        puts "Deleting #{p.key}..."
        ProjectsController.new.delete_project(p)
      else
	puts "Keep project #{p.key}"
      end
    else
      puts "No session for #{p.key} => delete"
      ProjectsController.new.delete_project(p)  	   
    end
    
  end
  
  
  
  ## remove fus that are not associated with any project anymore
  
  # get all symbolic links
  #  symlinks = `find /data/asap2/users -type l -exec readlink -f {} +`.split("\n")
  #  h_used_fus = {}
  
  ## get all referenced fus
  h_fu_ids = {}
  Project.all.map{|p| h_fu_ids[p.fu_id] = 1}
  old_fus_dir = Pathname.new(APP_CONFIG[:data_dir]) + 'old_fus'
  fus_dir =  Pathname.new(APP_CONFIG[:data_dir]) + 'fus'
  
  Fu.all.each do |fu|
    if !h_fu_ids[fu.id]
      puts "Delete fu " + fu.id.to_s
      # fu.destroy
      fu_dir = fus_dir + fu.id.to_s
      # FileUtils.rm_r fu_dir 
      if File.exist? fu_dir
        FileUtils.rm_r fu_dir
        # FileUtils.mv fu_dir, old_fus_dir
      end
    end
  end
  
  Dir.new(fus_dir).entries.select{|e| File.directory?(fus_dir + e) and e.match(/^\d+$/)}.each do |d|
    if !h_fu_ids[d.to_i]
      puts "Delete fantom directory : " + d
      fu_dir = fus_dir + d
      if File.exist? fu_dir
        FileUtils.rm_r fu_dir
        #      FileUtils.mv fu_dir, old_fus_dir
      end
    end
  end
  
end
