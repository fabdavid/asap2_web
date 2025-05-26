class OttProjectsController < ApplicationController
  before_action :set_ott_project, only: %i[ show edit update destroy ]

  # GET /ott_projects or /ott_projects.json
  def index
    @ott_projects = OttProject.all
  end

  # GET /ott_projects/1 or /ott_projects/1.json
  def show
  end

  # GET /ott_projects/new
  def new
    @ott_project = OttProject.new
  end

  # GET /ott_projects/1/edit
  def edit
  end

  # POST /ott_projects or /ott_projects.json
  def create
    @ott_project = OttProject.new(ott_project_params)

    respond_to do |format|
      if @ott_project.save
        format.html { redirect_to ott_project_url(@ott_project), notice: "Ott project was successfully created." }
        format.json { render :show, status: :created, location: @ott_project }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @ott_project.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /ott_projects/1 or /ott_projects/1.json
  def update
    respond_to do |format|
      if @ott_project.update(ott_project_params)
        format.html { redirect_to ott_project_url(@ott_project), notice: "Ott project was successfully updated." }
        format.json { render :show, status: :ok, location: @ott_project }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @ott_project.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /ott_projects/1 or /ott_projects/1.json
  def destroy
    @ott_project.destroy

    respond_to do |format|
      format.html { redirect_to ott_projects_url, notice: "Ott project was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_ott_project
      @ott_project = OttProject.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def ott_project_params
      params.fetch(:ott_project, {})
    end
end
