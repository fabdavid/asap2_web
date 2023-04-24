class CellOntologyTermsController < ApplicationController
  before_action :set_cell_ontology_term, only: [:show, :edit, :update, :destroy]

  def autocomplete

    organism = Organism.where(:id => params[:organism_id]).first
    co_ids = CellOntology.all.select{|co| tax_ids = (co.tax_ids) ? co.tax_ids.split(",") : nil; flag = (tax_ids) ? tax_ids.include?(organism.tax_id.to_s) : false; default_tax_id = organism.tax_id if flag; (flag or co.tax_ids.to_i == 0)}.map{|co| co.id} 
    
    tax_id = params[:tax_id]
    to_render = []
    final_list=[]
    query = CellOntologyTerm.search do
      fulltext (params[:term].gsub(/\$\{jndi\:/, '') + " or " + params[:term].gsub(/\$\{jndi\:/, '') + "*") do
        fields(:identifier => 3.0, :name => 2.0)
      end
      with :tax_id, tax_id if tax_id 
      with :cell_ontology_id, (params[:cell_ontology_id] != '0') ? params[:cell_ontology_id].to_i : co_ids
      with :original, true
      paginate :page => 1, :per_page => 20
    end
    final_list = query.results

    to_render = final_list.map{|e| {:id => e.id, :label => "#{e.identifier} #{e.name}"}}
    render :json => to_render.to_json
  end

  # GET /cell_ontology_terms
  # GET /cell_ontology_terms.json
  def index
    @cell_ontology_terms = CellOntologyTerm.all
  end

  # GET /cell_ontology_terms/1
  # GET /cell_ontology_terms/1.json
  def show

    render :layout => (params[:nolayout]) ? false : true 

  end

  # GET /cell_ontology_terms/new
  def new
    @cell_ontology_term = CellOntologyTerm.new
  end

  # GET /cell_ontology_terms/1/edit
  def edit
  end

  # POST /cell_ontology_terms
  # POST /cell_ontology_terms.json
  def create
    @cell_ontology_term = CellOntologyTerm.new(cell_ontology_term_params)

    respond_to do |format|
      if @cell_ontology_term.save
        format.html { redirect_to @cell_ontology_term, notice: 'Cell ontology term was successfully created.' }
        format.json { render :show, status: :created, location: @cell_ontology_term }
      else
        format.html { render :new }
        format.json { render json: @cell_ontology_term.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /cell_ontology_terms/1
  # PATCH/PUT /cell_ontology_terms/1.json
  def update
    respond_to do |format|
      if @cell_ontology_term.update(cell_ontology_term_params)
        format.html { redirect_to @cell_ontology_term, notice: 'Cell ontology term was successfully updated.' }
        format.json { render :show, status: :ok, location: @cell_ontology_term }
      else
        format.html { render :edit }
        format.json { render json: @cell_ontology_term.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /cell_ontology_terms/1
  # DELETE /cell_ontology_terms/1.json
  def destroy
    @cell_ontology_term.destroy
    respond_to do |format|
      format.html { redirect_to cell_ontology_terms_url, notice: 'Cell ontology term was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_cell_ontology_term
      @cell_ontology_term = CellOntologyTerm.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def cell_ontology_term_params
      params.fetch(:cell_ontology_term, {})
    end
end
