desc '####################### change_step_name'
task change_step_name: :environment do
  puts 'Executing...'

  now = Time.now

  old_name = 'metadata'
  new_name = 'cell_selection'
  
  Project.all.each do |p|
    project_dir =  Pathname.new(APP_CONFIG[:user_data_dir]) + p.user_id.to_s + p.key
    if File.exist?(project_dir + old_name)
      FileUtils.move (project_dir + old_name),  (project_dir + new_name)
    end	
  end
  
end
