class StdMethodsController < ApplicationController
  before_action :set_std_method, only: [:show, :edit, :update, :destroy]

  # GET /std_methods
  # GET /std_methods.json
  def index
    @std_methods = StdMethod.all
  end

  # GET /std_methods/1
  # GET /std_methods/1.json
  def show
  end

  # GET /std_methods/new
  def new
    @std_method = StdMethod.new
  end

  # GET /std_methods/1/edit
  def edit
  end

  # POST /std_methods
  # POST /std_methods.json
  def create
    @std_method = StdMethod.new(std_method_params)

    respond_to do |format|
      if @std_method.save
        format.html { redirect_to @std_method, notice: 'Std method was successfully created.' }
        format.json { render :show, status: :created, location: @std_method }
      else
        format.html { render :new }
        format.json { render json: @std_method.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /std_methods/1
  # PATCH/PUT /std_methods/1.json
  def update
    respond_to do |format|
      if @std_method.update(std_method_params)
        format.html { redirect_to @std_method, notice: 'Std method was successfully updated.' }
        format.json { render :show, status: :ok, location: @std_method }
      else
        format.html { render :edit }
        format.json { render json: @std_method.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /std_methods/1
  # DELETE /std_methods/1.json
  def destroy
    @std_method.destroy
    respond_to do |format|
      format.html { redirect_to std_methods_url, notice: 'Std method was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_std_method
      @std_method = StdMethod.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def std_method_params
      params.fetch(:std_method).permit(:name, :label, :step_id, :description, :short_label, :program, :command_json, :link, :speed_id, :attrs_json, :attr_layout_json, :obj_attrs_json)
    end
end
