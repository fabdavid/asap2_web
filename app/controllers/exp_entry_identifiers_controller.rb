class ExpEntryIdentifiersController < ApplicationController
  before_action :set_exp_entry_identifier, only: [:show, :edit, :update, :destroy]

  # GET /exp_entry_identifiers
  # GET /exp_entry_identifiers.json
  def index
    @exp_entry_identifiers = ExpEntryIdentifier.all
  end

  # GET /exp_entry_identifiers/1
  # GET /exp_entry_identifiers/1.json
  def show
  end

  # GET /exp_entry_identifiers/new
  def new
    @exp_entry_identifier = ExpEntryIdentifier.new
  end

  # GET /exp_entry_identifiers/1/edit
  def edit
  end

  # POST /exp_entry_identifiers
  # POST /exp_entry_identifiers.json
  def create
    @exp_entry_identifier = ExpEntryIdentifier.new(exp_entry_identifier_params)

    respond_to do |format|
      if admin? and @exp_entry_identifier.save
        format.html { redirect_to @exp_entry_identifier, notice: 'Exp entry identifier was successfully created.' }
        format.json { render :show, status: :created, location: @exp_entry_identifier }
      else
        format.html { render :new }
        format.json { render json: @exp_entry_identifier.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /exp_entry_identifiers/1
  # PATCH/PUT /exp_entry_identifiers/1.json
  def update
    respond_to do |format|
      if admin? and @exp_entry_identifier.update(exp_entry_identifier_params)
        format.html { redirect_to @exp_entry_identifier, notice: 'Exp entry identifier was successfully updated.' }
        format.json { render :show, status: :ok, location: @exp_entry_identifier }
      else
        format.html { render :edit }
        format.json { render json: @exp_entry_identifier.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /exp_entry_identifiers/1
  # DELETE /exp_entry_identifiers/1.json
  def destroy
    if admin?
      @exp_entry_identifier.destroy
      respond_to do |format|
        format.html { redirect_to exp_entry_identifiers_url, notice: 'Exp entry identifier was successfully destroyed.' }
        format.json { head :no_content }
      end
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_exp_entry_identifier
      @exp_entry_identifier = ExpEntryIdentifier.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def exp_entry_identifier_params
      params.fetch(:exp_entry_identifier, {})
    end
end
