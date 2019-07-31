class AnnotsController < ApplicationController
  before_action :set_annot, only: [:get_cats, :show, :edit, :update, :destroy]

  def get_cats
    @project = @annot.project
    if readable?(@project) and @annot.data_type_id == 3
      @project_dir =  Pathname.new(APP_CONFIG[:user_data_dir]) + @project.user_id.to_s + @project.key
      @cmd = "java -jar #{APP_CONFIG[:local_asap_run_dir]}/ASAP.jar -T ExtractMetadata -f #{@project_dir + @annot.filepath} -meta #{@annot.name}"
      @h_results = JSON.parse(`#{@cmd}`)
      @cats = @h_results['values'].uniq
      
      @h_list_indexes_by_cat={}
      ## init
      @cats.each do |c|
         @h_list_indexes_by_cat[c]=[]
      end
      @h_results['values'].each_index do |i|
        @h_list_indexes_by_cat[@h_results['values'][i]].push i
      end
      render :partial => 'get_cats'
    end
  end

  # GET /annots
  # GET /annots.json
  def index
    @annots = Annot.all
  end

  # GET /annots/1
  # GET /annots/1.json
  def show
    @h_steps = {}
    @h_statuses = {}
    Step.all.map{|s| @h_steps[s.id]=s}
    Status.all.map{|s| @h_statuses[s.id]=s}

    @project = @annot.project
    @step = Step.find_by_name('metadata')
    @ps = ProjectStep.where(:project_id => @project.id, :step_id => @step.id).first
    @h_attrs = JSON.parse(@step.attrs_json)
 
    @project_dir =  Pathname.new(APP_CONFIG[:user_data_dir]) + @project.user_id.to_s + @project.key
    @run = @annot.run
    @h_dashboard_card = {}
    @h_dashboard_card[@run.step_id] = JSON.parse(@h_steps[@run.step_id].dashboard_card_json)
    
    ## get annot
    @cmd = "java -jar #{APP_CONFIG[:local_asap_run_dir]}/ASAP.jar -T ExtractMetadata -prec 2 -f #{@project_dir + @annot.filepath} -meta #{@annot.name}"
    
    @h_results = JSON.parse(`#{@cmd}`)
    
    if @h_results['values']
      ### get the list of genes or cells
      name = (@annot.dim == 2) ? '/row_attrs/Gene' : 'col_attrs/CellID'
      cmd = "java -jar #{APP_CONFIG[:local_asap_run_dir]}/ASAP.jar -T ExtractMetadata -prec 2 -f #{@project_dir + @annot.filepath} -meta #{name}"
      key = (@annot.dim == 2) ? 'genes' : 'cells'
      @h_results[key] = JSON.parse(`#{cmd}`)['values']
    end 


    if !readable? @project
      render :text => 'Not authorized'
    end
    render :layout => false
  end

  # GET /annots/new
  def new
    @annot = Annot.new
  end

  # GET /annots/1/edit
  def edit
  end

  # POST /annots
  # POST /annots.json
  def create
    @annot = Annot.new(annot_params)

    respond_to do |format|
      if editable?(@project) and @annot.save
        format.html { redirect_to @annot, notice: 'Annot was successfully created.' }
        format.json { render :show, status: :created, location: @annot }
      else
        format.html { render :new }
        format.json { render json: @annot.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /annots/1
  # PATCH/PUT /annots/1.json
  def update
    respond_to do |format|
      if editable?(@project) and @annot.update(annot_params)
        format.html { redirect_to @annot, notice: 'Annot was successfully updated.' }
        format.json { render :show, status: :ok, location: @annot }
      else
        format.html { render :edit }
        format.json { render json: @annot.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /annots/1
  # DELETE /annots/1.json
  def destroy
    if editable?(@project)        
      @annot.destroy
      respond_to do |format|
        format.html { redirect_to annots_url, notice: 'Annot was successfully destroyed.' }
        format.json { head :no_content }
      end
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_annot
      @annot = Annot.find(params[:id])
      @project = @annot.project
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def annot_params
      params.fetch(:annot, {})
    end
end
