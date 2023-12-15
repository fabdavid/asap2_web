desc '####################### remove imported fca annotations'
task :remove_imported_fca_annotations, [:project_key, :metadata_name] => [:environment] do |t, args|
  puts 'Executing...'
  
  #  args[:project_keys].split(":").each do |project_key|  
  
  projects = Project.where(["name ~ 'FlyCellAtlas'"]).all.select{|p| p.shares.size > 20}
  
  annot_name = "/col_attrs/Consensus.Crowd.Annotation"
  
  projects.each do |p|

    if p.archive_status_id != 1
      cmd = "rails unarchive[#{p.key}]"
      puts cmd
      `#{cmd}`
    end

    annot = Annot.where(:project_id => p.id, :name => annot_name).first
    if annot
      run = annot.run
      puts "destroy #{annot.name}'s run (#{run.id}) in #{p.name}"
       RunsController.destroy_run_call(p, run)    
    end		 
  end
  
  
end
