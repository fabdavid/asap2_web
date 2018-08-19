desc '####################### Parse'
task :parse, [:project_id] => [:environment] do |t, args|
  puts 'Executing...'
  
  now = Time.now

  puts args[:project_id]

  project_id = args[:project_id]  
  project = Project.where(:id => project_id).first
  if project
    puts "parse"
    project.parse    
  end
end
