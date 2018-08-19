desc '####################### Restart delayed_jobs'
task restart_dj: :environment do
  puts 'Executing...'

  now = Time.now
  
  Job.where(:status_id => 2).all.each do |j|
  
    if j.project
      puts j.project
    else
      
    end
  end
    
end
