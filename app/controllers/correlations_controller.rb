class CorrelationsController < ApplicationController
  before_action :set_correlation, only: [:show, :edit, :update, :destroy]

  # GET /correlations
  # GET /correlations.json
  def index
    @correlations = Correlation.all
  end

  # GET /correlations/1
  # GET /correlations/1.json
  def show
  end

  # GET /correlations/new
  def new
    @correlation = Correlation.new
  end

  # GET /correlations/1/edit
  def edit
  end

  # POST /correlations
  # POST /correlations.json
  def create
    @correlation = Correlation.new(correlation_params)

    respond_to do |format|
      if @correlation.save
        format.html { redirect_to @correlation, notice: 'Correlation was successfully created.' }
        format.json { render :show, status: :created, location: @correlation }
      else
        format.html { render :new }
        format.json { render json: @correlation.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /correlations/1
  # PATCH/PUT /correlations/1.json
  def update
    respond_to do |format|
      if @correlation.update(correlation_params)
        format.html { redirect_to @correlation, notice: 'Correlation was successfully updated.' }
        format.json { render :show, status: :ok, location: @correlation }
      else
        format.html { render :edit }
        format.json { render json: @correlation.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /correlations/1
  # DELETE /correlations/1.json
  def destroy
    @correlation.destroy
    respond_to do |format|
      format.html { redirect_to correlations_url, notice: 'Correlation was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_correlation
      @correlation = Correlation.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def correlation_params
      params.fetch(:correlation, {})
    end
end
