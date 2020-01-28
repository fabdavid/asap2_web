class IdentifierTypesController < ApplicationController
  before_action :set_identifier_type, only: [:show, :edit, :update, :destroy]

  # GET /identifier_types
  # GET /identifier_types.json
  def index
    @identifier_types = IdentifierType.all
  end

  # GET /identifier_types/1
  # GET /identifier_types/1.json
  def show
  end

  # GET /identifier_types/new
  def new
    @identifier_type = IdentifierType.new
  end

  # GET /identifier_types/1/edit
  def edit
  end

  # POST /identifier_types
  # POST /identifier_types.json
  def create
    @identifier_type = IdentifierType.new(identifier_type_params)

    respond_to do |format|
      if @identifier_type.save
        format.html { redirect_to @identifier_type, notice: 'Identifier type was successfully created.' }
        format.json { render :show, status: :created, location: @identifier_type }
      else
        format.html { render :new }
        format.json { render json: @identifier_type.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /identifier_types/1
  # PATCH/PUT /identifier_types/1.json
  def update
    respond_to do |format|
      if @identifier_type.update(identifier_type_params)
        format.html { redirect_to @identifier_type, notice: 'Identifier type was successfully updated.' }
        format.json { render :show, status: :ok, location: @identifier_type }
      else
        format.html { render :edit }
        format.json { render json: @identifier_type.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /identifier_types/1
  # DELETE /identifier_types/1.json
  def destroy
    @identifier_type.destroy
    respond_to do |format|
      format.html { redirect_to identifier_types_url, notice: 'Identifier type was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_identifier_type
      @identifier_type = IdentifierType.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def identifier_type_params
      params.fetch(:identifier_type, {})
    end
end
