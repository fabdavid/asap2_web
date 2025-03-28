class Req < ApplicationRecord

  belongs_to :project
  belongs_to :step
  belongs_to :std_method
  has_many :runs
  belongs_to :user

  NewRunBatch = Struct.new(:req) do
    def perform
      req.create_runs
    end

    def error(job, exception)
      if job.last_error
        lines = job.last_error.split("\n")
        lines = lines.join("\\n")
        #    parsing_step = Step.where(:version_id => project.version_id, :name => 'parsing').first
        #    project_step = ProjectStep.where(:project_id => project.id, :step_id => parsing_step.id).first
        #    project_step.update_attributes(:error_message => lines, :status_id => 4)
        #    project.update_attributes(:error => lines, :status_id => 4)
      end
    end
  end

  def create_run_batch 
    #self.create_runs
    delayed_job = Delayed::Job.enqueue NewRunBatch.new(self), :queue => 'fast'
    self.update_attributes(:delayed_job_id => delayed_job.id)
  end

  def set_runs list_of_runs2, list_of_h_p 
    project = self.project
    step = self.step
    t = Time.now
    list_of_runs2.each_index do |run_i|
      h_p = list_of_h_p[run_i]
      h_res = Basic.set_run(logger, h_p)
    
#    Basic.upd_project_step project, step.id
    
    #    puts "Elapsed time 10:" + (Time.now-t).to_s
