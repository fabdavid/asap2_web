class ReqsController < ApplicationController

  before_action :set_project, only: [:create]
  before_action :set_req, only: [:show, :edit, :update, :destroy]

  # GET /reqs
  # GET /reqs.json
  def index
    @reqs = Req.all
  end

  # GET /reqs/1
  # GET /reqs/1.json
  def show
  end

  # GET /reqs/new
  def new
    @req = Req.new
  end

  # GET /reqs/1/edit
  def edit
  end

  def add_runs list_of_runs, h_attr_values, attr_name #, applied_combinatorial_run_attrs
    logger.debug("======== #{attr_name} ========")
    logger.debug("LIST_OF_RUNS_attrs: " + list_of_runs.map{|e| e[1]}.to_json)
    #    logger.debug("h_attr_values: " + h_attr_values.to_json)
    new_list_of_runs = []
    list_of_runs.each do |tmp_run|
      #    logger.debug("bla: " +  tmp_run.to_json)
      #    new_run = tmp_run[0].dup
      ### each value
      h_attr_values[attr_name].each do |attr|
        #        logger.debug("bli: " + attr.to_json)
        new_run = tmp_run[0].dup

        ### light version works otherwise uncomment the heavy version (using applied_combinatorial_run_attrs)
        new_h_attr_values = JSON.parse(new_run.attrs_json)
        #  new_h_attr_values = h_attr_values.dup
        #  h_tmp_attr = JSON.parse(new_run.attrs_json)
        #  applied_combinatorial_run_attrs.each do |applied_attr_name|
        #    new_h_attr_values[applied_attr_name]= h_tmp_attr[applied_attr_name]
        #  end
        new_h_attr_values[attr_name] = attr
        new_run.attrs_json = new_h_attr_values.to_json
        logger.debug("NEW_H_ATTR_VALUES: " + new_h_attr_values.to_json)
        new_list_of_runs.push([new_run, new_h_attr_values])
      end
    end
    logger.debug("new_LIST_OF_RUNS_attrs: " + new_list_of_runs.map{|e| e[1]}.to_json)
    #   logger.debug("NEW_LIST: #{attr_name} => #{new_list_of_runs.to_json}")
    return new_list_of_runs
  end

  def create_runs

    t = Time.now
    
    project_dir = Pathname.new(APP_CONFIG[:user_data_dir]) + @project.user.id.to_s + @project.key
    
    ## create runs
    # {"input_matrix":{"run_id":"13","output_attr_name":"output_matrix"},"fit_model":"log"}
    h_attr_values = JSON.parse(@req.attrs_json)
    @std_method = @req.std_method
    @step = @req.step
    h_version = @project
    @h_attrs = {}

    @h_data_classes = {}
    DataClass.all.map{|dc| @h_data_classes[dc.id] = dc}
    
    puts "Elapsed time 1:" + (Time.now-t).to_s

    if @std_method and @step
      
      @h_cmd_params = JSON.parse(@step.command_json)
      #     logger.debug("blou:" + @h_cmd_params.to_json)
      
      tmp_h = JSON.parse(@std_method.command_json)
      tmp_h.each_key do |k|
        @h_cmd_params[k] = tmp_h[k]
      end

      h_res = Basic.get_std_method_attrs(@std_method, @step)
      @h_attrs = h_res[:h_attrs]
      @h_global_params = h_res[:h_global_params]
      
#      @h_global_params = JSON.parse(@step.method_attrs_json)
#      
#      @h_attrs = JSON.parse(@std_method.attrs_json)
#      ## complement attributes with global parameters - defined at the level of the step                                                                                                    #                       
#      @h_global_params.each_key do |k|
#        @h_attrs[k]={}
#        @h_global_params[k].each_key do |k2|
#          @h_attrs[k][k2] = @h_global_params[k][k2]
#        end
#      end
      puts "Elapsed time 2:" + (Time.now-t).to_s
      
      combinatorial_run_attrs = @h_attrs.keys.select{|k|  @h_attrs[k]['combinatorial_runs'] == true and (h_attr_values[k] and h_attr_values[k].size > 0)}
      
      now = Time.now
      ### call the function for each combinatorial_runs
      h_run = {
        :req_id => @req.id,
        :step_id => @step.id,
        :std_method_id => @std_method.id,
        :project_id => @project.id,
        :command_json => nil,
        :attrs_json => h_attr_values.to_json,
        :user_id => (current_user) ? current_user.id : 1,
        :num => nil,
        :pid => nil,
        :error => nil,
        :status_id => 6,
        :submitted_at => now,
        :created_at => now,
        :async => @h_cmd_params['async']#,
     #   :pred_max_ram => params[:predicted_ram],
     #   :pred_process_duration => params[:predicted_time]
      }
      
      puts "Elapsed time 3:" + (Time.now-t).to_s

      list_of_runs = [[Run.new(h_run), {}]]
      #      applied_combinatorial_run_attrs = []
      combinatorial_run_attrs.each do |attr_name|
        #   logger.debug("ble: " + list_of_runs.to_json)
        list_of_runs = add_runs(list_of_runs, h_attr_values, attr_name) #, applied_combinatorial_run_attrs)
        #        applied_combinatorial_run_attrs.push(attr_name)
      end
      
      puts "Elapsed time 4:" + (Time.now-t).to_s


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
      puts "Elapsed time 5:" + (Time.now-t).to_s

      ### add errors if runs already exists
      existing_runs =  Run.where(:project_id => @project.id, :step_id => @step.id, :std_method_id =>  @std_method.id).all
      h_existing_runs_by_attrs_json = {}
      existing_runs.each do |r|
        h_existing_runs_by_attrs_json[r.attrs_json] = 1
      end
      list_already_existing_run_i = [] 
      list_of_runs.each_index do |run_i|
        run = list_of_runs[run_i]
