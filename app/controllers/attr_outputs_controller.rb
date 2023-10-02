class AttrOutputsController < ApplicationController
  before_action :set_attr_output, only: [:show, :edit, :update, :destroy]

  # GET /attr_outputs
  # GET /attr_outputs.json
  def index
    @attr_outputs = AttrOutput.all
  end

  # GET /attr_outputs/1
  # GET /attr_outputs/1.json
  def show
  end

  # GET /attr_outputs/new
  def new
    @attr_output = AttrOutput.new
  end

  # GET /attr_outputs/1/edit
  def edit
  end

  # POST /attr_outputs
  # POST /attr_outputs.json
  def create
    @attr_output = AttrOutput.new(attr_output_params)

    respond_to do |format|
      if @attr_output.save
        format.html { redirect_to @attr_output, notice: 'Attr output was successfully created.' }
        format.json { render :show, status: :created, location: @attr_output }
      else
        format.html { render :new }
        format.json { render json: @attr_output.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /attr_outputs/1
  # PATCH/PUT /attr_outputs/1.json
  def update
    respond_to do |format|
      if @attr_output.update(attr_output_params)
        format.html { redirect_to @attr_output, notice: 'Attr output was successfully updated.' }
        format.json { render :show, status: :ok, location: @attr_output }
      else
        format.html { render :edit }
        format.json { render json: @attr_output.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /attr_outputs/1
  # DELETE /attr_outputs/1.json
  def destroy
    @attr_output.destroy
    respond_to do |format|
      format.html { redirect_to attr_outputs_url, notice: 'Attr output was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_attr_output
      @attr_output = AttrOutput.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def attr_output_params
      params.fetch(:attr_output, {})
    end
end