#    list_of_runs2.each_index do |run_i|
      run = list_of_runs2[run_i][0]
      if !h_res[:error]
        #  ### init active_run -- OBSOLETE as active_run is created at the same time as run                                                                                                                                        
        #   h_res = Basic.init_active_run(run)                                                                                                                                                                                     
        if !h_res[:error] and run.async == false
         # logger.debug("START RUN #{run.id} SYNCHRONEOUSLY")
          ## execute run                                                                                                                                                                                                           
          Basic.exec_run(run)
        end
      end
    
      #   puts "Elapsed time 11:" + (Time.now-t).to_s
      #   ActiveRecord::Base.transaction do
      #     list_of_runs2.each_index do |run_i|
 #       run = list_of_runs2[run_i][0]
      
      ### update run status                                                                                                                                                                                                      
      if h_res[:error]
        h_to_upd = {:status_id => 4}
        Basic.upd_run(@project, run, h_to_upd, true)
      end
    end
  end
  

  def add_runs list_of_runs, h_attr_values, attr_name #, applied_combinatorial_run_attrs                                                                                                                                              
    logger.debug("======== #{attr_name} ========")
    logger.debug("LIST_OF_RUNS_attrs: " + list_of_runs.map{|e| e[1]}.to_json)
    
    new_list_of_runs = []
    list_of_runs.each do |tmp_run|
      ### each value                                                                                                                                                                                                                  
      h_attr_values[attr_name].each do |attr|
        new_run = tmp_run[0].dup
        
        ### light version works otherwise uncomment the heavy version (using applied_combinatorial_run_attrs)       
        new_h_attr_values = JSON.parse(new_run.attrs_json)
        new_h_attr_values[attr_name] = attr
        new_run.attrs_json = new_h_attr_values.to_json
        logger.debug("NEW_H_ATTR_VALUES: " + new_h_attr_values.to_json)
        new_list_of_runs.push([new_run, new_h_attr_values])
      end
    end
    logger.debug("new_LIST_OF_RUNS_attrs: " + new_list_of_runs.map{|e| e[1]}.to_json)
    return new_list_of_runs
  end
  
  def create_runs
    project = req.project
    project_dir = Pathname.new(APP_CONFIG[:user_data_dir]) + project.user.id.to_s + project.key
    
    ## create runs                                                                                                       
    # {"input_matrix":{"run_id":"13","output_attr_name":"output_matrix"},"fit_model":"log"}                                                                                                                                           
    h_attr_values = JSON.parse(self.attrs_json)
    std_method = self.std_method
    step = self.step
    h_version = project
    h_attrs = {}
    
    h_data_classes = {}
    DataClass.all.map{|dc| h_data_classes[dc.id] = dc}
    
    if std_method and step
      
      h_cmd_params = JSON.parse(step.command_json)
           logger.debug("blou:" + @h_cmd_params.to_json)                                                                                                                                                                             
      tmp_h = JSON.parse(std_method.command_json)
      tmp_h.each_key do |k|
        h_cmd_params[k] = tmp_h[k]
      end
      
      h_res = Basic.get_std_method_attrs(std_method, step)
      h_attrs = h_res[:h_attrs]
      h_global_params = h_res[:h_global_params]

      combinatorial_run_attrs = h_attrs.keys.select{|k|  h_attrs[k]['combinatorial_runs'] == true and (h_attr_values[k] and h_attr_values[k].size > 0)}
      
      now = Time.now
      ### call the function for each combinatorial_runs                                                                                                                                                                               
      h_run = {
        :req_id => self.id,
        :step_id => @step.id,
        :std_method_id => std_method.id,
        :project_id => project.id,
        :command_json => nil,
        :attrs_json => h_attr_values.to_json,
        :user_id => (current_user) ? current_user.id : 1,
        :num => nil,
        :pid => nil,
        :error => nil,
        :status_id => 6,
        :submitted_at => now,
        :created_at => now,
        :async => h_cmd_params['async']#,    
      }
      list_of_runs = [[Run.new(h_run), {}]]
      #      applied_combinatorial_run_attrs = []                                                                                                                                                                                     
      combinatorial_run_attrs.each do |attr_name|
        list_of_runs = add_runs(list_of_runs, h_attr_values, attr_name) #, applied_combinatorial_run_attrs)                    
      end
      
      ### update params                                                                                                                                                                                                               
      list_of_runs.each_index do |run_i|
        run = list_of_runs[run_i]
        h_run_attrs = JSON.parse(run[0].attrs_json)
        if gp = h_run_attrs['group_pairs'] and gp.size > 0
          h_run_attrs['group_ref'] = gp[0]
          h_run_attrs['group_comp'] = gp[1]
          h_run_attrs['group_pairs'] = nil
          list_of_runs[run_i][0].attrs_json = h_run_attrs.to_json
          list_of_runs[run_i][1] = h_run_attrs
        end
      end
      ### add errors if runs already exists                                                                                                                                                                                           
      list_already_existing_run_i = []
      list_of_runs.each_index do |run_i|
        run = list_of_runs[run_i]
        nber_existing_runs = Run.where(:project_id => project.id, :step_id => step.id, :std_method_id =>  std_method.id, :attrs_json => run[0].attrs_json).count
        if nber_existing_runs > 0
          h_errors[:already_existing]||=0
          h_errors[:already_existing]+=1
          list_already_existing_run_i.push run_i
        end
      end
      
      ### delete already existing runs                                                                                                                                                                                                
      list_of_runs2 = list_of_runs.reject.with_index { |e, run_i| list_already_existing_run_i.include? run_i }
      
      ### define num for each run after creation                                                                                                                                                                                      
      last_run = Run.where(:project_id => project.id, :step_id => step.id).order(:id).last
      i = (last_run) ? (last_run.num+1) : 1
      
      ### write in files some parameters that take too much space and replace in db by a SHA2                                                                                                                                         
      step_dir = project_dir + step.name
      Dir.mkdir step_dir if !File.exist? step_dir
      h_sha2= {}
      h_sha2_values={}
      list_of_runs2.each_index do |run_i|
        run = list_of_runs2[run_i][0]
        # output_dir = (@step.multiple_runs == true) ? (step_dir + run.id.to_s) : step_dir                                                                                                                                            
        #        Dir.mkdir output_dir if !File.exist? output_dir                                                                                                                                                                      
        h_attrs.each_key do |k|
          if filename = h_attrs[k]['write_in_file']                                                             
            
            h_run_attrs = JSON.parse(run.attrs_json)
            sha2 = Digest::SHA2.hexdigest h_run_attrs[k]
            
            h_sha2[run_i] ||= {}
            h_sha2[run_i][k] = sha2
            h_sha2_values[sha2] = h_run_attrs[k]
            h_run_attrs[k] = sha2
            list_of_runs2[run_i][0].attrs_json = h_run_attrs.to_json
          end                 
          
        end
      end
      
      ### save runs                                                                                                                                                                                                                   
      list_of_runs2.each_index do |run_i|
        list_of_runs2[run_i][0].num = i
        list_of_runs2[run_i][0].save
        Basic.save_run list_of_runs2[run_i][0]
        i+=1
      end
      
      ### write files corresponding to sha2                                                                                                                                                                                           
      list_of_runs2.each_index do |run_i|
        run = list_of_runs2[run_i][0]
        output_dir = (step.multiple_runs == true) ? (step_dir + run.id.to_s) : step_dir
        Dir.mkdir output_dir if !File.exists? output_dir
        if h_sha2[run_i]
          h_sha2[run_i].each_key do |k|
            sha2 = h_sha2[run_i][k]
            filename = h_attrs[k]['write_in_file']
            filepath = output_dir + filename
            File.open(filepath, 'w') do |f|
              f.write(h_sha2_values[sha2])
            end
          end
        end
      end
      
      ### need to have the run_id to determine the output_dir and build the command                                                                                                                                                   
      list_of_runs2.each_index do |run_i|
        run = list_of_runs2[run_i][0]
        h_p = {
          :project => project,
          :h_cmd_params => h_cmd_params.dup,
          :run => run,
          :p => list_of_runs2[run_i][1],
          :h_attrs => h_attrs,
          :step => step,
          :h_data_classes => h_data_classes,
          :std_method => std_method,
          :h_env => h_env
        }
        logger.debug("BLOUUUUU:" + h_p.to_json)
        h_res = Basic.set_run(logger, h_p)
        
        if !h_res[:error]
          #  ### init active_run -- OBSOLETE as active_run is created at the same time as run    
          #   h_res = Basic.init_active_run(run)                                                                                                                                                                                                
          if !h_res[:error] and run.async == false
            logger.debug("START RUN #{run.id} SYNCHRONEOUSLY")
            ## execute run                                                             
            Basic.exec_run(run)
          end
        end
        
        ### update run status                                                                                                                                                                                                         
        if h_res[:error]
          h_to_upd = {:status_id => 4}
          Basic.upd_run(project, run, h_to_upd, true)
        end
        
      end
      
    end
    
  end

end
