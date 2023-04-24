class ExpEntriesController < ApplicationController
  before_action :set_exp_entry, only: [:show, :edit, :update, :destroy, :summary]

  layout "welcome"

  def summary
    render :partial => 'summary'
  end

  # GET /exp_entries
  # GET /exp_entries.json
  def index
    @exp_entries = ExpEntry.all
  end

  # GET /exp_entries/1
  # GET /exp_entries/1.json
  def show
    @h_identifier_types = {}
    IdentifierType.all.map{|it| @h_identifier_types[it.id] = it}
  end

  # GET /exp_entries/new
  def new
    @exp_entry = ExpEntry.new
  end

  # GET /exp_entries/1/edit
  def edit
  end

  # POST /exp_entries
  # POST /exp_entries.json
  def create
    @exp_entry = ExpEntry.new(exp_entry_params)

    respond_to do |format|
      if admin? and @exp_entry.save
        format.html { redirect_to @exp_entry, notice: 'Exp entry was successfully created.' }
        format.json { render :show, status: :created, location: @exp_entry }
      else
        format.html { render :new }
        format.json { render json: @exp_entry.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /exp_entries/1
  # PATCH/PUT /exp_entries/1.json
  def update
    respond_to do |format|
      if admin? and @exp_entry.update(exp_entry_params)
        format.html { redirect_to @exp_entry, notice: 'Exp entry was successfully updated.' }
        format.json { render :show, status: :ok, location: @exp_entry }
      else
        format.html { render :edit }
        format.json { render json: @exp_entry.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /exp_entries/1
  # DELETE /exp_entries/1.json
  def destroy
    if admin?
      @exp_entry.destroy
      respond_to do |format|
        format.html { redirect_to exp_entries_url, notice: 'Exp entry was successfully destroyed.' }
        format.json { head :no_content }
      end
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_exp_entry
      @exp_entry = ExpEntry.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def exp_entry_params
      params.fetch(:exp_entry, {})
    end
end
