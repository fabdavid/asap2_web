class DockerPatchesController < ApplicationController
  before_action :set_docker_patch, only: [:show, :edit, :update, :destroy]

  # GET /docker_patches
  # GET /docker_patches.json
  def index
    @docker_patches = DockerPatch.all
  end

  # GET /docker_patches/1
  # GET /docker_patches/1.json
  def show
  end

  # GET /docker_patches/new
  def new
    @docker_patch = DockerPatch.new
  end

  # GET /docker_patches/1/edit
  def edit
  end

  # POST /docker_patches
  # POST /docker_patches.json
  def create
    @docker_patch = DockerPatch.new(docker_patch_params)

    respond_to do |format|
      if @docker_patch.save
        format.html { redirect_to @docker_patch, notice: 'Docker patch was successfully created.' }
        format.json { render :show, status: :created, location: @docker_patch }
      else
        format.html { render :new }
        format.json { render json: @docker_patch.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /docker_patches/1
  # PATCH/PUT /docker_patches/1.json
  def update
    respond_to do |format|
      if @docker_patch.update(docker_patch_params)
        format.html { redirect_to @docker_patch, notice: 'Docker patch was successfully updated.' }
        format.json { render :show, status: :ok, location: @docker_patch }
      else
        format.html { render :edit }
        format.json { render json: @docker_patch.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /docker_patches/1
  # DELETE /docker_patches/1.json
  def destroy
    @docker_patch.destroy
    respond_to do |format|
      format.html { redirect_to docker_patches_url, notice: 'Docker patch was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_docker_patch
      @docker_patch = DockerPatch.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def docker_patch_params
      params.fetch(:docker_patch, {})
    end
end
