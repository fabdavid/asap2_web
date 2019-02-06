desc '####################### Execute runs'
task exec_runs: :environment do
  puts 'Executing...'

  require 'Basic'
  now = Time.now
#  project = Project.where(:key => 'xdlsz5').first  
  max_nber_cores = 5
  max_nber_memory = 5000000000
  run_timeout = 1.day

  fake_list_jobs  = (0 .. 100).to_a

  threads = []
  h_finished_runs = {}

  # test broadcast => works
  #project.broadcast 1

  def fake_run
    
    s = 0
    h = {}
    (1 .. 1000000).each do |a|
      s+= (a + 2/a)
      h[s] = s+3
    end
    begin
    t = `ls bla`
    rescue
     end	
    puts s.to_s + " " + t.to_s
    
  end
 
  round = 0

  ### reinitialize runs/jobs that have running status and kill possible jobs

  while(1)
    
    puts "Round #{round}..."
    #  Job.where(:status_id => 1).order(:created_at).all.each do |job|
   # fake_list_jobs.select{|j| !h_finished_jobs[j]}.each do |job|
    runs = Run.where(:status_id => 1).order(:created_at).all
    runs.each do |run|
    # run = job.run
      
      ### check finished threads and remove them    
      threads.each do |t| 
        if t[:thread].status == false
          h_finished_jobs[t[:job]] = 1 
          puts "Finished job #{t[:job]}!"
        end
      end
      threads.reject!{|t| t[:thread].status == false}    

      puts threads.size.to_s + " threads running; finished runs: #{h_finished_runs.keys.size}"
      #puts 'RAM USAGE: ' + `pmap #{Process.pid} | tail -1`[10,40].strip
      #must do the RAM check using the predictive RAM 

      ### go off the loop if the max number of cpus is reached
      if threads.size == max_nber_cores
        break
      end
      
      threads.push({
      :job => job, 
      :thread => Thread.new { Basic.exec_run(run) }
      })
      puts "Added a thread"
      puts threads.map{|t| t[:thread].status}
      
    end
    
    round += 1
    sleep 1
  end   
  
end
