class ImputationsController < ApplicationController
  before_action :set_imputation, only: [:show, :edit, :update, :destroy]

  # GET /imputations
  # GET /imputations.json
  def index
    @imputations = Imputation.all
  end

  # GET /imputations/1
  # GET /imputations/1.json
  def show
  end

  # GET /imputations/new
  def new
    @imputation = Imputation.new
  end

  # GET /imputations/1/edit
  def edit
  end

  # POST /imputations
  # POST /imputations.json
  def create
    @imputation = Imputation.new(imputation_params)

    respond_to do |format|
      if @imputation.save
        format.html { redirect_to @imputation, notice: 'Imputation was successfully created.' }
        format.json { render :show, status: :created, location: @imputation }
      else
        format.html { render :new }
        format.json { render json: @imputation.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /imputations/1
  # PATCH/PUT /imputations/1.json
  def update
    respond_to do |format|
      if @imputation.update(imputation_params)
        format.html { redirect_to @imputation, notice: 'Imputation was successfully updated.' }
        format.json { render :show, status: :ok, location: @imputation }
      else
        format.html { render :edit }
        format.json { render json: @imputation.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /imputations/1
  # DELETE /imputations/1.json
  def destroy
    @imputation.destroy
    respond_to do |format|
      format.html { redirect_to imputations_url, notice: 'Imputation was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_imputation
      @imputation = Imputation.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def imputation_params
      params.fetch(:imputation, {})
    end
end
