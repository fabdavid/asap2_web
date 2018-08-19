desc '####################### Parse batch file'
task :parse_batch_file, [:project_key] => [:environment] do |t, args|
  puts 'Executing...'
  
  now = Time.now

  puts args[:project_key]

  project_key = args[:project_key]  
  project = Project.where(:key => project_key).first
  if project
    puts "parse"
    project.parse_batch_file()    
  end
end
