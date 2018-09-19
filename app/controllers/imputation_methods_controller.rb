class ImputationMethodsController < ApplicationController
  before_action :set_imputation_method, only: [:show, :edit, :update, :destroy]

  # GET /imputation_methods
  # GET /imputation_methods.json
  def index
    @imputation_methods = ImputationMethod.all
  end

  # GET /imputation_methods/1
  # GET /imputation_methods/1.json
  def show
  end

  # GET /imputation_methods/new
  def new
    @imputation_method = ImputationMethod.new
  end

  # GET /imputation_methods/1/edit
  def edit
  end

  # POST /imputation_methods
  # POST /imputation_methods.json
  def create
    @imputation_method = ImputationMethod.new(imputation_method_params)

    respond_to do |format|
      if @imputation_method.save
        format.html { redirect_to @imputation_method, notice: 'Imputation method was successfully created.' }
        format.json { render :show, status: :created, location: @imputation_method }
      else
        format.html { render :new }
        format.json { render json: @imputation_method.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /imputation_methods/1
  # PATCH/PUT /imputation_methods/1.json
  def update
    respond_to do |format|
      if @imputation_method.update(imputation_method_params)
        format.html { redirect_to @imputation_method, notice: 'Imputation method was successfully updated.' }
        format.json { render :show, status: :ok, location: @imputation_method }
      else
        format.html { render :edit }
        format.json { render json: @imputation_method.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /imputation_methods/1
  # DELETE /imputation_methods/1.json
  def destroy
    @imputation_method.destroy
    respond_to do |format|
      format.html { redirect_to imputation_methods_url, notice: 'Imputation method was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_imputation_method
      @imputation_method = ImputationMethod.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def imputation_method_params
      params.fetch(:imputation_method, {})
    end
end
