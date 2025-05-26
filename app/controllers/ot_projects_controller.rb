class OtProjectsController < ApplicationController
  before_action :set_ot_project, only: %i[ show edit update destroy ]

  # GET /ot_projects or /ot_projects.json
  def index
    @ot_projects = OtProject.all
  end

  # GET /ot_projects/1 or /ot_projects/1.json
  def show
  end

  # GET /ot_projects/new
  def new
    @ot_project = OtProject.new
  end

  # GET /ot_projects/1/edit
  def edit
  end

  # POST /ot_projects or /ot_projects.json
  def create
    @ot_project = OtProject.new(ot_project_params)

    respond_to do |format|
      if @ot_project.save
        format.html { redirect_to ot_project_url(@ot_project), notice: "Ot project was successfully created." }
        format.json { render :show, status: :created, location: @ot_project }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @ot_project.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /ot_projects/1 or /ot_projects/1.json
  def update
    respond_to do |format|
      if @ot_project.update(ot_project_params)
        format.html { redirect_to ot_project_url(@ot_project), notice: "Ot project was successfully updated." }
        format.json { render :show, status: :ok, location: @ot_project }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @ot_project.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /ot_projects/1 or /ot_projects/1.json
  def destroy
    @ot_project.destroy

    respond_to do |format|
      format.html { redirect_to ot_projects_url, notice: "Ot project was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_ot_project
      @ot_project = OtProject.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def ot_project_params
      params.fetch(:ot_project, {})
    end
end
