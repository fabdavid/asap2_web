class TmpFosController < ApplicationController
  before_action :set_tmp_fo, only: [:show, :edit, :update, :destroy]

  # GET /tmp_fos
  # GET /tmp_fos.json
  def index
    @tmp_fos = TmpFo.all
  end

  # GET /tmp_fos/1
  # GET /tmp_fos/1.json
  def show
  end

  # GET /tmp_fos/new
  def new
    @tmp_fo = TmpFo.new
  end

  # GET /tmp_fos/1/edit
  def edit
  end

  # POST /tmp_fos
  # POST /tmp_fos.json
  def create
    @tmp_fo = TmpFo.new(tmp_fo_params)

    respond_to do |format|
      if @tmp_fo.save
        format.html { redirect_to @tmp_fo, notice: 'Tmp fo was successfully created.' }
        format.json { render :show, status: :created, location: @tmp_fo }
      else
        format.html { render :new }
        format.json { render json: @tmp_fo.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /tmp_fos/1
  # PATCH/PUT /tmp_fos/1.json
  def update
    respond_to do |format|
      if @tmp_fo.update(tmp_fo_params)
        format.html { redirect_to @tmp_fo, notice: 'Tmp fo was successfully updated.' }
        format.json { render :show, status: :ok, location: @tmp_fo }
      else
        format.html { render :edit }
        format.json { render json: @tmp_fo.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /tmp_fos/1
  # DELETE /tmp_fos/1.json
  def destroy
    @tmp_fo.destroy
    respond_to do |format|
      format.html { redirect_to tmp_fos_url, notice: 'Tmp fo was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_tmp_fo
      @tmp_fo = TmpFo.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def tmp_fo_params
      params.fetch(:tmp_fo, {})
    end
end
