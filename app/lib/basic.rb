module Basic

#class Basic

  class << self

    def upd_run run, h_upd
      run.update_attributes(h_upd)
      if active_run = run.active_run and h_upd[:status_id] == 4
        active_run.delete
      end
    end

    def set_run h_p

      h_res = {}

      project_dir = Pathname.new(APP_CONFIG[:user_data_dir]) + h_p[:project].user_id.to_s + h_p[:project].key
      run = h_p[:run] #list_of_runs[run_i][0]
      p = h_p[:p] #list_of_runs[run_i][1]

      docker_image = h_p[:h_cmd_params]['docker_image']
      
      h_var = {
        'output_dir' => project_dir + h_p[:step].name + run.id.to_s,
        'std_method_name' => h_p[:std_method].name
      }
      
      run_parents = []
      
      p.each_key do |k|
        #logger.debug("bly: #{k.to_s} #{@h_attrs.to_json} #{@h_attrs[k.to_s].to_json}")                                                                                                            
        if h_p[:h_attrs][k.to_s] and h_p[:h_attrs][k.to_s]['valid_types']
          if h_p[:h_attrs][k.to_s]['valid_types'].include?('num_matrix')
            linked_run = Run.where(:id => p[k]['run_id']).first
            h_linked_run_outputs = nil
            if !linked_run
              h_res[:error] = 'Linked run was not found!'
            else
              h_linked_run_outputs = JSON.parse(linked_run.output_json)
              h_linked_run_outputs[p[k]['output_attr_name']].each_key do |k2|
                h_var[k + "_" + k2] = h_linked_run_outputs[p[k]['output_attr_name']][k2]
              end
              run_parents.push({
                                 :run_id => linked_run.id,
                                 :type => 'num_matrix',
                                 :output_attr_name => p[k]['output_attr_name'],
                                 :filename => h_linked_run_outputs[p[k]['output_attr_name']]['filename'],
                                 :dataset => h_linked_run_outputs[p[k]['output_attr_name']]['dataset'],
                                 :output_json_filename => (oj = h_linked_run_outputs['output_json']) ? oj['filename'] : nil,
                                 :input_attr_name => k.to_s 
                               })
            end
          end
        else
          h_var[k] = p[k]
        end
      end
      
      ## define if predictable = there is one matrix as input                                                                                                                                      
      matrix_runs = run_parents.select{|parent| parent[:type] == 'num_matrix'}
      predictable = (matrix_runs.size == 1) ? true : false
      if predictable
        matrix_run = matrix_runs.first
        h_output_json = JSON.parse(File.read(project_dir + matrix_run[:output_json_filename]))
        h_var['nb_cols'] = h_output_json['nb_cols']
        h_var['nb_rows'] = h_output_json['nb_rows']
      end
      
      list_args = []
      if h_p[:h_cmd_params]['args']
          h_p[:h_cmd_params]['args'].each do |h_arg|
          list_args.push({:param_key => h_arg['param_key'], :value => h_var[h_arg['param_key']] })
        end
      end
      
      list_opts = []
      if h_p[:h_cmd_params]['opts']
        h_p[:h_cmd_params]['opts'].each do |opt|
          list_opts.push(opt)
        end
      end
      
      h_cmd = {
        :docker_call => (docker_image) ? h_p[:h_env]['docker_images'][docker_image]['call'] : nil,
        :time_call => h_p[:h_env]['time_call'].gsub(/(\#[\w_]+)/) { |var| h_var[var[1..-1]] },
        :program =>  h_p[:h_cmd_params]['program'],
        :args => list_args,
        :opts => list_opts
      }
        
        if predictable
          
        h_predict_params = {}
        h_p[:h_cmd_params]['predict_params'].each do |pp|
          h_predict_params[pp] = h_var[pp]
        end
        
        h_cmd[:expected_duration] = Basic.predict_duration(h_predict_params)
        h_cmd[:expected_ram] =  Basic.predict_ram(h_predict_params)
      end
      
      run.update_attributes({:command_json => h_cmd.to_json, :run_parents_json => run_parents.to_json});
      
      return h_res
      
    end

    def init_active_run run    
      h_res = {}
      h_active_run = run.as_json
      h_active_run[:run_id] = run.id
      ar = ActiveRun.new(h_active_run)
      ar.save!
      return h_res
    end

    def predict_ram h_predict_param
      return nil
    end

    def predict_duration h_predict_param
      return nil
    end

    def build_cmd h_cmd
      cmd_core = [h_cmd['time_call'], h_cmd['program'], h_cmd['opts'].map{|e| "#{e['opt']} #{e['value']}"}.join(" "), h_cmd['args'].map{|e| e['value']}].compact.join(" ")
      cmd = ""
      if h_env['docker_call']
        cmd = h_env['docker_call'] + "\"" + cmd_core + "\""
      end
      return cmd
    end

    def exec_run run
      
      start_time = Time.now
      project = run.project      
      version = project.version
      step = run.step

      project_dir = Pathname.new(APP_CONFIG[:user_data_dir]) + project.user_id.to_s + project.key 
      step_dir = project_dir + step.name
      Dir.mkdir step_dir if !File.exist? step_dir
      output_dir = (step.multiple_runs == true) ? (step_dir + run.id.to_s) : step_dir
      Dir.mkdir output_dir if step.multiple_runs == true and !File.exist? output_dir

      h_env = JSON.parse(version.env_json)
      
      h_cmd = JSON.parse(run.command_json)
      
      cmd = build_cmd(h_cmd)
      logger.debug("CMD:#{cmd}")
      pid = spawn(cmd)
      
      h_run = {
        :command_line => cmd,
        :status_id => 2,
        :pid => pid
      }
      run.update_attributes(h_run)
      project.broadcast run.step_id

      Process.waitpid(pid)

      logger.debug "CMD_STATUS: #{$?.stopped?}"
      
      if ! $?.stopped?  #(job and ! $?.stopped?) or (results["original_error"] or results["displayed_error"])             

        ## check if expected output files exist
        h_output_json = JSON.parse(step.output_json)        
        h_expected_outputs = (h_output_json) ? h_output_json['expected_outputs'] : nil
        
        results = {}
        found_expected = true
        h_expected_outputs.each_key do |k|
          if !h_expected_outputs[k]['optional']
            filename = output_dir + h_expected_outputs[k]['filename']
            found_expected = false if !File.exist? filename
            if h_expected_outputs[k]['type'] == 'json_file'
              ### check if json results is parseable, if not write an error
              begin
                results = JSON.parse(File.read(filename))
              rescue Exception => e
                results['displayed_error']='Bad format'
                File.open(filename, 'w') do |f|
                  f.write(results.to_json)
                end
              end
            end
            break if found_expected == false
          end
        end

        ### update duration    
        duration = Time.now - start_time
        if found_expected == true and !results["original_error"] and !results["displayed_error"]
          run && run.update_attributes(:status_id => 3, :duration => duration)
        else
          run && run.update_attributes(:status_id => 4, :duration => duration)
        end
        
      end
      
    end
    
    
    def std_run(run)
      h = {:project_id => project.id, :step_id => step_id,  :status_id => 1, :speed_id => speed_id}
      job = Job.new(h)
      job.save
      o.update_attributes({job_id_key => job.id, :status_id => 1})
      return job
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
      
      project.broadcast step_id
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
      
      logger.debug("CMD2: " + cmd)

#      jobs = []
#      if step_id < 5
#        Basic.kill_jobs(logger, project.id, step_id, o)
#      end
      
      #      project_step = ProjectStep.where(:project_id => project.id, :step_id => step_id).first
      ### search potentially running script                                                                                                                    
      file = ''
      if m = cmd.match(/-f ([^ ]+)/)
        file = m[1]
      end
      logger.debug("CMD_ls : " + `ls -alt #{file}`)
      pid = spawn(cmd)
      logger.debug("CMD3: " + cmd)
      logger.debug("CMD_ls2 : " + `ls -alt #{file}`)
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
      project.broadcast step_id
#      job_id_fields = [:parsing_job_id, :filtering_job_id, :normalization_job_id]
#      if step_id < 4
#        o.update_attribute(job_id_fields[step_id-1], job.id)
#      else
#        o.update_attribute(:job_id, job.id)
#      end
      #logger.debug("BLABLABLA")

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
      
#       project.broadcast_new_status
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

  def safe_download(url, filepath, max_size: nil)
    require 'open-uri'
    #    Error = Class.new(StandardError)                                                                                                                                                                                    
    
    #    DOWNLOAD_ERRORS = [                                                                                                                                                                                                 
    #                       SocketError,                                                                                                                                                                                     
    #                       OpenURI::HTTPError,                                                                                                                                                                              
    #                       RuntimeError,                                                                                                                                                                                    
    #                       URI::InvalidURIError,                                                                                                                                                                            
    #                       Error,                                                                                                                                                                                           
    #                      ]                                                                                                                                                                                                 
    
    url = URI.encode(URI.decode(url))
    url = URI(url)
    raise Error, "url was invalid" if !url.respond_to?(:open)
    
    options = {}
    options["User-Agent"] = "MyApp/1.2.3"
    options[:read_timeout] = 10000
    options[:content_length_proc] = ->(size) {
      if max_size && size && size > max_size
        raise Error, "file is too big (max is #{max_size})"
      end
    }
    
    downloaded_file = url.open(options)
    
    if downloaded_file.is_a?(StringIO)
      # tempfile = Tempfile.new("open-uri", binmode: true)                                                                                                                                                                
      IO.copy_stream(downloaded_file, filepath)
      # downloaded_file = tempfile                                                                                                                                                                                        
      # OpenURI::Meta.init downloaded_file, stringio                                                                                                                                                                      
    end
    
    #   downloaded_file                                                                                                                                                                                                     
    
    #  rescue *DOWNLOAD_ERRORS => error                                                                                                                                                                                
    #    raise if error.instance_of?(RuntimeError) && error.message !~ /redirection/                                                                                                                                    
    #    raise Error, "download failed (#{url}): #{error.message}"                                                                                                                                                           
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
