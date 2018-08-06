module Basic

#class Basic

  class << self
    def t
      puts 't'
    end

    def create_job(o, step_id, project, job_id_key, speed_id = 1)
      h = {:project_id => project.id, :step_id => step_id,  :status_id => 1, :speed_id => speed_id}
      job = Job.new(h)
      job.save
      o.update_attributes({job_id_key => job.id, :status_id => 1})
      return job
    end
    
    def finish_step(logger, start_time, project, step_id, o, output_file, output_json)
      
      project_step = ProjectStep.where(:project_id => project.id, :step_id => step_id).first

      #      logger.debug("BLA")

      ### check if there is not a step < 4 that is also < current project step that was updated after the last update of this step.
      
      #project_steps = ProjectStep.where("project_id = #{project.id} and step_id < 4 and step_id < #{step_id}")
      #alert = 0
      #project_steps.each do |ps|
      #  if ps.updated_at > project_step.updated_at
      #    alert = 1
      #    break
      #  end
      #end
      
      #if alert == 0
      
      results = {}
      if output_json and File.exists?(output_json)
        begin
          results = JSON.parse(File.read(output_json))
        rescue Exception => e
        end
      end

      logger.debug("JSON1: #{results.to_json}")

      duration = Time.now - start_time
      if File.exists?(output_file) and !results["original_error"] and !results["displayed_error"]
        logger.debug("SUCCESSFUL #{o.id}")
        o.update_attributes(:duration => duration, :status_id => 3)       
        if step_id != 4
          project.update_attributes(:duration => duration, :status_id => 3)
          project_step.update_attributes(:status_id => 3)
        end
      else
        logger.debug("FAILED #{o.id}")
        o.update_attributes(:duration => duration, :status_id => 4)
        if step_id != 4 and project_step.status_id != nil ## second part of condition to prevent to update project_step when a job is killed when an earlier step is restarted (necessary if the kill is slower than the update of the ps.status to nil)
          project.update_attributes(:duration => duration, :status_id => 4)
          project_step.update_attributes(:status_id => 4)
        end
      end
      
      # end
    end
    
    def kill_job(logger, job)
      pid = (job) ? job.pid : nil
      if job 
        delayed_job = Delayed::Job.where(:id => job.delayed_job_id).first
        ### delete the job and delayed job if they are pending
        if job.status_id == 1
          delayed_job.destroy if delayed_job
          job.destroy        
        else
          if pid and `ps -ef | egrep '^rvmuser +#{pid} +' | wc -l`.to_i > 0
            
            ## kill main process                                                                                                                                                                                                                                                
            Process.kill('INT', pid) #Process::kill 0, job.pid                                                                                                                                                                                                              
            ## kill remaining children processes                                                                                                                                                                                                                                 
            processes = Sys::ProcTable.ps.select{ |pe| pe.ppid == pid }
            logger.debug("KILL CHILDREN: #{processes.map{|pe| pe.pid}}")
            processes.each do |pe|
              Process.kill('INT', pe.pid)
          end
            job.update_attributes(:status_id => 5)
            delayed_job.destroy if delayed_job
          end
        end
      end
    end

    def kill_jobs(logger, project_id, step_id, o =nil)
      jobs = []
