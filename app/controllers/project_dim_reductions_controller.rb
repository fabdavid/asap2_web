class ProjectDimReductionsController < ApplicationController
  before_action :set_project_dim_reduction, only: [:show, :edit, :update, :destroy]

  # GET /project_dim_reductions
  # GET /project_dim_reductions.json
  def index
    @project_dim_reductions = ProjectDimReduction.all
  end

  # GET /project_dim_reductions/1
  # GET /project_dim_reductions/1.json
  def show
  end

  # GET /project_dim_reductions/new
  def new
    @project_dim_reduction = ProjectDimReduction.new
  end

  # GET /project_dim_reductions/1/edit
  def edit
  end

  # POST /project_dim_reductions
  # POST /project_dim_reductions.json
  def create
    @project_dim_reduction = ProjectDimReduction.new(project_dim_reduction_params)

    respond_to do |format|
      if @project_dim_reduction.save
        format.html { redirect_to @project_dim_reduction, notice: 'Project dim reduction was successfully created.' }
        format.json { render :show, status: :created, location: @project_dim_reduction }
      else
        format.html { render :new }
        format.json { render json: @project_dim_reduction.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /project_dim_reductions/1
  # PATCH/PUT /project_dim_reductions/1.json
  def update
    respond_to do |format|
      if @project_dim_reduction.update(project_dim_reduction_params)
        format.html { redirect_to @project_dim_reduction, notice: 'Project dim reduction was successfully updated.' }
        format.json { render :show, status: :ok, location: @project_dim_reduction }
      else
        format.html { render :edit }
        format.json { render json: @project_dim_reduction.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /project_dim_reductions/1
  # DELETE /project_dim_reductions/1.json
  def destroy
    @project_dim_reduction.destroy
    respond_to do |format|
      format.html { redirect_to project_dim_reductions_url, notice: 'Project dim reduction was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_project_dim_reduction
      @project_dim_reduction = ProjectDimReduction.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def project_dim_reduction_params
      params.fetch(:project_dim_reduction, {})
    end
end
