class FileFormatsController < ApplicationController
  before_action :set_file_format, only: [:show, :edit, :update, :destroy]

  # GET /file_formats
  # GET /file_formats.json
  def index
    @file_formats = FileFormat.all
  end

  # GET /file_formats/1
  # GET /file_formats/1.json
  def show
  end

  # GET /file_formats/new
  def new
    @file_format = FileFormat.new
  end

  # GET /file_formats/1/edit
  def edit
  end

  # POST /file_formats
  # POST /file_formats.json
  def create
    @file_format = FileFormat.new(file_format_params)

    respond_to do |format|
      if @file_format.save
        format.html { redirect_to @file_format, notice: 'File format was successfully created.' }
        format.json { render :show, status: :created, location: @file_format }
      else
        format.html { render :new }
        format.json { render json: @file_format.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /file_formats/1
  # PATCH/PUT /file_formats/1.json
  def update
    respond_to do |format|
      if @file_format.update(file_format_params)
        format.html { redirect_to @file_format, notice: 'File format was successfully updated.' }
        format.json { render :show, status: :ok, location: @file_format }
      else
        format.html { render :edit }
        format.json { render json: @file_format.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /file_formats/1
  # DELETE /file_formats/1.json
  def destroy
    @file_format.destroy
    respond_to do |format|
      format.html { redirect_to file_formats_url, notice: 'File format was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_file_format
      @file_format = FileFormat.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def file_format_params
      params.fetch(:file_format, {})
    end
end
