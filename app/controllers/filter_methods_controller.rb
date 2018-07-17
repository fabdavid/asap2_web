class FilterMethodsController < ApplicationController
  before_action :set_filter_method, only: [:show, :edit, :update, :destroy]

  # GET /filter_methods
  # GET /filter_methods.json
  def index
    @filter_methods = FilterMethod.all
  end

  # GET /filter_methods/1
  # GET /filter_methods/1.json
  def show
  end

  # GET /filter_methods/new
  def new
    @filter_method = FilterMethod.new
  end

  # GET /filter_methods/1/edit
  def edit
  end

  # POST /filter_methods
  # POST /filter_methods.json
  def create
    @filter_method = FilterMethod.new(filter_method_params)

    respond_to do |format|
      if @filter_method.save
        format.html { redirect_to @filter_method, notice: 'Filter method was successfully created.' }
        format.json { render :show, status: :created, location: @filter_method }
      else
        format.html { render :new }
        format.json { render json: @filter_method.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /filter_methods/1
  # PATCH/PUT /filter_methods/1.json
  def update
    respond_to do |format|
      if @filter_method.update(filter_method_params)
        format.html { redirect_to @filter_method, notice: 'Filter method was successfully updated.' }
        format.json { render :show, status: :ok, location: @filter_method }
      else
        format.html { render :edit }
        format.json { render json: @filter_method.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /filter_methods/1
  # DELETE /filter_methods/1.json
  def destroy
    @filter_method.destroy
    respond_to do |format|
      format.html { redirect_to filter_methods_url, notice: 'Filter method was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_filter_method
      @filter_method = FilterMethod.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def filter_method_params
      params.fetch(:filter_method, {})
    end
end
