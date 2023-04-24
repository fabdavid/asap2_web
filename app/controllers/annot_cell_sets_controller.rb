class AnnotCellSetsController < ApplicationController
  before_action :set_annot_cell_set, only: [:show, :edit, :update, :destroy]

  # GET /annot_cell_sets
  # GET /annot_cell_sets.json
  def index
    @annot_cell_sets = AnnotCellSet.all
  end

  # GET /annot_cell_sets/1
  # GET /annot_cell_sets/1.json
  def show
  end

  # GET /annot_cell_sets/new
  def new
    @annot_cell_set = AnnotCellSet.new
  end

  # GET /annot_cell_sets/1/edit
  def edit
  end

  # POST /annot_cell_sets
  # POST /annot_cell_sets.json
  def create
    @annot_cell_set = AnnotCellSet.new(annot_cell_set_params)

    respond_to do |format|
      if @annot_cell_set.save
        format.html { redirect_to @annot_cell_set, notice: 'Annot cell set was successfully created.' }
        format.json { render :show, status: :created, location: @annot_cell_set }
      else
        format.html { render :new }
        format.json { render json: @annot_cell_set.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /annot_cell_sets/1
  # PATCH/PUT /annot_cell_sets/1.json
  def update
    respond_to do |format|
      if @annot_cell_set.update(annot_cell_set_params)
        format.html { redirect_to @annot_cell_set, notice: 'Annot cell set was successfully updated.' }
        format.json { render :show, status: :ok, location: @annot_cell_set }
      else
        format.html { render :edit }
        format.json { render json: @annot_cell_set.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /annot_cell_sets/1
  # DELETE /annot_cell_sets/1.json
  def destroy
    @annot_cell_set.destroy
    respond_to do |format|
      format.html { redirect_to annot_cell_sets_url, notice: 'Annot cell set was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_annot_cell_set
      @annot_cell_set = AnnotCellSet.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def annot_cell_set_params
      params.fetch(:annot_cell_set, {})
    end
end
