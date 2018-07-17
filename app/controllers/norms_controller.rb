class NormsController < ApplicationController
  before_action :set_norm, only: [:show, :edit, :update, :destroy]

  # GET /norms
  # GET /norms.json
  def index
    @norms = Norm.all
  end

  # GET /norms/1
  # GET /norms/1.json
  def show
  end

  # GET /norms/new
  def new
    @norm = Norm.new
  end

  # GET /norms/1/edit
  def edit
  end

  # POST /norms
  # POST /norms.json
  def create
    @norm = Norm.new(norm_params)

    respond_to do |format|
      if @norm.save
        format.html { redirect_to @norm, notice: 'Norm was successfully created.' }
        format.json { render :show, status: :created, location: @norm }
      else
        format.html { render :new }
        format.json { render json: @norm.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /norms/1
  # PATCH/PUT /norms/1.json
  def update
    respond_to do |format|
      if @norm.update(norm_params)
        format.html { redirect_to @norm, notice: 'Norm was successfully updated.' }
        format.json { render :show, status: :ok, location: @norm }
      else
        format.html { render :edit }
        format.json { render json: @norm.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /norms/1
  # DELETE /norms/1.json
  def destroy
    @norm.destroy
    respond_to do |format|
      format.html { redirect_to norms_url, notice: 'Norm was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_norm
      @norm = Norm.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def norm_params
      params.fetch(:norm, {})
    end
end
