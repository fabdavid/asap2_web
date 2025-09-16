class OtProjectsController < ApplicationController
  before_action :set_ot_project, only: %i[ show edit update destroy ]

  # GET /ot_projects or /ot_projects.json
  def index
    @ot_projects = OtProject.all
  end

  # GET /ot_projects/1 or /ot_projects/1.json
  def show
  end

  # GET /ot_projects/new
  def new
    @ot_project = OtProject.new
  end

  # GET /ot_projects/1/edit
  def edit
  end

  # POST /ot_projects or /ot_projects.json
  def create
    @ot_project = OtProject.new(ot_project_params)
    p = Project.where(:key => params[:project_key]).first
    @ot_project.project_id = p.id if p
    existing_ot_project = OtProject.where(:project_id => p.id, :ontology_term_type_id => @ot_project.ontology_term_type_id, :cell_ontology_term_id => @ot_project.cell_ontology_term_id).first
    respond_to do |format|
      if editable? @project and (existing_ot_project or @ot_project.save)
        @ot_projects = OtProject.where(:project_id => p.id, :ontology_term_type_id => @ot_project.ontology_term_type_id).all
        
        all_cots = CellOntologyTerm.where(:id => @ot_projects.map{|e| e.cell_ontology_term_id}.compact).all
        @h_cots = {}
        all_cots.map{|e| @h_cots[e.id] =e}

        format.html {
          if params[:partial]
            render :partial => 'index'
          else
            redirect_to ot_project_url(@ot_project), notice: "Ot project was successfully created." 
          end
        }
        format.json { render :show, status: :created, location: @ot_project }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @ot_project.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /ot_projects/1 or /ot_projects/1.json
  def update
    respond_to do |format|
      if editable? @project and @ot_project.update(ot_project_params)
        format.html { redirect_to ot_project_url(@ot_project), notice: "Ot project was successfully updated." }
        format.json { render :show, status: :ok, location: @ot_project }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @ot_project.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /ot_projects/1 or /ot_projects/1.json
  def destroy
    if editable? @project
      @ot_project.destroy
      
      @ot_projects = OtProject.where(:project_id => @project.id, :ontology_term_type_id => params[:ott_id]).all
      
      all_cots = CellOntologyTerm.where(:id => @ot_projects.map{|e| e.cell_ontology_term_id}.compact).all
      @h_cots = {}
      all_cots.map{|e| @h_cots[e.id] =e}
      
      respond_to do |format|
        format.html {
          if params[:partial]
            render :partial => 'index'
          else
            redirect_to ot_projects_url, notice: "Ot project was successfully destroyed."
          end
        }
        format.json { head :no_content }
      end
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_ot_project
      @ot_project = OtProject.find(params[:id])
      @project = @ot_project.project
    end

    # Only allow a list of trusted parameters through.
    def ot_project_params
      params.fetch(:ot_project).permit(:ontology_term_type_id, :free_text, :cell_ontology_term_id)
    end
end
