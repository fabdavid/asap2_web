class CovariatesController < ApplicationController
  before_action :set_covariate, only: [:show, :edit, :update, :destroy]

  # GET /covariates
  # GET /covariates.json
  def index
    @covariates = Covariate.all
  end

  # GET /covariates/1
  # GET /covariates/1.json
  def show
  end

  # GET /covariates/new
  def new
    @covariate = Covariate.new
  end

  # GET /covariates/1/edit
  def edit
  end

  # POST /covariates
  # POST /covariates.json
  def create
    @covariate = Covariate.new(covariate_params)

    respond_to do |format|
      if @covariate.save
        format.html { redirect_to @covariate, notice: 'Covariate was successfully created.' }
        format.json { render :show, status: :created, location: @covariate }
      else
        format.html { render :new }
        format.json { render json: @covariate.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /covariates/1
  # PATCH/PUT /covariates/1.json
  def update
    respond_to do |format|
      if @covariate.update(covariate_params)
        format.html { redirect_to @covariate, notice: 'Covariate was successfully updated.' }
        format.json { render :show, status: :ok, location: @covariate }
      else
        format.html { render :edit }
        format.json { render json: @covariate.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /covariates/1
  # DELETE /covariates/1.json
  def destroy
    @covariate.destroy
    respond_to do |format|
      format.html { redirect_to covariates_url, notice: 'Covariate was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_covariate
      @covariate = Covariate.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def covariate_params
      params.fetch(:covariate, {})
    end
end
