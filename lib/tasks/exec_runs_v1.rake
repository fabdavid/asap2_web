desc '####################### Execute runs'
task exec_runs_v1: :environment do
  puts 'Executing...'
### NOTE executing at each pass in the loop, it loads several runs until the breaking condition is reached


#  require 'Basic'
  now = Time.now
#  project = Project.where(:key => 'xdlsz5').first  
  host_name = 'localhost'
  max_nber_runs = 40
  max_nber_cores = 80
  max_nber_memory = 200000000000
  run_timeout = 1.day

  logger = Logger.new("log/exec_runs.log")

#  fake_list_jobs  = (0 .. 100).to_a

  threads = []
  h_finished_runs = {}

  def get_output_dir run
 
    project = run.project
    step = run.step
    project_dir = Pathname.new(APP_CONFIG[:user_data_dir]) + project.user_id.to_s + project.key
    step_dir = project_dir + step.name
    Dir.mkdir step_dir if !File.exist? step_dir
    output_dir = (step.multiple_runs == true) ? (step_dir + run.id.to_s) : step_dir  
    Dir.mkdir output_dir if !File.exist? output_dir  
    return output_dir
  end

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

  ### reinitialize threads that have running status and kill possible jobs

  running_runs = Run.where(:status_id => 2).order(:created_at).all
  running_runs.each do |run|
#    ## kill
#    Basic.kill_run(run)
#    ## resend in the queue
#    run.update_attribute(:status_id, 1)
    threads.push({:run => run})
  end
  
  while(1)
    
#       puts "Round #{round}..."
    #  Job.where(:status_id => 1).order(:created_at).all.each do |job|
   # fake_list_jobs.select{|j| !h_finished_jobs[j]}.each do |job|

    runs = []
    old_logger = ActiveRecord::Base.logger
    ActiveRecord::Base.logger = nil
    runs = Run.where(:status_id => 1).order(:created_at).all.to_a
    ActiveRecord::Base.logger = old_logger
    runs.each do |run|
      # run = job.run
#      if run = runs.first
      h_containers = Basic.list_containers(host_name)
      
      ### check finished threads and remove them    
      #threads.each do |t| 
      #  if t[:thread].status == false
      #    h_finished_runs[t[:run].id] = 1 
      #   # puts "Finished run #{t[:run]}!"
      #  end
      #end
      
      threads.reject!{|t| #t[:thread].status == false or
        [3, 4].include?(t[:run].status) or !h_containers['asap_dev_' + t[:run].id.to_s] 
      }
      
      #puts threads.size.to_s + " threads running; finished runs: #{h_finished_runs.keys.size}"
      #puts 'RAM USAGE: ' + `pmap #{Process.pid} | tail -1`[10,40].strip
      #must do the RAM check using the predictive RAM 
      
      ### go off the loop if the max number of cpus is reached
      puts  threads.map{|thread| thread[:run].std_method.nber_cores}.to_json
      nber_cores_running = (threads.size > 0) ? threads.map{|thread| (std_method = thread[:run].std_method and std_method.nber_cores) ? std_method.nber_cores : 1}.compact.sum : 0
      #           puts "!!!!" + nber_cores_running.to_s
      #puts run.std_method.nber_cores 
      if nber_cores_running + ((std_method = run.std_method and std_method.nber_cores) ? std_method.nber_cores : 1) > max_nber_cores or 
        threads.size + 1 == max_nber_runs or
        Basic.machine_load > 5
        break
      end
      
      output_dir = get_output_dir run
      logfile = output_dir + "output.log"
      cmd = "rails exec_run[#{run.id}] --trace 1> #{logfile.to_s} 2> #{logfile.to_s}"
      #puts "CMD: " + cmd
      threads.push({
                     :run => run, 
                     :thread => Thread.new { 
                       run.update_attributes(:status_id => 2)
                       `#{cmd}`
                     }
                   })
      # puts "Added a thread"
      # puts threads.map{|t| t[:thread].status}
      
    end
    
    round += 1
    sleep 1
  end   
  
end
