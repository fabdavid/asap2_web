class FosController < ApplicationController
  before_action :set_fo, only: [:show, :edit, :update, :destroy]

  # GET /fos
  # GET /fos.json
  def index
    @fos = Fo.all
  end

  # GET /fos/1
  # GET /fos/1.json
  def show
  end

  # GET /fos/new
  def new
    @fo = Fo.new
  end

  # GET /fos/1/edit
  def edit
  end

  # POST /fos
  # POST /fos.json
  def create
    @fo = Fo.new(fo_params)

    respond_to do |format|
      if @fo.save
        format.html { redirect_to @fo, notice: 'Fo was successfully created.' }
        format.json { render :show, status: :created, location: @fo }
      else
        format.html { render :new }
        format.json { render json: @fo.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /fos/1
  # PATCH/PUT /fos/1.json
  def update
    respond_to do |format|
      if @fo.update(fo_params)
        format.html { redirect_to @fo, notice: 'Fo was successfully updated.' }
        format.json { render :show, status: :ok, location: @fo }
      else
        format.html { render :edit }
        format.json { render json: @fo.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /fos/1
  # DELETE /fos/1.json
  def destroy
    @fo.destroy
    respond_to do |format|
      format.html { redirect_to fos_url, notice: 'Fo was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_fo
      @fo = Fo.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def fo_params
      params.fetch(:fo, {})
    end
end