#        nber_existing_runs = Run.where(:project_id => @project.id, :step_id => @step.id, :std_method_id =>  @std_method.id, :attrs_json => run[0].attrs_json).count
#        if nber_existing_runs > 0
        if h_existing_runs_by_attrs_json[run[0].attrs_json]
          @h_errors[:already_existing]||=0
          @h_errors[:already_existing]+=1
          list_already_existing_run_i.push run_i
        end
      end
      
      puts "Elapsed time 6:" + (Time.now-t).to_s

      ### delete already existing runs
      list_of_runs2 = list_of_runs.reject.with_index { |e, run_i| list_already_existing_run_i.include? run_i } 

      ### define num for each run after creation                                                                                                                               
      last_run = Run.where(:project_id => @project.id, :step_id => @step.id).order(:id).last
      i = (last_run) ? (last_run.num+1) : 1

       puts "Elapsed time 7:" + (Time.now-t).to_s
      ### write in files some parameters that take too much space and replace in db by a SHA2
      step_dir = project_dir + @step.name
      Dir.mkdir step_dir if !File.exist? step_dir
      h_sha2= {}
      h_sha2_values={}
      list_of_runs2.each_index do |run_i|
        run = list_of_runs2[run_i][0]
        # output_dir = (@step.multiple_runs == true) ? (step_dir + run.id.to_s) : step_dir
        #        Dir.mkdir output_dir if !File.exist? output_dir
        @h_attrs.each_key do |k|
          if filename = @h_attrs[k]['write_in_file']                                                                                                                                                                                     
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
       puts "Elapsed time 7:" + (Time.now-t).to_s
      ### save runs
      list_of_runs2.each_index do |run_i|
        list_of_runs2[run_i][0].num = i
        list_of_runs2[run_i][0].save
        Basic.save_run list_of_runs2[run_i][0]
        i+=1
      end
       puts "Elapsed time 8:" + (Time.now-t).to_s
      ### write files corresponding to sha2
      list_of_runs2.each_index do |run_i|
        run = list_of_runs2[run_i][0]
        output_dir = (@step.multiple_runs == true) ? (step_dir + run.id.to_s) : step_dir
        Dir.mkdir output_dir if !File.exists? output_dir
        if h_sha2[run_i]
          h_sha2[run_i].each_key do |k|
            sha2 = h_sha2[run_i][k]
            filename = @h_attrs[k]['write_in_file']
            filepath = output_dir + filename                                                             
            File.open(filepath, 'w') do |f|                                                                                                                                  
              f.write(h_sha2_values[sha2])                                                                        
            end           
          end
        end
      end

      list_of_h_p = []

      puts "Elapsed time 9:" + (Time.now-t).to_s
      h_annots ={}
      Annot.where(:project_id => @project.id).all.map{|a| h_annots[a.id] = a}
      ### need to have the run_id to determine the output_dir and build the command
      list_of_runs2.each_index do |run_i|
        run = list_of_runs2[run_i][0]
        h_p = {
          :project => @project,
          :h_cmd_params => @h_cmd_params.dup,
          :run => run,
          :p => list_of_runs2[run_i][1],
          :h_attrs => @h_attrs,
          :step => @step,
          :h_data_classes => @h_data_classes,
          :std_method => @std_method,
          :h_env => @h_env,
          :h_annots => h_annots,
          :el_time => t,
          :user_id => (current_user) ? current_user.id : 1
        }
        list_of_h_p.push h_p
        logger.debug("BLOUUUUU:" + h_p.to_json)
        #h_res = Basic.set_run(logger, h_p)
      end
      Basic.upd_project_step @project, @step.id
      @project.broadcast @step.id
      @req.delay.set_runs(list_of_runs2, list_of_h_p)
#      @req.set_runs(list_of_runs2, list_of_h_p)

#      Basic.upd_project_step @project, @step.id


