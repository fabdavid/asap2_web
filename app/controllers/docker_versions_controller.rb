class DockerVersionsController < ApplicationController
  before_action :set_docker_version, only: [:show, :edit, :update, :destroy]

  # GET /docker_versions
  # GET /docker_versions.json
  def index
    @docker_versions = DockerVersion.all
    @h_tool_types = {}
    ToolType.all.map{|tt| @h_tool_types[tt.id] = tt}
    @h_tools = {}
    Tool.all.map{|t| @h_tools[t.name] = t}
  end

  # GET /docker_versions/1
  # GET /docker_versions/1.json
  def show
  end

  # GET /docker_versions/new
  def new
    @docker_version = DockerVersion.new
  end

  # GET /docker_versions/1/edit
  def edit
  end

  # POST /docker_versions
  # POST /docker_versions.json
  def create
    @docker_version = DockerVersion.new(docker_version_params)

    respond_to do |format|
      if @docker_version.save
        format.html { redirect_to @docker_version, notice: 'Docker version was successfully created.' }
        format.json { render :show, status: :created, location: @docker_version }
      else
        format.html { render :new }
        format.json { render json: @docker_version.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /docker_versions/1
  # PATCH/PUT /docker_versions/1.json
  def update
    respond_to do |format|
      if @docker_version.update(docker_version_params)
        format.html { redirect_to @docker_version, notice: 'Docker version was successfully updated.' }
        format.json { render :show, status: :ok, location: @docker_version }
      else
        format.html { render :edit }
        format.json { render json: @docker_version.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /docker_versions/1
  # DELETE /docker_versions/1.json
  def destroy
    @docker_version.destroy
    respond_to do |format|
      format.html { redirect_to docker_versions_url, notice: 'Docker version was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_docker_version
      @docker_version = DockerVersion.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def docker_version_params
      params.fetch(:docker_version, {})
    end
end
