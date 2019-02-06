class GeneFilteringsController < ApplicationController
  before_action :set_gene_filtering, only: [:show, :edit, :update, :destroy]
  
  # GET /gene_filterings
  # GET /gene_filterings.json
  def index
    @gene_filterings = []
    @project = Project.where(:key => params[:project_key]).first
    @gene_filterings = GeneFiltering.where(:project_id => @project.id).all
    #    get_cluster_data()
    render :partial => 'index'
  end
  
  # GET /gene_filterings/1
  # GET /gene_filterings/1.json
  def show
  end
  
  # GET /gene_filterings/new
  def new
    @gene_filtering = GeneFiltering.new
  end
  
  # GET /gene_filterings/1/edit
  def edit
  end
  
  # POST /gene_filterings
  # POST /gene_filterings.json
  def create
    #    @gene_filtering = GeneFiltering.new(gene_filtering_params)
    
    StdStep.create_instance('gene_filtering', gene_filtering_params)
    
    render :nothing => true
    
    #    respond_to do |format|
    #      if @gf.save
    #        format.html { redirect_to @gf, notice: 'Gene filtering was successfully created.' }
    #        format.json { render :show, status: :created, location: @gene_filtering }
    #      else
    #        format.html { render :new }
    #        format.json { render json: @gene_filtering.errors, status: :unprocessable_entity }
    #      end
    #    end
  end
  
  # PATCH/PUT /gene_filterings/1
  # PATCH/PUT /gene_filterings/1.json
  def update
    respond_to do |format|
      if @gene_filtering.update(gene_filtering_params)
        format.html { redirect_to @gene_filtering, notice: 'Gene filtering was successfully updated.' }
        format.json { render :show, status: :ok, location: @gene_filtering }
      else
        format.html { render :edit }
        format.json { render json: @gene_filtering.errors, status: :unprocessable_entity }
      end
    end
  end
  
  # DELETE /gene_filterings/1
  # DELETE /gene_filterings/1.json
  def destroy
    @gene_filtering.destroy
    respond_to do |format|
      format.html { redirect_to gene_filterings_url, notice: 'Gene filtering was successfully destroyed.' }
      format.json { head :no_content }
    end
  end
  
  private
  # Use callbacks to share common setup or constraints between actions.
  def set_gene_filtering
    @gene_filtering = GeneFiltering.find(params[:id])
  end
  
  # Never trust parameters from the scary internet, only allow the white list through.
  def gene_filtering_params
    params.fetch(:gene_filtering, {})
  end
end
