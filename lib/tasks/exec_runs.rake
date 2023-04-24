desc '####################### Execute runs'
task exec_runs: :environment do
  puts 'Executing...'
  # at each pass in the loop, gets only one run and test each time the condition to not start the next run in the queue

#  require 'Basic'
  now = Time.now
#  project = Project.where(:key => 'xdlsz5').first  
  host_name = 'localhost'
  max_nber_runs = 40
  max_nber_cores = 80
  max_memory = 250000000
  run_timeout = 1.day
  
  h_fairplay = {}
  
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
  #  if running_runs.size > 0
  puts "#{running_runs.size} running runs"
  running_runs.each do |run|
    #    ## kill
    #    Basic.kill_run(run)
    #    ## resend in the queue
    #    run.update_attribute(:status_id, 1)
    puts run.id    
    ## check if the run actually runs
    if Basic.is_running(run)
      puts "Still running #{run.id}"
      threads.push({:run => run})
    else
      puts "Finish run #{run.id}"
      
      h_results = {}	
      Basic.finish_run logger, run, h_results
    end
  end
  #end
  puts "INIT_THREADS = " + threads.to_json 
  
  h_delayed_runs = {}
  
  while(1)
    
    #       puts "Round #{round}..."
    #  Job.where(:status_id => 1).order(:created_at).all.each do |job|
    # fake_list_jobs.select{|j| !h_finished_jobs[j]}.each do |job|
    
    #puts "CHECK_THREADS = #{threads.to_json}"
    
    ### remove finished threads
    h_containers = Basic.list_containers(host_name)
    puts h_containers.to_json
    threads.reject!{|t| #t[:thread].status == false or                                                                                                                     
      [3, 4].include?(t[:run].status) or !h_containers['asap_dev_' + t[:run].id.to_s]
    }
    
    #puts "CHECK_THREADS2 = #{threads.to_json}"

    ### determine which run to start
    
    runs = []
    old_logger = ActiveRecord::Base.logger
    ActiveRecord::Base.logger = nil
    runs = Run.where(:status_id => 1).order(:created_at).all.to_a
    running_runs = Run.where(:status_id => 2).order(:created_at).all.to_a
    
    ##reset h_fairplay if they have all had one run executed
    
    v = h_fairplay.values
    k = h_fairplay.keys
    if v.size > 0 and k.size == v.sum
      h_fairplay = {}
    end
    
    ##initialize h_fairplay
    all_users = runs.map{|r| r.user_id}.uniq
    all_users.map{|uid| h_fairplay[uid] ||=0}
    
    ##select next user to be served
   # user_id = all_users.select{|uid| h_fairplay[uid]==0}.first
    user_id = all_users.sort{|a, b| h_fairplay[a] <=> h_fairplay[b]}.first
    
    puts "ALL_USERS: " + all_users.to_json
    puts "USER_ID: " + user_id.to_s
    ActiveRecord::Base.logger = old_logger
    #    runs.each do |run|
    # run = job.run
    all_user_runs = Run.where(:status_id => 1, :user_id => user_id).order(:created_at).all
    all_user_runs_not_delayed = all_user_runs.reject{|r| h_delayed_runs[r.id]}
    puts "H_DELAYED_RUNS: " + h_delayed_runs.keys.join(",")
    if all_user_runs == all_user_runs_not_delayed
      h_delayed_runs = {}
    end
    run = all_user_runs_not_delayed.first
    puts "RUNs_not_delayed:" +  all_user_runs_not_delayed.map{|r| r.id}.to_json

    run = all_user_runs.first if !run

    flag_run = 0
    if run #all_user_runs.size > 0 and all_user_runs.selectrun = all_user_runs.first
      
      h_delayed_runs.delete(run.id) if h_delayed_runs[run.id]
      
      puts "EVALUATING RUN " + run.id.to_s
      
      #   h_containers = Basic.list_containers(host_name)
      
      ### check finished threads and remove them    
      #threads.each do |t| 
      #  if t[:thread].status == false
      #    h_finished_runs[t[:run].id] = 1 
      #   # puts "Finished run #{t[:run]}!"
      #  end
      #end
      #  
      #  threads.reject!{|t| #t[:thread].status == false or
      #    [3, 4].include?(t[:run].status) or !h_containers['asap_dev_' + t[:run].id.to_s] 
      #  }
      
      #puts threads.size.to_s + " threads running; finished runs: #{h_finished_runs.keys.size}"
      #puts 'RAM USAGE: ' + `pmap #{Process.pid} | tail -1`[10,40].strip
      #must do the RAM check using the predictive RAM 
      
      ### go off the loop if the max number of cpus is reached
      #puts  "THREADS: " + threads.map{|thread| thread[:run].std_method.nber_cores}.to_json
      nber_cores_running = (threads.size > 0) ? threads.map{|thread| (std_method = thread[:run].std_method and std_method.nber_cores) ? std_method.nber_cores : 1}.compact.sum : 0
      puts "NBER_CORES_RUNNING: "  + nber_cores_running.to_s
      #           puts "!!!!" + nber_cores_running.to_s
      #puts run.std_method.nber_cores
      
      free_mem = `free -k`.split("\n")[1].split(/\s+/)[6].to_i
      #      sum_pred_max_ram = 0
      running_runs_with_pred = running_runs.select{|r| r.pred_max_ram}
      #      if running_runs.size > 0
      free_mem2 = max_memory - ((running_runs_with_pred.size > 0) ? running_runs_with_pred.map{|r| r.pred_max_ram}.compact.sum : 0)
      puts "FREE_MEM: " + free_mem.to_s 
      puts "FREE_MEM2: " + free_mem2.to_s
      puts "MACHINE_LOAD: " + Basic.machine_load.to_s
      puts "PRED_MAX_RAM:  " + run.pred_max_ram.to_s
      #      grep -R pred_max_ram

      unless (nber_cores_running + ((std_method = run.std_method and std_method.nber_cores) ? std_method.nber_cores : 1) > max_nber_cores or               
              threads.size + 1 == max_nber_runs or
              Basic.machine_load > 80 or 
              (run.pred_max_ram and #and `free -k`.split("\n")[1].split(/\s+/)[3].to_i and
               #     free_mem = max_memory - ((running_runs.size > 0) ? running_runs.map{|r| r.pred_max_ram}.sum : 0) and
               # free_mem = `free -k`.split("\n")[1].split(/\s+/)[3].to_i and 
               (free_mem - (run.pred_max_ram * 1.2) + 10000000 < 0 or
                free_mem2 - (run.pred_max_ram * 1.2) + 10000000 < 0 #or nber_cores_running > 0 
                )))
        
        pipeline_run_ids = run.pipeline_parent_run_ids.split(",")
        nber_successful_pipeline_runs = (pipeline_run_ids.size > 0) ? Run.where(:id => pipeline_run_ids, :status_id => 3).size : 0
        if pipeline_run_ids.size == nber_successful_pipeline_runs
          
          
          puts "STARTING RUN " + run.id.to_s
          output_dir = get_output_dir run
          logfile = output_dir + "output.log"
          
          cmd = "rails exec_run[#{run.id}] --trace 1> #{logfile.to_s} 2> #{logfile.to_s}"
          puts "CMD: " + cmd
          threads.push({
                         :run => run, 
                         :thread => Thread.new { 
                           run.update_attributes(:status_id => 2)
                           `#{cmd}`
                         }
                       })
          puts "Added a thread"
          #        puts threads.map{|t| t[:thread].status_id}
	  flag_run = 1
          h_fairplay[user_id] = 1
        else
          if Run.where(:id => pipeline_run_ids, :status_id => 4).size > 0
            run.update_attributes({:status_id => 4})
          else
            h_delayed_runs[run.id] = 1
          end
          puts "NBER_SUCCESSFUL_PIPELINE_RUNS=" + nber_successful_pipeline_runs.to_s
          puts "PIPELINE_RUN_IDS" + pipeline_run_ids.to_json
          h_fairplay[user_id] = 1 
        end
      else
        if run.pred_max_ram and run.pred_max_ram > 200000000
          h_results = {:displayed_error => ["Not enough memory on this server (rejected if predicted memory exceeds 200Gb). Please try to run an alternative method."]}
          output_dir = get_output_dir run
          output_json_filename = output_dir + 'output.json'          
          File.open(output_json_filename, 'w') do |f|
            f.write(h_results.to_json)
          end
          run.update_attributes(:status_id => 5)
          Basic.upd_project_step run.project, run.step_id
        else
          h_delayed_runs[run.id] = 1
          h_fairplay[user_id] = 1
	end
      end

    end 
    
    
    round += 1
    sleep 3 if flag_run == 1
  end   
  
end
