class UploadTypesController < ApplicationController
  before_action :set_upload_type, only: [:show, :edit, :update, :destroy]

  # GET /upload_types
  # GET /upload_types.json
  def index
    @upload_types = UploadType.all
  end

  # GET /upload_types/1
  # GET /upload_types/1.json
  def show
  end

  # GET /upload_types/new
  def new
    @upload_type = UploadType.new
  end

  # GET /upload_types/1/edit
  def edit
  end

  # POST /upload_types
  # POST /upload_types.json
  def create
    @upload_type = UploadType.new(upload_type_params)

    respond_to do |format|
      if admin? and @upload_type.save
        format.html { redirect_to @upload_type, notice: 'Upload type was successfully created.' }
        format.json { render :show, status: :created, location: @upload_type }
      else
        format.html { render :new }
        format.json { render json: @upload_type.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /upload_types/1
  # PATCH/PUT /upload_types/1.json
  def update
    respond_to do |format|
      if admin? and @upload_type.update(upload_type_params)
        format.html { redirect_to @upload_type, notice: 'Upload type was successfully updated.' }
        format.json { render :show, status: :ok, location: @upload_type }
      else
        format.html { render :edit }
        format.json { render json: @upload_type.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /upload_types/1
  # DELETE /upload_types/1.json
  def destroy
    if admin?
      @upload_type.destroy
      respond_to do |format|
        format.html { redirect_to upload_types_url, notice: 'Upload type was successfully destroyed.' }
        format.json { head :no_content }
      end
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_upload_type
      @upload_type = UploadType.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def upload_type_params
      params.fetch(:upload_type, {})
    end
end
