desc '####################### unarchive projects'
task :unarchive, [:project_key] => [:environment] do |t, args|
  puts 'Executing...'

  now = Time.now

  p = Project.find_by_key(args[:project_key])
  p.update_attributes({:archive_status_id => 4})
  project_archive = p.key + '.tgz'
  project_dir = Pathname.new(APP_CONFIG[:user_data_dir]) + p.user_id.to_s
  ## tar and pigz
  cmd = "cd #{project_dir} && tar -zxvf #{project_archive}"
  `#{cmd}`
  p.update_attributes(:archive_status_id => 1, :disk_size_archived => nil)
  
end
