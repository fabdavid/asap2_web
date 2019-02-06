class ActiveRunsController < ApplicationController
  before_action :set_active_run, only: [:show, :edit, :update, :destroy]

  # GET /active_runs
  # GET /active_runs.json
  def index
    @active_runs = ActiveRun.all
  end

  # GET /active_runs/1
  # GET /active_runs/1.json
  def show
  end

  # GET /active_runs/new
  def new
    @active_run = ActiveRun.new
  end

  # GET /active_runs/1/edit
  def edit
  end

  # POST /active_runs
  # POST /active_runs.json
  def create
    @active_run = ActiveRun.new(active_run_params)

    respond_to do |format|
      if @active_run.save
        format.html { redirect_to @active_run, notice: 'Active run was successfully created.' }
        format.json { render :show, status: :created, location: @active_run }
      else
        format.html { render :new }
        format.json { render json: @active_run.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /active_runs/1
  # PATCH/PUT /active_runs/1.json
  def update
    respond_to do |format|
      if @active_run.update(active_run_params)
        format.html { redirect_to @active_run, notice: 'Active run was successfully updated.' }
        format.json { render :show, status: :ok, location: @active_run }
      else
        format.html { render :edit }
        format.json { render json: @active_run.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /active_runs/1
  # DELETE /active_runs/1.json
  def destroy
    @active_run.destroy
    respond_to do |format|
      format.html { redirect_to active_runs_url, notice: 'Active run was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_active_run
      @active_run = ActiveRun.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def active_run_params
      params.fetch(:active_run, {})
    end
end
