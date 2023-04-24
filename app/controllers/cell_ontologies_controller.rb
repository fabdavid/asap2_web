class CellOntologiesController < ApplicationController
  before_action :set_cell_ontology, only: [:show, :edit, :update, :destroy]

  layout "welcome"

  # GET /cell_ontologies
  # GET /cell_ontologies.json
  def index
    @cell_ontologies = CellOntology.all
    @h_organisms = {}
    Organism.all.map{|o| @h_organisms[o.tax_id] = o}
  end

  # GET /cell_ontologies/1
  # GET /cell_ontologies/1.json
  def show
  end

  # GET /cell_ontologies/new
  def new
    @cell_ontology = CellOntology.new
  end

  # GET /cell_ontologies/1/edit
  def edit
  end

  # POST /cell_ontologies
  # POST /cell_ontologies.json
  def create
    @cell_ontology = CellOntology.new(cell_ontology_params)

    respond_to do |format|
      if admin? and @cell_ontology.save
        format.html { redirect_to @cell_ontology, notice: 'Cell ontology was successfully created.' }
        format.json { render :show, status: :created, location: @cell_ontology }
      else
        format.html { render :new }
        format.json { render json: @cell_ontology.errors, status: :unprocessable_entity }
      end
    end
  end
  
  # PATCH/PUT /cell_ontologies/1
  # PATCH/PUT /cell_ontologies/1.json
  def update
    respond_to do |format|
      if admin? and @cell_ontology.update(cell_ontology_params)
        format.html { redirect_to @cell_ontology, notice: 'Cell ontology was successfully updated.' }
        format.json { render :show, status: :ok, location: @cell_ontology }
      else
        format.html { render :edit }
        format.json { render json: @cell_ontology.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /cell_ontologies/1
  # DELETE /cell_ontologies/1.json
  def destroy
    if admin?
      @cell_ontology.destroy
    end
    respond_to do |format|
      format.html { redirect_to cell_ontologies_url, notice: 'Cell ontology was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
  def set_cell_ontology
    @cell_ontology = CellOntology.find(params[:id])
  end
  
  # Never trust parameters from the scary internet, only allow the white list through.
  def cell_ontology_params
    #      name text, --HCAO or FlyBase Fly Anatomy                        
    #file_url text,
    #url text,
    #last_version text,
    #      params.fetch(:cell_ontology, {})
    params.fetch(:cell_ontology).permit(:name, :tag, :format, :file_url, :url, :last_version, :tax_ids)
  end
end
