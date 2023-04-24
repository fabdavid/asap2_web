class SampleIdentifiersController < ApplicationController
  before_action :set_sample_identifier, only: [:show, :edit, :update, :destroy]

  # GET /sample_identifiers
  # GET /sample_identifiers.json
  def index
    @sample_identifiers = SampleIdentifier.all
  end

  # GET /sample_identifiers/1
  # GET /sample_identifiers/1.json
  def show
  end

  # GET /sample_identifiers/new
  def new
    @sample_identifier = SampleIdentifier.new
  end

  # GET /sample_identifiers/1/edit
  def edit
  end

  # POST /sample_identifiers
  # POST /sample_identifiers.json
  def create
    @sample_identifier = SampleIdentifier.new(sample_identifier_params)

    respond_to do |format|
      if admin? and @sample_identifier.save
        format.html { redirect_to @sample_identifier, notice: 'Sample identifier was successfully created.' }
        format.json { render :show, status: :created, location: @sample_identifier }
      else
        format.html { render :new }
        format.json { render json: @sample_identifier.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /sample_identifiers/1
  # PATCH/PUT /sample_identifiers/1.json
  def update
    respond_to do |format|
      if admin? and @sample_identifier.update(sample_identifier_params)
        format.html { redirect_to @sample_identifier, notice: 'Sample identifier was successfully updated.' }
        format.json { render :show, status: :ok, location: @sample_identifier }
      else
        format.html { render :edit }
        format.json { render json: @sample_identifier.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /sample_identifiers/1
  # DELETE /sample_identifiers/1.json
  def destroy
    if admin?
      @sample_identifier.destroy
      respond_to do |format|
        format.html { redirect_to sample_identifiers_url, notice: 'Sample identifier was successfully destroyed.' }
        format.json { head :no_content }
      end
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_sample_identifier
      @sample_identifier = SampleIdentifier.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def sample_identifier_params
      params.fetch(:sample_identifier, {})
    end
end
