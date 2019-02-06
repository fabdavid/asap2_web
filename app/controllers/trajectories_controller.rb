class TrajectoriesController < ApplicationController
  before_action :set_trajectory, only: [:show, :edit, :update, :destroy]

  # GET /trajectories
  # GET /trajectories.json
  def index
    @trajectories = Trajectory.all
  end

  # GET /trajectories/1
  # GET /trajectories/1.json
  def show
  end

  # GET /trajectories/new
  def new
    @trajectory = Trajectory.new
  end

  # GET /trajectories/1/edit
  def edit
  end

  # POST /trajectories
  # POST /trajectories.json
  def create
    @trajectory = Trajectory.new(trajectory_params)

    respond_to do |format|
      if @trajectory.save
        format.html { redirect_to @trajectory, notice: 'Trajectory was successfully created.' }
        format.json { render :show, status: :created, location: @trajectory }
      else
        format.html { render :new }
        format.json { render json: @trajectory.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /trajectories/1
  # PATCH/PUT /trajectories/1.json
  def update
    respond_to do |format|
      if @trajectory.update(trajectory_params)
        format.html { redirect_to @trajectory, notice: 'Trajectory was successfully updated.' }
        format.json { render :show, status: :ok, location: @trajectory }
      else
        format.html { render :edit }
        format.json { render json: @trajectory.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /trajectories/1
  # DELETE /trajectories/1.json
  def destroy
    @trajectory.destroy
    respond_to do |format|
      format.html { redirect_to trajectories_url, notice: 'Trajectory was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_trajectory
      @trajectory = Trajectory.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def trajectory_params
      params.fetch(:trajectory, {})
    end
end
