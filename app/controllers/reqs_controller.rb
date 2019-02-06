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

  def add_runs list_of_runs, h_attr_values, attr_name

    new_list_of_runs = []
    list_of_runs.each do |tmp_run|
  #    logger.debug("bla: " +  tmp_run.to_json)
      new_run = tmp_run[0].dup
      new_h_attr_values = h_attr_values.dup
      ### each value
      h_attr_values[attr_name].each do |attr|
  #      logger.debug("bli: " + attr.to_json)
        new_h_attr_values[attr_name] = attr
        new_run.attrs_json = new_h_attr_values.to_json
        new_list_of_runs.push([new_run, new_h_attr_values])
      end
    end

    return new_list_of_runs
  end

  def create_runs

#    project_dir = Pathname.new(APP_CONFIG[:user_data_dir]) + @project.user.id.to_s + @project.key
    
    ## create runs
    # {"input_matrix":{"run_id":"13","output_attr_name":"output_matrix"},"fit_model":"log"}
    h_attr_values = JSON.parse(@req.attrs_json)
    @std_method = @req.std_method
    @step = @req.step
    h_version = @project
    @h_attrs = {}
    
    if @std_method and @step
      
      @h_cmd_params = JSON.parse(@step.command_json)
      #     logger.debug("blou:" + @h_cmd_params.to_json)
      
      tmp_h = JSON.parse(@std_method.command_json)
      tmp_h.each_key do |k|
        @h_cmd_params[k] = tmp_h[k]
      end
      @h_global_params = JSON.parse(@step.method_attrs_json)
      
      @h_attrs = JSON.parse(@std_method.attrs_json)
      ## complement attributes with global parameters - defined at the level of the step                                                                                                                           
      @h_global_params.each_key do |k|
        @h_attrs[k]={}
        @h_global_params[k].each_key do |k2|
          @h_attrs[k][k2] = @h_global_params[k][k2]
        end
      end
      
      combinatorial_run_attrs = @h_attrs.keys.select{|k|  @h_attrs[k]['combinatorial_runs'] == true and (h_attr_values[k] and h_attr_values[k].size > 0)}
      
      ### call the function for each combinatorial_runs
      h_run = {
        :req_id => @req.id,
        :step_id => @step.id,
        :std_method_id => @std_method.id,
        :project_id => @project.id,
        :command_json => nil,
        :attrs_json => nil,
        :user_id => (current_user) ? current_user.id : 1,
        :num => nil,
        :pid => nil,
        :error => nil,
        :status_id => 1,
        :async => @h_cmd_params['async']
      }

      list_of_runs = [[Run.new(h_run), {}]]
      combinatorial_run_attrs.each do |attr_name|
        #   logger.debug("ble: " + list_of_runs.to_json)
        list_of_runs = add_runs(list_of_runs, h_attr_values, attr_name)
      end
      
      ### define num for each run after creation
      last_run = Run.where(:project_id => @project.id).order(:id).last
      i = (last_run) ? last_run.num : 1
      list_of_runs.each_index do |run_i|
        i+=1
        list_of_runs[run_i][0].num = i
        #   logger.debug("blo: " + list_of_runs[run_i].to_json)
        list_of_runs[run_i][0].save
      end
      
      ### need to have the run_id to determine the output_dir and build the command
      list_of_runs.each_index do |run_i|
        run = list_of_runs[run_i][0]
        h_p = {
          :project => @project,
          :h_cmd_params => @h_cmd_params,
          :run => run,
          :p => list_of_runs[run_i][1],
          :h_attrs => @h_attrs,
          :step => @step,
          :std_method => @std_method,
          :h_env => @h_env
        }
        
        h_res = Basic.set_run(h_p)
        
        if !h_res[:error]
          ### init active_run
          h_res = Basic.init_active_run(run)
          
          if !h_res[:error] and run.async == false
            ## execute run
            Basic.exec_run(run)
          end
        end
        
        ### update run status
        if h_res[:error]
          h_to_upd = {:status_id => 4}
          Basic.upd_run(run, h_to_upd)
        end
        
      end

    end
  end

  # POST /reqs
  # POST /reqs.json
  def create
    @req = Req.new(req_params)
    @req.project_id = @project.id
    
    @h_env = JSON.parse(@project.version.env_json)
    @std_method = @req.std_method
    @step = @req.step
    
    @h_attrs = {}
    if @std_method and @step
      h_global_params = JSON.parse(@step.method_attrs_json)
      
      @h_attrs = JSON.parse(@std_method.attrs_json)
      ## complement attributes with global parameters - defined at the level of the step                              
      
      h_global_params.each_key do |k|
        @h_attrs[k]={}
        h_global_params[k].each_key do |k2|
          @h_attrs[k][k2] = h_global_params[k][k2]
        end
      end
    end
    
    tmp_attrs = params[:attrs]

    tmp_attrs.each_pair do |k, v|
      if ["array", "hash"].include? @h_attrs[k]['req_data_structure']
        tmp_attrs[k] = JSON.parse(v)
      end
    end
    @req.attrs_json = tmp_attrs.to_json
    @req.user_id = (current_user) ? current_user.id : 1

    respond_to do |format|
      if @req.save

        create_runs()
        format.json { render :json => {:status => 'success'}}
 #       format.html { redirect_to @req, notice: 'Req was successfully created.' }
 #       format.json { render :show, status: :created, location: @req }
      else
        format.json { render :json => {:status => 'failed'}}
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
    @req.destroy
    respond_to do |format|
      format.html { redirect_to reqs_url, notice: 'Req was successfully destroyed.' }
      format.json { head :no_content }
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
