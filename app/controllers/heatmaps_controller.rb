class HeatmapsController < ApplicationController
  before_action :set_heatmap, only: [:show, :edit, :update, :destroy]

  # GET /heatmaps
  # GET /heatmaps.json
  def index
    @heatmaps = Heatmap.all
  end

  # GET /heatmaps/1
  # GET /heatmaps/1.json
  def show
  end

  # GET /heatmaps/new
  def new
    @heatmap = Heatmap.new
  end

  # GET /heatmaps/1/edit
  def edit
  end

  # POST /heatmaps
  # POST /heatmaps.json
  def create
    @heatmap = Heatmap.new(heatmap_params)

    respond_to do |format|
      if @heatmap.save
        format.html { redirect_to @heatmap, notice: 'Heatmap was successfully created.' }
        format.json { render :show, status: :created, location: @heatmap }
      else
        format.html { render :new }
        format.json { render json: @heatmap.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /heatmaps/1
  # PATCH/PUT /heatmaps/1.json
  def update
    respond_to do |format|
      if @heatmap.update(heatmap_params)
        format.html { redirect_to @heatmap, notice: 'Heatmap was successfully updated.' }
        format.json { render :show, status: :ok, location: @heatmap }
      else
        format.html { render :edit }
        format.json { render json: @heatmap.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /heatmaps/1
  # DELETE /heatmaps/1.json
  def destroy
    @heatmap.destroy
    respond_to do |format|
      format.html { redirect_to heatmaps_url, notice: 'Heatmap was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_heatmap
      @heatmap = Heatmap.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def heatmap_params
      params.fetch(:heatmap, {})
    end
end
