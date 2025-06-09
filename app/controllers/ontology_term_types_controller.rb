class OntologyTermTypesController < ApplicationController
  before_action :set_ontology_term_type, only: %i[ show edit update destroy ]

  # GET /ontology_term_types or /ontology_term_types.json
  def index
    @ontology_term_types = OntologyTermType.all

    @h_cell_ontologies = {}
    CellOntology.all.map{|e| @h_cell_ontologies[e.id] = e}

    @h_terms = {}
    all_term_ids = @ontology_term_types.map{|e| e.in_lineage_term_ids&.split(",") | e.term_ids&.split(",")}.flatten.uniq.compact
    CellOntologyTerm.where(:id => all_term_ids).all.map{|e| @h_terms[e.id] = e}
    
  end

  # GET /ontology_term_types/1 or /ontology_term_types/1.json
  def show
  end

  # GET /ontology_term_types/new
  def new
    @ontology_term_type = OntologyTermType.new
  end

  # GET /ontology_term_types/1/edit
  def edit
  end

  # POST /ontology_term_types or /ontology_term_types.json
  def create
    @ontology_term_type = OntologyTermType.new(ontology_term_type_params)

    respond_to do |format|
      if admin? and @ontology_term_type.save
        format.html { redirect_to ontology_term_type_url(@ontology_term_type), notice: "Ontology term type was successfully created." }
        format.json { render :show, status: :created, location: @ontology_term_type }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @ontology_term_type.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /ontology_term_types/1 or /ontology_term_types/1.json
  def update
    respond_to do |format|
      if admin? and @ontology_term_type.update(ontology_term_type_params)
        format.html { redirect_to ontology_term_type_url(@ontology_term_type), notice: "Ontology term type was successfully updated." }
        format.json { render :show, status: :ok, location: @ontology_term_type }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @ontology_term_type.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /ontology_term_types/1 or /ontology_term_types/1.json
  def destroy
    @ontology_term_type.destroy if admin?

    respond_to do |format|
      format.html { redirect_to ontology_term_types_url, notice: "Ontology term type was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_ontology_term_type
      @ontology_term_type = OntologyTermType.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def ontology_term_type_params
      params.fetch(:ontology_term_type).permit(:name, :label, :cell_ontology_ids, :in_lineage_term_ids, :term_ids, :free_text_json)
    end
end
