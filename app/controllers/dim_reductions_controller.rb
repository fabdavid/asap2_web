class DimReductionsController < ApplicationController
  before_action :set_dim_reduction, only: [:show, :edit, :update, :destroy]

  # GET /dim_reductions
  # GET /dim_reductions.json
  def index
    @dim_reductions = DimReduction.all
  end

  # GET /dim_reductions/1
  # GET /dim_reductions/1.json
  def show
  end

  # GET /dim_reductions/new
  def new
    @dim_reduction = DimReduction.new
  end

  # GET /dim_reductions/1/edit
  def edit
  end

  # POST /dim_reductions
  # POST /dim_reductions.json
  def create
    @dim_reduction = DimReduction.new(dim_reduction_params)

    respond_to do |format|
      if @dim_reduction.save
        format.html { redirect_to @dim_reduction, notice: 'Dim reduction was successfully created.' }
        format.json { render :show, status: :created, location: @dim_reduction }
      else
        format.html { render :new }
        format.json { render json: @dim_reduction.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /dim_reductions/1
  # PATCH/PUT /dim_reductions/1.json
  def update
    respond_to do |format|
      if @dim_reduction.update(dim_reduction_params)
        format.html { redirect_to @dim_reduction, notice: 'Dim reduction was successfully updated.' }
        format.json { render :show, status: :ok, location: @dim_reduction }
      else
        format.html { render :edit }
        format.json { render json: @dim_reduction.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /dim_reductions/1
  # DELETE /dim_reductions/1.json
  def destroy
    @dim_reduction.destroy
    respond_to do |format|
      format.html { redirect_to dim_reductions_url, notice: 'Dim reduction was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_dim_reduction
      @dim_reduction = DimReduction.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def dim_reduction_params
      params.fetch(:dim_reduction, {})
    end
end
