desc '####################### Import metadata'
task :remove_imported_metadata, [:project_key, :metadata_name] => [:environment] do |t, args|
  puts 'Executing...'

#  args[:project_keys].split(":").each do |project_key|  
    
   project = Project.where(:key => args[:project_key]).first

   annot = Annot.where(:project_id => project.id, :name => args[:metadata_name]).first
  
  puts "destroy #{annot.name}'s run (#{run.id}) in #{project.name}" 
  # RunsController.destroy_run_call(project, annot.run)  
  
end