#      puts "Elapsed time 10:" + (Time.now-t).to_s
#      list_of_runs2.each_index do |run_i|
#        run = list_of_runs2[run_i][0]
#        if !h_res[:error]
#          #  ### init active_run -- OBSOLETE as active_run is created at the same time as run
#          #   h_res = Basic.init_active_run(run)
#          
#          if !h_res[:error] and run.async == false
#            logger.debug("START RUN #{run.id} SYNCHRONEOUSLY")
#            ## execute run
#            Basic.exec_run(run)
#          end
#        end
#      end
##      
 #     puts "Elapsed time 11:" + (Time.now-t).to_s
 #     ActiveRecord::Base.transaction do
 #       list_of_runs2.each_index do |run_i|
 #         run = list_of_runs2[run_i][0]
 #         
 #         ### update run status
 #         if h_res[:error]
 #           h_to_upd = {:status_id => 4}
 #           Basic.upd_run(@project, run, h_to_upd, true)
 #         end
 #       end
 #       
 #     end

    end
  end

  # POST /reqs
  # POST /reqs.json
  def create

    project_dir = Pathname.new(APP_CONFIG[:user_data_dir]) + @project.user.id.to_s + @project.key  
    
    @req = Req.new(req_params)
    @req.project_id = @project.id
    
    @h_env = JSON.parse(@project.version.env_json)
    @std_method = @req.std_method
    @step = @req.step
 
    @h_attrs = {}
    @h_errors = {}
    
    if @std_method and @step

     # ## cell_filtering
     # 
     # if @step.id == 9
     #   ## write list of filtered cells
     #   filepath = project_dir + 'filtered_out_cells.txt'
     #   File.open(filepath, 'w') do |f|
     #     f.write(params[:req][:all_filtered])
     #   end
     # end

      h_global_params = JSON.parse(@step.method_attrs_json)
      
      @h_attrs = JSON.parse(@std_method.attrs_json)
      ## complement attributes with global parameters - defined at the level of the step                              
      
      h_global_params.each_key do |k|
        @h_attrs[k]={}
        h_global_params[k].each_key do |k2|
          @h_attrs[k][k2] = h_global_params[k][k2]
        end
      end

      #      ### apply write_in_file
      #      @h_attrs.each_key do |k|
      #        if filename = @h_attrs[k]['write_in_file']
      #          filepath = project_dir + filename
      #          File.open(filepath, 'w') do |f|
      #             f.write(params[:attrs][k])
      #          end
      #        end
      #      end
    end
    
    tmp_attrs = params[:attrs]

    if tmp_attrs
      tmp_attrs.each_pair do |k, v|
        if @h_attrs[k] and @h_attrs[k]['req_data_structure'] and ["array", "hash"].include? @h_attrs[k]['req_data_structure']
          tmp_attrs[k] = JSON.parse(v) #Basic.safe_parse_json(v, nil)
        end
      end
    end
    @req.attrs_json = (tmp_attrs) ? tmp_attrs.to_json : "{}"
    @req.user_id = (current_user) ? current_user.id : 1

    

    respond_to do |format|
      if @req.save

        create_runs()
        errors_txt = nil
        list_errors = []
        if @h_errors[:already_existing]
          list_errors.push("#{@h_errors[:already_existing]} configuration#{(@h_errors[:already_existing] > 1) ? 's' : ''} #{(@h_errors[:already_existing] > 1) ? 'were' : 'was'} already launched, #{(@h_errors[:already_existing] > 1) ? 'they were' : 'it was'} not added.")
        end
        if list_errors.size > 0
          errors_txt = list_errors.join(" ")
        end
        
        format.json { render :json => {:status => 'success', :errors => errors_txt}}
 #       format.html { redirect_to @req, notice: 'Req was successfully created.' }
 #       format.json { render :show, status: :created, location: @req }
      else
        format.json { render :json => {:status => 'failed', :log =>  tmp_attrs.to_json}}
 #       format.html { render :new }
 #       format.json { render json: @req.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /reqs/1
  # PATCH/PUT /reqs/1.json
  def update
#    respond_to do |format|
#      if @req.update(req_params)
        format.json { render :json => {:status => 'success'}}
#        format.html { redirect_to @req, notice: 'Req was successfully updated.' }
#        format.json { render :show, status: :ok, location: @req }
#      else
       format.json { render :json => {:status => 'failed'}}
#        format.html { render :edit }
#        format.json { render json: @req.errors, status: :unprocessable_entity }
#      end
#    end
  end

  # DELETE /reqs/1
  # DELETE /reqs/1.json
  def destroy
    @project = @req.project
    if owner_or_admin_obj? @req, @project #or (current_user.id and @req.user_id == current_user.id) or (@project.sandbox == true and @project.key == session[:project_key])
      @req.runs.map{|r| RunsController.destroy_run_call @req.project, r}
      @req.destroy
      respond_to do |format|
        format.html { redirect_to reqs_url, notice: 'Req was successfully destroyed.' }
        format.json { head :no_content }
      end
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_project
      @project = Project.find_by_key(params[:project_key])
    end
  
    def set_req
      @req = Req.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def req_params
      params.fetch(:req).permit(:step_id, :std_method_id) 
    end
end
