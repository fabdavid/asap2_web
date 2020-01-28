class TmpGenesController < ApplicationController
  before_action :set_tmp_gene, only: [:show, :edit, :update, :destroy]

  # GET /tmp_genes
  # GET /tmp_genes.json
  def index
    @tmp_genes = TmpGene.all
  end

  # GET /tmp_genes/1
  # GET /tmp_genes/1.json
  def show
  end

  # GET /tmp_genes/new
  def new
    @tmp_gene = TmpGene.new
  end

  # GET /tmp_genes/1/edit
  def edit
  end

  # POST /tmp_genes
  # POST /tmp_genes.json
  def create
    @tmp_gene = TmpGene.new(tmp_gene_params)

    respond_to do |format|
      if @tmp_gene.save
        format.html { redirect_to @tmp_gene, notice: 'Tmp gene was successfully created.' }
        format.json { render :show, status: :created, location: @tmp_gene }
      else
        format.html { render :new }
        format.json { render json: @tmp_gene.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /tmp_genes/1
  # PATCH/PUT /tmp_genes/1.json
  def update
    respond_to do |format|
      if @tmp_gene.update(tmp_gene_params)
        format.html { redirect_to @tmp_gene, notice: 'Tmp gene was successfully updated.' }
        format.json { render :show, status: :ok, location: @tmp_gene }
      else
        format.html { render :edit }
        format.json { render json: @tmp_gene.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /tmp_genes/1
  # DELETE /tmp_genes/1.json
  def destroy
    @tmp_gene.destroy
    respond_to do |format|
      format.html { redirect_to tmp_genes_url, notice: 'Tmp gene was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_tmp_gene
      @tmp_gene = TmpGene.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def tmp_gene_params
      params.fetch(:tmp_gene, {})
    end
end
