class StdRunsController < ApplicationController
  before_action :set_std_run, only: [:show, :edit, :update, :destroy]

  # GET /std_runs
  # GET /std_runs.json
  def index
    @std_runs = StdRun.all
  end

  # GET /std_runs/1
  # GET /std_runs/1.json
  def show
  end

  # GET /std_runs/new
  def new
    @std_run = StdRun.new
  end

  # GET /std_runs/1/edit
  def edit
  end

  # POST /std_runs
  # POST /std_runs.json
  def create
    @std_run = StdRun.new(std_run_params)

    respond_to do |format|
      if @std_run.save
        format.html { redirect_to @std_run, notice: 'Std run was successfully created.' }
        format.json { render :show, status: :created, location: @std_run }
      else
        format.html { render :new }
        format.json { render json: @std_run.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /std_runs/1
  # PATCH/PUT /std_runs/1.json
  def update
    respond_to do |format|
      if @std_run.update(std_run_params)
        format.html { redirect_to @std_run, notice: 'Std run was successfully updated.' }
        format.json { render :show, status: :ok, location: @std_run }
      else
        format.html { render :edit }
        format.json { render json: @std_run.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /std_runs/1
  # DELETE /std_runs/1.json
  def destroy
    @std_run.destroy
    respond_to do |format|
      format.html { redirect_to std_runs_url, notice: 'Std run was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_std_run
      @std_run = StdRun.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def std_run_params
      params.fetch(:std_run, {})
    end
end
