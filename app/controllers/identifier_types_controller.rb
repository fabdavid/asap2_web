class IdentifierTypesController < ApplicationController
  before_action :set_identifier_type, only: [:show, :edit, :update, :destroy]

  layout "welcome"

  # GET /identifier_types
  # GET /identifier_types.json
  def index
    @h_identifier_types = {}
    IdentifierType.all.each do |it|
      @h_identifier_types[it.name] = it
    end
  end

  # GET /identifier_types/1
  # GET /identifier_types/1.json
  def show
    @h_identifier_types = {}
    IdentifierType.all.map{|it| @h_identifier_types[it.id] = it}
    
    @exp_entries = @identifier_type.exp_entries
    @h_exp_entries = {}
    @exp_entries.map{|e| @h_exp_entries[e.id] = e}
    @exp_entry_identifiers = @identifier_type.exp_entry_identifiers
    ExpEntry.where(:id => @exp_entry_identifiers.map{|e| e.exp_entry_id}).all.map{|e| @h_exp_entries[e.id] = e}
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
      if admin? and @identifier_type.save
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
      if admin? and @identifier_type.update(identifier_type_params)
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
    if admin?
      @identifier_type.destroy
      respond_to do |format|
        format.html { redirect_to identifier_types_url, notice: 'Identifier type was successfully destroyed.' }
        format.json { head :no_content }
      end
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_identifier_type
      @identifier_type = IdentifierType.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def identifier_type_params
      params.fetch(:identifier_type).permit(:name, :url_mask, :pluralizable)
   #   params.permit(:
    end
end
