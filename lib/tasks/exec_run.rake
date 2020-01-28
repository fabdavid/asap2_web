desc '####################### Execute run'
task :exec_run, [:run_id] => [:environment] do |t, args|
  puts 'Executing...'
  
  logger = Logger.new("log/exec_run.log")
  run = Run.find(args[:run_id])

  run.update_attribute(:submitted_at, Time.now)  
  Basic.exec_run(logger, run) 
  
end
