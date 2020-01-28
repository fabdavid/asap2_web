class HcaProjectsController < ApplicationController
  before_action :set_hca_project, only: [:show, :edit, :update, :destroy]

  # GET /hca_projects
  # GET /hca_projects.json
  def index
    @hca_projects = HcaProject.all
  end

  # GET /hca_projects/1
  # GET /hca_projects/1.json
  def show
  end

  # GET /hca_projects/new
  def new
    @hca_project = HcaProject.new
  end

  # GET /hca_projects/1/edit
  def edit
  end

  # POST /hca_projects
  # POST /hca_projects.json
  def create
    @hca_project = HcaProject.new(hca_project_params)

    respond_to do |format|
      if @hca_project.save
        format.html { redirect_to @hca_project, notice: 'Hca project was successfully created.' }
        format.json { render :show, status: :created, location: @hca_project }
      else
        format.html { render :new }
        format.json { render json: @hca_project.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /hca_projects/1
  # PATCH/PUT /hca_projects/1.json
  def update
    respond_to do |format|
      if @hca_project.update(hca_project_params)
        format.html { redirect_to @hca_project, notice: 'Hca project was successfully updated.' }
        format.json { render :show, status: :ok, location: @hca_project }
      else
        format.html { render :edit }
        format.json { render json: @hca_project.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /hca_projects/1
  # DELETE /hca_projects/1.json
  def destroy
    @hca_project.destroy
    respond_to do |format|
      format.html { redirect_to hca_projects_url, notice: 'Hca project was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_hca_project
      @hca_project = HcaProject.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def hca_project_params
      params.fetch(:hca_project, {})
    end
end
