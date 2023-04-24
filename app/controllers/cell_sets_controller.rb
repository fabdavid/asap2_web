class CellSetsController < ApplicationController
  before_action :set_cell_set, only: [:show, :edit, :update, :destroy]

  # GET /cell_sets
  # GET /cell_sets.json
  def index
    @cell_sets = CellSet.all
  end

  # GET /cell_sets/1
  # GET /cell_sets/1.json
  def show
  end

  # GET /cell_sets/new
  def new
    @cell_set = CellSet.new
  end

  # GET /cell_sets/1/edit
  def edit
  end

  # POST /cell_sets
  # POST /cell_sets.json
  def create
    @cell_set = CellSet.new(cell_set_params)

    respond_to do |format|
      if @cell_set.save
        format.html { redirect_to @cell_set, notice: 'Cell set was successfully created.' }
        format.json { render :show, status: :created, location: @cell_set }
      else
        format.html { render :new }
        format.json { render json: @cell_set.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /cell_sets/1
  # PATCH/PUT /cell_sets/1.json
  def update
    respond_to do |format|
      if @cell_set.update(cell_set_params)
        format.html { redirect_to @cell_set, notice: 'Cell set was successfully updated.' }
        format.json { render :show, status: :ok, location: @cell_set }
      else
        format.html { render :edit }
        format.json { render json: @cell_set.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /cell_sets/1
  # DELETE /cell_sets/1.json
  def destroy
    @cell_set.destroy
    respond_to do |format|
      format.html { redirect_to cell_sets_url, notice: 'Cell set was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_cell_set
      @cell_set = CellSet.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def cell_set_params
      params.fetch(:cell_set, {})
    end
end
