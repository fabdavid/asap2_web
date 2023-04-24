desc '####################### Execute run'
task :exec_run, [:run_id] => [:environment] do |t, args|
  puts 'Executing...'
  
  logger = Logger.new("log/exec_run.log")
  run = Run.find(args[:run_id])

  run.update_attribute(:submitted_at, Time.now)  

  ## check if the project is not archived, and if it is unarchive first
  project = run.project     
  if project.archive_status_id == 3
    Basic.unarchive(project.key)	
  end
  
  Basic.exec_run(logger, run) 
  
end
