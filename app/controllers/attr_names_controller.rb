class AttrNamesController < ApplicationController
  before_action :set_attr_name, only: [:show, :edit, :update, :destroy]

  # GET /attr_names
  # GET /attr_names.json
  def index
    @attr_names = AttrName.all
  end

  # GET /attr_names/1
  # GET /attr_names/1.json
  def show
  end

  # GET /attr_names/new
  def new
    @attr_name = AttrName.new
  end

  # GET /attr_names/1/edit
  def edit
  end

  # POST /attr_names
  # POST /attr_names.json
  def create
    @attr_name = AttrName.new(attr_name_params)

    respond_to do |format|
      if @attr_name.save
        format.html { redirect_to @attr_name, notice: 'Attr name was successfully created.' }
        format.json { render :show, status: :created, location: @attr_name }
      else
        format.html { render :new }
        format.json { render json: @attr_name.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /attr_names/1
  # PATCH/PUT /attr_names/1.json
  def update
    respond_to do |format|
      if @attr_name.update(attr_name_params)
        format.html { redirect_to @attr_name, notice: 'Attr name was successfully updated.' }
        format.json { render :show, status: :ok, location: @attr_name }
      else
        format.html { render :edit }
        format.json { render json: @attr_name.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /attr_names/1
  # DELETE /attr_names/1.json
  def destroy
    @attr_name.destroy
    respond_to do |format|
      format.html { redirect_to attr_names_url, notice: 'Attr name was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_attr_name
      @attr_name = AttrName.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def attr_name_params
      params.fetch(:attr_name, {})
    end
end
