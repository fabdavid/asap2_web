class ArchiveStatusesController < ApplicationController
  before_action :set_archive_status, only: [:show, :edit, :update, :destroy]

  # GET /archive_statuses
  # GET /archive_statuses.json
  def index
    @archive_statuses = ArchiveStatus.all
  end

  # GET /archive_statuses/1
  # GET /archive_statuses/1.json
  def show
  end

  # GET /archive_statuses/new
  def new
    @archive_status = ArchiveStatus.new
  end

  # GET /archive_statuses/1/edit
  def edit
  end

  # POST /archive_statuses
  # POST /archive_statuses.json
  def create
    @archive_status = ArchiveStatus.new(archive_status_params)

    respond_to do |format|
      if admin? and @archive_status.save
        format.html { redirect_to @archive_status, notice: 'Archive status was successfully created.' }
        format.json { render :show, status: :created, location: @archive_status }
      else
        format.html { render :new }
        format.json { render json: @archive_status.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /archive_statuses/1
  # PATCH/PUT /archive_statuses/1.json
  def update
    respond_to do |format|
      if admin? and @archive_status.update(archive_status_params)
        format.html { redirect_to @archive_status, notice: 'Archive status was successfully updated.' }
        format.json { render :show, status: :ok, location: @archive_status }
      else
        format.html { render :edit }
        format.json { render json: @archive_status.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /archive_statuses/1
  # DELETE /archive_statuses/1.json
  def destroy
    if admin?
      @archive_status.destroy
      respond_to do |format|
        format.html { redirect_to archive_statuses_url, notice: 'Archive status was successfully destroyed.' }
        format.json { head :no_content }
      end
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_archive_status
      @archive_status = ArchiveStatus.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def archive_status_params
      params.fetch(:archive_status, {})
    end
end
