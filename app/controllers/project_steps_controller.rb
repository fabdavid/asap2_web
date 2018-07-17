class ProjectStepsController < ApplicationController
  before_action :set_project_step, only: [:show, :edit, :update, :destroy]

  # GET /project_steps
  # GET /project_steps.json
  def index
    @project_steps = ProjectStep.all
  end

  # GET /project_steps/1
  # GET /project_steps/1.json
  def show
  end

  # GET /project_steps/new
  def new
    @project_step = ProjectStep.new
  end

  # GET /project_steps/1/edit
  def edit
  end

  # POST /project_steps
  # POST /project_steps.json
  def create
    @project_step = ProjectStep.new(project_step_params)

    respond_to do |format|
      if @project_step.save
        format.html { redirect_to @project_step, notice: 'Project step was successfully created.' }
        format.json { render :show, status: :created, location: @project_step }
      else
        format.html { render :new }
        format.json { render json: @project_step.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /project_steps/1
  # PATCH/PUT /project_steps/1.json
  def update
    respond_to do |format|
      if @project_step.update(project_step_params)
        format.html { redirect_to @project_step, notice: 'Project step was successfully updated.' }
        format.json { render :show, status: :ok, location: @project_step }
      else
        format.html { render :edit }
        format.json { render json: @project_step.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /project_steps/1
  # DELETE /project_steps/1.json
  def destroy
    @project_step.destroy
    respond_to do |format|
      format.html { redirect_to project_steps_url, notice: 'Project step was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_project_step
      @project_step = ProjectStep.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def project_step_params
      params.fetch(:project_step, {})
    end
end
