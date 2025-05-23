class ProvidersController < ApplicationController
  before_action :set_provider, only: [:show, :edit, :update, :destroy]

  def get_data
    @attrs = Basic.safe_parse_json(@provider.attrs_json, {})
    @h_ref_projects = {}
    @provider_projects = @provider.provider_projects
    @provider_projects.each do |pp|
      @h_ref_projects[pp.id] = pp.projects.select{|e| e.public == true}
    end
  end


  def fca
    @provider = Provider.where(:tag => 'FCA').first
    get_data()
    render :show
  end

  def hca
    @provider = Provider.where(:tag => 'HCA').first
    get_data()
    render :show
  end


  # GET /providers
  # GET /providers.json
  def index
    @providers = Provider.all
  end

  # GET /providers/1
  # GET /providers/1.json
  def show
    get_data()
  end

  # GET /providers/new
  def new
    @provider = Provider.new
  end

  # GET /providers/1/edit
  def edit
  end

  # POST /providers
  # POST /providers.json
  def create
    @provider = Provider.new(provider_params)

    respond_to do |format|
      if admin? and @provider.save
        format.html { redirect_to @provider, notice: 'Provider was successfully created.' }
        format.json { render :show, status: :created, location: @provider }
      else
        format.html { render :new }
        format.json { render json: @provider.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /providers/1
  # PATCH/PUT /providers/1.json
  def update
    respond_to do |format|
      if admin? and @provider.update(provider_params)
        format.html { redirect_to @provider, notice: 'Provider was successfully updated.' }
        format.json { render :show, status: :ok, location: @provider }
      else
        format.html { render :edit }
        format.json { render json: @provider.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /providers/1
  # DELETE /providers/1.json
  def destroy
    if admin?
      @provider.destroy
      respond_to do |format|
        format.html { redirect_to providers_url, notice: 'Provider was successfully destroyed.' }
        format.json { head :no_content }
      end
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_provider
      @provider = Provider.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def provider_params
      params.fetch(:provider, {})
    end
end
