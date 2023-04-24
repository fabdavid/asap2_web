class ClaSourcesController < ApplicationController
  before_action :set_cla_source, only: [:show, :edit, :update, :destroy]

  # GET /cla_sources
  # GET /cla_sources.json
  def index
    @cla_sources = ClaSource.all
  end

  # GET /cla_sources/1
  # GET /cla_sources/1.json
  def show
  end

  # GET /cla_sources/new
  def new
    @cla_source = ClaSource.new
  end

  # GET /cla_sources/1/edit
  def edit
  end

  # POST /cla_sources
  # POST /cla_sources.json
  def create
    @cla_source = ClaSource.new(cla_source_params)

    respond_to do |format|
      if @cla_source.save
        format.html { redirect_to @cla_source, notice: 'Cla source was successfully created.' }
        format.json { render :show, status: :created, location: @cla_source }
      else
        format.html { render :new }
        format.json { render json: @cla_source.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /cla_sources/1
  # PATCH/PUT /cla_sources/1.json
  def update
    respond_to do |format|
      if @cla_source.update(cla_source_params)
        format.html { redirect_to @cla_source, notice: 'Cla source was successfully updated.' }
        format.json { render :show, status: :ok, location: @cla_source }
      else
        format.html { render :edit }
        format.json { render json: @cla_source.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /cla_sources/1
  # DELETE /cla_sources/1.json
  def destroy
    @cla_source.destroy
    respond_to do |format|
      format.html { redirect_to cla_sources_url, notice: 'Cla source was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_cla_source
      @cla_source = ClaSource.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def cla_source_params
      params.fetch(:cla_source).permit(:name)
    end
end
