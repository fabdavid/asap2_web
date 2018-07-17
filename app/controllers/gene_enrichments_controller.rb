class GeneEnrichmentsController < ApplicationController
  before_action :set_gene_enrichment, only: [:show, :edit, :update, :destroy]

  # GET /gene_enrichments
  # GET /gene_enrichments.json
  def index
    @gene_enrichments = GeneEnrichment.all
  end

  # GET /gene_enrichments/1
  # GET /gene_enrichments/1.json
  def show
  end

  # GET /gene_enrichments/new
  def new
    @gene_enrichment = GeneEnrichment.new
  end

  # GET /gene_enrichments/1/edit
  def edit
  end

  # POST /gene_enrichments
  # POST /gene_enrichments.json
  def create
    @gene_enrichment = GeneEnrichment.new(gene_enrichment_params)

    respond_to do |format|
      if @gene_enrichment.save
        format.html { redirect_to @gene_enrichment, notice: 'Gene enrichment was successfully created.' }
        format.json { render :show, status: :created, location: @gene_enrichment }
      else
        format.html { render :new }
        format.json { render json: @gene_enrichment.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /gene_enrichments/1
  # PATCH/PUT /gene_enrichments/1.json
  def update
    respond_to do |format|
      if @gene_enrichment.update(gene_enrichment_params)
        format.html { redirect_to @gene_enrichment, notice: 'Gene enrichment was successfully updated.' }
        format.json { render :show, status: :ok, location: @gene_enrichment }
      else
        format.html { render :edit }
        format.json { render json: @gene_enrichment.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /gene_enrichments/1
  # DELETE /gene_enrichments/1.json
  def destroy
    @gene_enrichment.destroy
    respond_to do |format|
      format.html { redirect_to gene_enrichments_url, notice: 'Gene enrichment was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_gene_enrichment
      @gene_enrichment = GeneEnrichment.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def gene_enrichment_params
      params.fetch(:gene_enrichment, {})
    end
end
