class DirectLinksController < ApplicationController
  before_action :set_direct_link, only: %i[ show edit update destroy ]

  # GET /direct_links or /direct_links.json
  def index
    @direct_links = DirectLink.all
  end

  # GET /direct_links/1 or /direct_links/1.json
  def show
  end

  # GET /direct_links/new
  def new
    @direct_link = DirectLink.new
  end

  # GET /direct_links/1/edit
  def edit
  end

#  def create_link_key
#    key = create_key3(DirectLink, 9)
#    return key    
#  end
  
  # POST /direct_links or /direct_links.json
  def create

    if params[:project_key] and @project = Project.where(:key => params[:project_key]).first

      @direct_link = DirectLink.new(direct_link_params)
      
      h_p = {}
      
      if params[:params_json]
        h_p = Basic.safe_parse_json(params[:params_json], {})
        h_p["s"]||={}
        [:csp_params, :dr_params].each do |k|
          h_p["s"][k] = session[k][@project.id]
        end
        @direct_link[:params_json] = h_p.to_json
      end    
      
      existing_direct_link = DirectLink.where(:params_json => h_p.to_json).first
      if existing_direct_link
        @direct_link = existing_direct_link
      else
        @direct_link.view_key = create_key3(DirectLink, 9, :view_key)
        @direct_link.project_id = @project.id
        @direct_link.save
      end
      
      respond_to do |format|
        if @direct_link
          format.html {
            render :partial => 'create'
          }
          format.json { render :show, status: :created, location: @direct_link }
        else
          format.html { render :new, status: :unprocessable_entity }
          format.json {
            render json: @direct_link.errors, status: :unprocessable_entity
          }
        end
      end
    else
      render :nothing => true
    end
  end

  # PATCH/PUT /direct_links/1 or /direct_links/1.json
  def update
    respond_to do |format|
      if @direct_link.update(direct_link_params)
        format.html { redirect_to direct_link_url(@direct_link), notice: "Direct link was successfully updated." }
        format.json { render :show, status: :ok, location: @direct_link }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @direct_link.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /direct_links/1 or /direct_links/1.json
  def destroy
    @direct_link.destroy

    respond_to do |format|
      format.html { redirect_to direct_links_url, notice: "Direct link was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_direct_link
      @direct_link = DirectLink.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def direct_link_params
      params.fetch(:direct_link, {})
    end
end