#      if step_id < 5
      jobs = Job.where(:project_id => project_id, :step_id => step_id, :status_id => 2).all.to_a
      logger.debug("JOBS_TO_KILL: #{jobs.size}")
      if step_id == 4
        jobs = jobs.select{|j| j.command_line.match(/#{o.dim_reduction.name}/)}
      end
      logger.debug("JOBS_TO_KILL_2: " + jobs.size.to_s)
      
      jobs.each do |job|
        kill_job(logger, job)
#        if job and `ps -ef | egrep '^rvmuser +#{job.pid} +' | wc -l`.to_i > 0
#          ## kill main process
#          Process.kill('INT', job.pid) #Process::kill 0, job.pid 
#          ## kill children processes
#          processes = Sys::ProcTable.ps.select{ |pe| pe.ppid == job.pid }
#          logger.debug("KILL CHILDREN: #{processes}")
#          processes.each do |pe|
#            Process.kill('INT', pe.pid)
#          end
#          job.update_attributes(:status_id => 5)
#        end
      end
      #     end
    end

#     job = Basic.run_job(logger, cmd, self, self, 1, output_file, output_json, queue, self.parsing_job_id, self.user)

    def run_job(logger, cmd, project, o, step_id, output_file, output_json, queue, job_id, user)
      
      start_time = Time.now
      
      logger.debug("CMD: " + cmd)

#      jobs = []
#      if step_id < 5
#        Basic.kill_jobs(logger, project.id, step_id, o)
#      end
      
      #      project_step = ProjectStep.where(:project_id => project.id, :step_id => step_id).first
      ### search potentially running script                                                                                                                    
      
      pid = spawn(cmd)

      job = Job.find(job_id)

      h_job = {
        :project_id => project.id,
        :step_id => step_id,
        :command_line => cmd,
        :status_id => 2,
        :user_id => (user) ? user.id : 1,
        :speed_id => queue,
        :pid => pid
      }
#      job = Job.new(h_job)
#      job.save
      job.update_attributes(h_job)

#      job_id_fields = [:parsing_job_id, :filtering_job_id, :normalization_job_id]
#      if step_id < 4
#        o.update_attribute(job_id_fields[step_id-1], job.id)
#      else
#        o.update_attribute(:job_id, job.id)
#      end

      Process.waitpid(pid)
      #      launch_cmd(cmd, self)                                                                                                                                           
      logger.debug "CMD_STATUS: #{$?.stopped?}" 

      if ! $?.stopped?  #(job and ! $?.stopped?) or (results["original_error"] or results["displayed_error"])
      
        results = {}
        if  File.exists?(output_json)
          begin
            results = JSON.parse(File.read(output_json))
          rescue Exception => e
            results['displayed_error']='Bad format'
            File.open(output_json, 'w') do |f|
              f.write(results.to_json)
            end
          end
        end
  
        ### update duration                                                                                                                                                        
        duration = Time.now - start_time
        if File.exist?(output_file) and !results["original_error"] and !results["displayed_error"]
          job && job.update_attributes(:status_id => 3, :duration => duration)
        else
          job && job.update_attributes(:status_id => 4, :duration => duration)
        end
        
      end
      return job
      
    end

#    def create_job(cmd, project)
#      
#    end
    
    def launch_cmd(command, obj)
       logger.debug("CMD2: " + command)

    pid = spawn(command)
    obj.update_attribute(:pid, pid)
    while 1 do
      alive?(pid)
      sleep 3
    end
  end

  def alive?(pid)
    !!Process.kill(0, pid) rescue false
  end

  def sum(t)
    sum=0
    t.select{|e| e}.each do |e|
      sum+=e
    end
    return sum
  end

  def mean(t)
    sum=0
    t.select{|e| e}.each do |e|
      sum+=e
    end
    return (t.size > 0) ? sum.to_f/t.size : nil
  end

  def median(t1)
    t=t1.select{|e| e}.sort
    n=t.size
    if (n >0)
      if (n%2 == 0)
        return mean([t[(n/2)-1], t[n/2]])
      else
       # puts n/2                                                                                                                           
        return t[n/2]
      end
    else
      return nil
    end
  end

  def std_dev(t)
    t=t.select{|e| e}
    n=t.size
    if (n >0)
      m=mean(t)
      tot=0
      t.map{|e| tot+=(e-m)**2}
      return (tot / n)**0.5
    else
      return nil
    end
  end

  def min(t)
    return t.select{|e| e}.sort.first
  end

  def max(t)
    return t.select{|e| e}.sort.last
  end
end
end
