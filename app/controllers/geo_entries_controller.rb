class GeoEntriesController < ApplicationController
  before_action :set_geo_entry, only: [:show, :edit, :update, :destroy, :summary]


  def summary
    render :partial => 'summary'
  end

  # GET /geo_entries
  # GET /geo_entries.json
  def index
    @geo_entries = GeoEntry.all
  end

  # GET /geo_entries/1
  # GET /geo_entries/1.json
  def show
  end

  # GET /geo_entries/new
  def new
    @geo_entry = GeoEntry.new
  end

  # GET /geo_entries/1/edit
  def edit
  end

  # POST /geo_entries
  # POST /geo_entries.json
  def create
    @geo_entry = GeoEntry.new(geo_entry_params)

    respond_to do |format|
      if @geo_entry.save
        format.html { redirect_to @geo_entry, notice: 'Geo entry was successfully created.' }
        format.json { render :show, status: :created, location: @geo_entry }
      else
        format.html { render :new }
        format.json { render json: @geo_entry.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /geo_entries/1
  # PATCH/PUT /geo_entries/1.json
  def update
    respond_to do |format|
      if @geo_entry.update(geo_entry_params)
        format.html { redirect_to @geo_entry, notice: 'Geo entry was successfully updated.' }
        format.json { render :show, status: :ok, location: @geo_entry }
      else
        format.html { render :edit }
        format.json { render json: @geo_entry.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /geo_entries/1
  # DELETE /geo_entries/1.json
  def destroy
    @geo_entry.destroy
    respond_to do |format|
      format.html { redirect_to geo_entries_url, notice: 'Geo entry was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_geo_entry
      @geo_entry = GeoEntry.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def geo_entry_params
      params.fetch(:geo_entry, {})
    end
end
