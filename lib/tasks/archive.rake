desc '####################### archive projects'
task archive: :environment do
  puts 'Executing...'

  now = Time.now
  ## time after which the project is archived
  active_time = 2.day

  #  Project.where(:archive_status_id => 1).all.each do |p|
  Project.all.each do |p|
    base_dir =  Pathname.new(APP_CONFIG[:user_data_dir]) + p.user_id.to_s
    project_dir = base_dir + p.key
    #   ## delete tgz file if it exists
    #   File.delete "#{project_dir}.tgz" if File.exist? "#{project_dir}.tgz"
    
    if Time.now - p.viewed_at > active_time
      
      ## delete tgz file if it exists                                                                                                                         
      File.delete "#{project_dir}.tgz" if File.exist? "#{project_dir}.tgz"

      p.update_attributes(:archive_status_id => 2)
      #      project_dir =  Pathname.new(APP_CONFIG[:user_data_dir]) + p.user_id.to_s + p.key
      
      ## tar and pigz
      #      tar -cf -  -C /data/asap2/users/1 jgf9d1
      cmd = "tar -cf - -C #{base_dir} #{p.key} | pigz -9 -p 32 > #{project_dir}.tgz"
      puts cmd
      `#{cmd}`
      p.update_attributes(:archive_status_id => 3, :disk_size_archived => File.size("#{project_dir}.tgz"))
       if File.exist? "#{project_dir}.tgz" and File.size("#{project_dir}.tgz") > 0
         FileUtils.rm_r(project_dir)
       end	     
    end
  end
end
