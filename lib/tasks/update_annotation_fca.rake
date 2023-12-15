desc '####################### Import metadata'
task :update_annotation_fca, [] => [:environment] do |t, args|
  puts 'Executing...'

  filename = '/data/asap2/metadata_to_load/v2_20201127_fca_annotation_cleaned.tsv.gz'
  
#  projects = Project.all.select{|p| p.shares.size > 30}
#   projects = Project.where(["name ~ 'v2' or key = '06y2o7'"]).all

projects = Project.where(["key = 'x96waq'"]).all
   puts projects.map{|p| p.key}

#   exit
#  puts project_keys

  projects.each do |project|
    if project.archive_status_id != 1
      cmd = "rails unarchive[#{project.key}]"
      puts cmd
      `#{cmd}`
    end
    cmd = "rails import_metadata[#{project.key},#{filename},CELL]"
    puts cmd
    `#{cmd}`
    
  end
end
