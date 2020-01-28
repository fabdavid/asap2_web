class EnsemblSubdomainsController < ApplicationController
  before_action :set_ensembl_subdomain, only: [:show, :edit, :update, :destroy]

  # GET /ensembl_subdomains
  # GET /ensembl_subdomains.json
  def index
    @ensembl_subdomains = EnsemblSubdomain.all
  end

  # GET /ensembl_subdomains/1
  # GET /ensembl_subdomains/1.json
  def show
  end

  # GET /ensembl_subdomains/new
  def new
    @ensembl_subdomain = EnsemblSubdomain.new
  end

  # GET /ensembl_subdomains/1/edit
  def edit
  end

  # POST /ensembl_subdomains
  # POST /ensembl_subdomains.json
  def create
    @ensembl_subdomain = EnsemblSubdomain.new(ensembl_subdomain_params)

    respond_to do |format|
      if @ensembl_subdomain.save
        format.html { redirect_to @ensembl_subdomain, notice: 'Ensembl subdomain was successfully created.' }
        format.json { render :show, status: :created, location: @ensembl_subdomain }
      else
        format.html { render :new }
        format.json { render json: @ensembl_subdomain.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /ensembl_subdomains/1
  # PATCH/PUT /ensembl_subdomains/1.json
  def update
    respond_to do |format|
      if @ensembl_subdomain.update(ensembl_subdomain_params)
        format.html { redirect_to @ensembl_subdomain, notice: 'Ensembl subdomain was successfully updated.' }
        format.json { render :show, status: :ok, location: @ensembl_subdomain }
      else
        format.html { render :edit }
        format.json { render json: @ensembl_subdomain.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /ensembl_subdomains/1
  # DELETE /ensembl_subdomains/1.json
  def destroy
    @ensembl_subdomain.destroy
    respond_to do |format|
      format.html { redirect_to ensembl_subdomains_url, notice: 'Ensembl subdomain was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_ensembl_subdomain
      @ensembl_subdomain = EnsemblSubdomain.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def ensembl_subdomain_params
      params.fetch(:ensembl_subdomain, {})
    end
end
