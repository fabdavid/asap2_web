class VersionsController < ApplicationController
  before_action :set_version, only: [:run_stats, :show, :edit, :update, :destroy]
  
  layout "welcome"

  def run_stats

    list = Basic.get_run_stats(@version)
    # list = Basic.safe_parse_json(File.read("/data/asap2/run_stats/#{@version.id}.json"), [])
    respond_to do |format|
      format.json { render json: list }
    end

  end

  def get_base_data    
    @h_all_tools = {}
    Tool.all.map{|t| @h_all_tools[t.name]= t}
#     tools = Basic.sql_query2(:asap_data, @h_env['asap_data_db_version'], 'tools', '', '*', "") #"identifier IN (" + @h_gene_types[params[:highlight_gene_type].to_sym].map{|e| ("'#{e}'")}.join(", ") + ") and gene_sets.organism_id = #{@project.organism_id}")
#    tools.map{|t| @h_all_tools[t.name] = t} 

    @h_tool_types = {}
    ToolType.all.map{|tt| @h_tool_types[tt.id]= tt}    
  end

  # GET /versions
  # GET /versions.json
  def index
    get_base_data()
    @versions = Version.all
    @h_env = {}
    @versions.each do |v|
      @h_env[v.id] = Basic.safe_parse_json(v.env_json, {})
    end
    if params[:nolayout]
      render :layout => false
    else
      render
    end
  end

  def last_version
    @version = Version.last
    render :layout => false if params[:nolayout]
  end

  # GET /versions/1
  # GET /versions/1.json
  def show    
    get_base_data()
     if params[:nolayout]
       render :partial => 'show', :locals => {:version => @version}
     else
       render
     end
  end

  # GET /versions/new
  def new
    @version = Version.new
  end

  # GET /versions/1/edit
  def edit
  end

  # POST /versions
  # POST /versions.json
  def create
      @version = Version.new(version_params)
      
      respond_to do |format|
        if admin? and @version.save!
          format.html { redirect_to @version, notice: 'Version was successfully created.' }
          format.json { render :show, status: :created, location: @version }
        else
          format.html { render :new }
          format.json { render json: @version.errors, status: :unprocessable_entity }
        end
      end

  end

  # PATCH/PUT /versions/1
  # PATCH/PUT /versions/1.json
  def update

      respond_to do |format|
        if admin? and @version.update(version_params)
          format.html { redirect_to @version, notice: 'Version was successfully updated.' }
          format.json { render :show, status: :ok, location: @version }
        else
          format.html { render :edit }
          format.json { render json: @version.errors, status: :unprocessable_entity }
        end
      end

  end

  # DELETE /versions/1
  # DELETE /versions/1.json
  def destroy
    if admin?
      @version.destroy
      respond_to do |format|
        format.html { redirect_to versions_url, notice: 'Version was successfully destroyed.' }
        format.json { head :no_content }
      end
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_version
      @version = Version.find(params[:id])      
      @h_env = {@version.id => Basic.safe_parse_json(@version.env_json, {})}
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def version_params
#      params.fetch(:version, {})
      params.fetch(:version).permit(:release_date, :description, :env_json, :activated)
    end
end
