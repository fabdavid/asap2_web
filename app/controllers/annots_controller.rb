class AnnotsController < ApplicationController
  before_action :set_annot, only: [:get_cats, :get_cat_details, :show, :edit, :update, :destroy]

  def get_cat_details
    @project = @annot.project
    if readable?(@project) and @annot.data_type_id == 3
      @project_dir =  Pathname.new(APP_CONFIG[:user_data_dir]) + @project.user_id.to_s + @project.key
      @cmd = "java -jar #{APP_CONFIG[:local_asap_run_dir]}/ASAP.jar -T MatchValues -loom #{@project_dir + @annot.filepath} -iAnnot #{@annot.name} -value #{params[:cat_value]}"
      @h_results = JSON.parse(`#{@cmd}`)

      @h_results['list_names'] = []
      @test = nil
      if @annot.dim == 1
        ## get cell names
        cmd = "java -jar #{APP_CONFIG[:local_asap_run_dir]}/ASAP.jar -T ExtractMetadata -loom #{@project_dir + @annot.filepath} -meta /col_attrs/CellID"
        h_res = JSON.parse(`#{cmd}`)
        @h_results["indexes_match"].each do |i|
          @h_results["list_names"].push h_res["values"][i]
        end
      end

    end

    render :partial => 'get_cat_details'
  end

  def get_cats
    @project = @annot.project
    if readable?(@project) and @annot.data_type_id == 3
      @project_dir =  Pathname.new(APP_CONFIG[:user_data_dir]) + @project.user_id.to_s + @project.key
      @cmd = "java -jar #{APP_CONFIG[:local_asap_run_dir]}/ASAP.jar -T ExtractMetadata -names -loom #{@project_dir + @annot.filepath} -meta #{@annot.name}"
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
#    @step = Step.find_by_name('cell_')
    @step = @run.step
    @ps = ProjectStep.where(:project_id => @project.id, :step_id => @step.id).first
    @h_attrs = Basic.safe_parse_json(@step.attrs_json, {})
 
    @project_dir =  Pathname.new(APP_CONFIG[:user_data_dir]) + @project.user_id.to_s + @project.key
#    @run = @annot.run
    @h_dashboard_card = {}
    @h_dashboard_card[@run.step_id] = JSON.parse(@h_steps[@run.step_id].dashboard_card_json)
    
    ## get annot
    @h_results = {}
    @cmd = ""

    if @annot.dim == 3
      @cmd = "docker run -it --network=asap2_asap_network -e HOST_USER_ID=$(id -u) -e HOST_USER_GID=$(id -g) --rm -v /data/asap2:/data/asap2  -v /srv/asap_run/srv:/srv fabdavid/asap_run:v2 h5dump -d #{@annot.name} #{@project_dir + @annot.filepath}"
      #      @cmd = "java -jar #{APP_CONFIG[:local_asap_run_dir]}/ASAP.jar -T ExtractRow -prec 2 -i #{s[:row_i]} -f #{loom_path} -iAnnot #{@dataset_annot.name}"
      row_txt = `#{@cmd}`
      row = (row_txt.match(/^\{/)) ? JSON.parse(row_txt)['row'] : nil
      
    else
      @cmd = "java -jar #{APP_CONFIG[:local_asap_run_dir]}/ASAP.jar -T ExtractMetadata -prec 2 -names -loom #{@project_dir + @annot.filepath} -meta #{@annot.name}"
      
      begin
      @h_results = JSON.parse(`#{@cmd}`)
      rescue
      end
      if @h_results['values']
        ### get the list of genes or cells
        name = (@annot.dim == 2) ? '/row_attrs/Gene' : 'col_attrs/CellID'
        cmd = "java -jar #{APP_CONFIG[:local_asap_run_dir]}/ASAP.jar -T ExtractMetadata -prec 2 -names -loom #{@project_dir + @annot.filepath} -meta #{name}"
        key = (@annot.dim == 2) ? 'genes' : 'cells'
        @h_results[key] = JSON.parse(`#{cmd}`)['values']
      end 
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
      @run = @annot.run
      @project = @annot.project
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def annot_params
      params.fetch(:annot, {})
    end
end
