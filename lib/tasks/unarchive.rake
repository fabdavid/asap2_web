desc '####################### unarchive projects'
task :unarchive, [:project_key] => [:environment] do |t, args|
  puts 'Executing...'

  now = Time.now
  puts "Uncompressing #{args[:project_key]}..."
  
  Basic.unarchive(args[:project_key])

end
