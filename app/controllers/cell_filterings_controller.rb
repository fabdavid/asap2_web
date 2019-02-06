class CellFilteringsController < ApplicationController
  before_action :set_cell_filtering, only: [:show, :edit, :update, :destroy]

  # GET /cell_filterings
  # GET /cell_filterings.json
  def index
    @cell_filterings = []
    @project = Project.where(:key => params[:project_key]).first

    @cell_filterings = CellFiltering.where(:project_id => @project.id).all
    #    get_cluster_data()                                                                                                                                                                                                   
    render :partial => 'index'
  end

  # GET /cell_filterings/1
  # GET /cell_filterings/1.json
  def show
  end

  # GET /cell_filterings/new
  def new
    @cell_filtering = CellFiltering.new
  end

  # GET /cell_filterings/1/edit
  def edit
  end

  # POST /cell_filterings
  # POST /cell_filterings.json
  def create
    @cell_filtering = CellFiltering.new(cell_filtering_params)

    respond_to do |format|
      if @cell_filtering.save
        format.html { redirect_to @cell_filtering, notice: 'Cell filtering was successfully created.' }
        format.json { render :show, status: :created, location: @cell_filtering }
      else
        format.html { render :new }
        format.json { render json: @cell_filtering.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /cell_filterings/1
  # PATCH/PUT /cell_filterings/1.json
  def update
    respond_to do |format|
      if @cell_filtering.update(cell_filtering_params)
        format.html { redirect_to @cell_filtering, notice: 'Cell filtering was successfully updated.' }
        format.json { render :show, status: :ok, location: @cell_filtering }
      else
        format.html { render :edit }
        format.json { render json: @cell_filtering.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /cell_filterings/1
  # DELETE /cell_filterings/1.json
  def destroy
    @cell_filtering.destroy
    respond_to do |format|
      format.html { redirect_to cell_filterings_url, notice: 'Cell filtering was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_cell_filtering
      @cell_filtering = CellFiltering.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def cell_filtering_params
      params.fetch(:cell_filtering, {})
    end
end
