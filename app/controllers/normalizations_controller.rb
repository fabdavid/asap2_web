class NormalizationsController < ApplicationController
  before_action :set_normalization, only: [:show, :edit, :update, :destroy]

  # GET /normalizations
  # GET /normalizations.json
  def index
    @normalizations = Normalization.all
  end

  # GET /normalizations/1
  # GET /normalizations/1.json
  def show
  end

  # GET /normalizations/new
  def new
    @normalization = Normalization.new
  end

  # GET /normalizations/1/edit
  def edit
  end

  # POST /normalizations
  # POST /normalizations.json
  def create
    @normalization = Normalization.new(normalization_params)

    respond_to do |format|
      if @normalization.save
        format.html { redirect_to @normalization, notice: 'Normalization was successfully created.' }
        format.json { render :show, status: :created, location: @normalization }
      else
        format.html { render :new }
        format.json { render json: @normalization.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /normalizations/1
  # PATCH/PUT /normalizations/1.json
  def update
    respond_to do |format|
      if @normalization.update(normalization_params)
        format.html { redirect_to @normalization, notice: 'Normalization was successfully updated.' }
        format.json { render :show, status: :ok, location: @normalization }
      else
        format.html { render :edit }
        format.json { render json: @normalization.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /normalizations/1
  # DELETE /normalizations/1.json
  def destroy
    @normalization.destroy
    respond_to do |format|
      format.html { redirect_to normalizations_url, notice: 'Normalization was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_normalization
      @normalization = Normalization.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def normalization_params
      params.fetch(:normalization, {})
    end
end
