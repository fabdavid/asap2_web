class ProjectCellSetsController < ApplicationController
  before_action :set_project_cell_set, only: [:show, :edit, :update, :destroy]

  # GET /project_cell_sets
  # GET /project_cell_sets.json
  def index
    @project_cell_sets = ProjectCellSet.all
  end

  # GET /project_cell_sets/1
  # GET /project_cell_sets/1.json
  def show
  end

  # GET /project_cell_sets/new
  def new
    @project_cell_set = ProjectCellSet.new
  end

  # GET /project_cell_sets/1/edit
  def edit
  end

  # POST /project_cell_sets
  # POST /project_cell_sets.json
  def create
    @project_cell_set = ProjectCellSet.new(project_cell_set_params)

    respond_to do |format|
      if @project_cell_set.save
        format.html { redirect_to @project_cell_set, notice: 'Project cell set was successfully created.' }
        format.json { render :show, status: :created, location: @project_cell_set }
      else
        format.html { render :new }
        format.json { render json: @project_cell_set.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /project_cell_sets/1
  # PATCH/PUT /project_cell_sets/1.json
  def update
    respond_to do |format|
      if @project_cell_set.update(project_cell_set_params)
        format.html { redirect_to @project_cell_set, notice: 'Project cell set was successfully updated.' }
        format.json { render :show, status: :ok, location: @project_cell_set }
      else
        format.html { render :edit }
        format.json { render json: @project_cell_set.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /project_cell_sets/1
  # DELETE /project_cell_sets/1.json
  def destroy
    @project_cell_set.destroy
    respond_to do |format|
      format.html { redirect_to project_cell_sets_url, notice: 'Project cell set was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_project_cell_set
      @project_cell_set = ProjectCellSet.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def project_cell_set_params
      params.fetch(:project_cell_set, {})
    end
end
