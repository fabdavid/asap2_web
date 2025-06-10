desc '####################### Rearchive'
task rearchive: :environment do
  puts 'Executing...'
  
  now = Time.now

  fus_dir = Pathname.new(APP_CONFIG[:upload_data_dir])
  fu_ids = Dir.entries(fus_dir).select{|e| e.match(/^\d+$/)}

  project_ids = Fu.where(:id => fu_ids).all.map{|e| e.project_id}
  projects = Project.where(:id => project_ids, :archive_status_id => 3).all

  projects.each do |p|

    #unarchive
    
    cmd = "rails unarchive[#{p.key}]"
    puts cmd
    `#{cmd}`
    
    #archive
    cmd = "rails archive[#{p.key}]"
    puts cmd
    `#{cmd}`

  end
end
