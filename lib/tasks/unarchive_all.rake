desc '####################### Unarchive all'
task unarchive_all: :environment do
  puts 'Executing...'

  now = Time.now

  ## remove old sandbox projets
  
  Project.all.each do |p|
    project_dir = Pathname.new(APP_CONFIG[:data_dir]) + 'users' + p.user_id.to_s + p.key
    if p.archive_status_id == 3 or !File.exist? project_dir
     Basic.unarchive(p.key)
    end
  end
  
end
