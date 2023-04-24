class DockerImagesController < ApplicationController
  before_action :set_docker_image, only: [:show, :edit, :update, :destroy]
#  before_action :authorize_admin
  # GET /docker_images
  # GET /docker_images.json
  def index
    @docker_images = DockerImage.all
    @h_tool_types = {}
    ToolType.all.map{|tt| @h_tool_types[tt.id] = tt}
    @h_tools = {}
    Tool.all.map{|t| @h_tools[t.name] = t}

  end

  # GET /docker_images/1
  # GET /docker_images/1.json
  def show
  end

  # GET /docker_images/new
  def new
    @docker_image = DockerImage.new
  end

  # GET /docker_images/1/edit
  def edit
  end

  # POST /docker_images
  # POST /docker_images.json
  def create
    @docker_image = DockerImage.new(docker_image_params)

    
    respond_to do |format|
      if admin? and @docker_image.save
        format.html { redirect_to @docker_image, notice: 'Docker image was successfully created.' }
        format.json { render :show, status: :created, location: @docker_image }
      else
        format.html { render :new }
        format.json { render json: @docker_image.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /docker_images/1
  # PATCH/PUT /docker_images/1.json
  def update
    respond_to do |format|
      if admin? and @docker_image.update(docker_image_params)
        format.html { redirect_to @docker_image, notice: 'Docker image was successfully updated.' }
        format.json { render :show, status: :ok, location: @docker_image }
      else
        format.html { render :edit }
        format.json { render json: @docker_image.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /docker_images/1
  # DELETE /docker_images/1.json
  def destroy
    if admin?
      @docker_image.destroy
    end
    respond_to do |format|
      format.html { redirect_to docker_images_url, notice: 'Docker image was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_docker_image
      @docker_image = DockerImage.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def docker_image_params
      params.fetch(:docker_image, {})
    end
end
