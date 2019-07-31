class RunsController < ApplicationController
  before_action :set_run, only: [:show, :edit, :update, :destroy]

  # GET /runs
  # GET /runs.json
  def index
    @runs = Run.all
  end

  # GET /runs/1
  # GET /runs/1.json
  def show
  end

  # GET /runs/new
  def new
    @run = Run.new
  end

  # GET /runs/1/edit
  def edit
  end

  # POST /runs
  # POST /runs.json
  def create
    @run = Run.new(run_params)

    respond_to do |format|
      if admin? and @run.save
        format.html { redirect_to @run, notice: 'Run was successfully created.' }
        format.json { render :show, status: :created, location: @run }
      else
        format.html { render :new }
        format.json { render json: @run.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /runs/1
  # PATCH/PUT /runs/1.json
  def update
    respond_to do |format|
      if admin? and  @run.update(run_params)
        format.html { redirect_to @run, notice: 'Run was successfully updated.' }
        format.json { render :show, status: :ok, location: @run }
      else
        format.html { render :edit }
        format.json { render json: @run.errors, status: :unprocessable_entity }
      end
    end
  end

  def self.destroy_run project, step, run

    project_dir = Pathname.new(APP_CONFIG[:user_data_dir]) + project.user_id.to_s + project.key
    step_dir = project_dir + step.name
    output_dir = (step.multiple_runs == true) ? (step_dir + run.id.to_s) : step_dir
    
    tmp_dir = project_dir + 'tmp'
    ## kill run if necessary
    Basic.kill_run run
    
    ## remove potential annotations
    ### from the loom
    #run.annots.each do |annot|
    h_outputs = JSON.parse(run.output_json)
    logger.debug(h_outputs.to_json)
    h_outputs.each_key do |k|
      h_outputs[k].each_key do |output_key|
        t = output_key.split(":")
        if t.size == 2 
          if File.exist? (project_dir + t[0])
            cmd = "java -jar ../asap_run/srv/ASAP.jar -T RemoveMetaData -o #{tmp_dir} -loom #{project_dir + t[0]} -meta #{t[1]}"
            logger.debug("CMD: " + cmd)
            `#{cmd}`
          end
#        elsif t.size == 1
#          if File.exist? (project_dir + t[0])
#            logger.debug("DEL_FILE: " + t.to_json + '---' + (project_dir + t[0]).to_s)
#            File.delete (project_dir + t[0]) 
          #          end
        end
      end
    end

    #    logger.debug()
    FileUtils.rm_r output_dir if File.exist? output_dir
    
    ### from the database
    run.annots.destroy_all
    run.fos.destroy_all
    
    ## remove the run
    active_run = run.active_run
    active_run.destroy if active_run
   
    ## move run in the deleted_runs if it finished or failed                                                                                                                    
    if [3, 4].include? run.status_id
      h_run = run.as_json
      if ! DelRun.where(h_run).first
        del_run = DelRun.new(h_run)
        del_run.save!
      end
    end

    run.destroy  
  end

  def self.destroy_children project, step, run #, h_step_ids
    run_children = run.children_run_ids.split(",")
    if run_children.size > 0
      @log += "children: " + run_children.to_json + ". "
      runs = Run.where(:project_id => project.id, :id => run_children).all
      runs.each do |run|
        @h_step_ids[run.step_id] = 1
        @log += "call destroy_children on #{run.id}. "
        h_step_ids = destroy_children project, step, run
      end
    end
    # else
    @h_step_ids[run.step_id] = 1
    @log += "destroy #{run.id}. "
    destroy_run project, step, run

    #return h_step_ids
    #  end
  end
  
  def self.destroy_run_call project, run
 
    step = run.step

    ## edit parent's children_run_ids                                                                                                                                                                                 
    parents = (run.run_parents_json) ? JSON.parse(run.run_parents_json) : []
    parent_runs = Run.where(:project_id => project.id, :id => parents.map{|p| p['run_id']}).all
    parent_runs.each do |parent_run|
      children_run_ids = parent_run.children_run_ids.split(",").reject{|e| e == run.id}
      parent_run.update_attribute(:children_run_ids, children_run_ids.join(","))
    end

    ## destroy run and descendants                                                                                                                                                                                    
    @log = "call destroy_children on #{run.id}. "
    @h_step_ids = {}
    destroy_children project, step, run

    ### update project_step for each step affected                                                                                                                                                                    
    @h_step_ids.each_key do |step_id|
      Basic.upd_project_step project, step_id
    end
    Basic.upd_project_size project

  end


  # DELETE /runs/1
  # DELETE /runs/1.json
  def destroy
    if editable?(@project)
      RunsController.destroy_run_call(@project, @run)
      
      respond_to do |format|
        format.json { #redirect_to runs_url, notice: 'Run was successfully destroyed.' }
          render :json => {:status => 'success', :log => @log}
          #redirect_to {:controller => :projects, :action => :get_step, :key => @project.key, :step_id => @step.id, "_method" => :get}, {:turbolinks => false}
        }
        #      format.json { head :no_content }
      end
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_run
      @run = Run.find(params[:id])
      @project = @run.project
      @step = @run.step
      @std_method = @run.std_method
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def run_params
      params.fetch(:run, {})
    end
end
