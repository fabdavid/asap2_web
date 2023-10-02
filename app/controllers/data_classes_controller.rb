class DataClassesController < ApplicationController
  before_action :set_data_class, only: [:show, :edit, :update, :destroy]

  # GET /data_classes
  # GET /data_classes.json
  def index
    @data_classes = DataClass.all
  end

  # GET /data_classes/1
  # GET /data_classes/1.json
  def show
  end

  # GET /data_classes/new
  def new
    @data_class = DataClass.new
  end

  # GET /data_classes/1/edit
  def edit
  end

  # POST /data_classes
  # POST /data_classes.json
  def create
    @data_class = DataClass.new(data_class_params)

    respond_to do |format|
      if @data_class.save
        format.html { redirect_to @data_class, notice: 'Data class was successfully created.' }
        format.json { render :show, status: :created, location: @data_class }
      else
        format.html { render :new }
        format.json { render json: @data_class.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /data_classes/1
  # PATCH/PUT /data_classes/1.json
  def update
    respond_to do |format|
      if @data_class.update(data_class_params)
        format.html { redirect_to @data_class, notice: 'Data class was successfully updated.' }
        format.json { render :show, status: :ok, location: @data_class }
      else
        format.html { render :edit }
        format.json { render json: @data_class.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /data_classes/1
  # DELETE /data_classes/1.json
  def destroy
    @data_class.destroy
    respond_to do |format|
      format.html { redirect_to data_classes_url, notice: 'Data class was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_data_class
      @data_class = DataClass.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def data_class_params
      params.fetch(:data_class, {})
    end
end
