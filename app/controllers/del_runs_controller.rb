class DelRunsController < ApplicationController
  before_action :set_del_run, only: [:show, :edit, :update, :destroy]

  # GET /del_runs
  # GET /del_runs.json
  def index
    @del_runs = DelRun.all
  end

  # GET /del_runs/1
  # GET /del_runs/1.json
  def show
  end

  # GET /del_runs/new
  def new
    @del_run = DelRun.new
  end

  # GET /del_runs/1/edit
  def edit
  end

  # POST /del_runs
  # POST /del_runs.json
  def create
    @del_run = DelRun.new(del_run_params)

    respond_to do |format|
      if admin? and @del_run.save
        format.html { redirect_to @del_run, notice: 'Del run was successfully created.' }
        format.json { render :show, status: :created, location: @del_run }
      else
        format.html { render :new }
        format.json { render json: @del_run.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /del_runs/1
  # PATCH/PUT /del_runs/1.json
  def update
    respond_to do |format|
      if admin? and @del_run.update(del_run_params)
        format.html { redirect_to @del_run, notice: 'Del run was successfully updated.' }
        format.json { render :show, status: :ok, location: @del_run }
      else
        format.html { render :edit }
        format.json { render json: @del_run.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /del_runs/1
  # DELETE /del_runs/1.json
  def destroy
    if admin?
      @del_run.destroy
      respond_to do |format|
        format.html { redirect_to del_runs_url, notice: 'Del run was successfully destroyed.' }
        format.json { head :no_content }
      end
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_del_run
      @del_run = DelRun.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def del_run_params
      params.fetch(:del_run, {})
    end
end
