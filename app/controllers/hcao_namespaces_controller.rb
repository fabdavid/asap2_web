class HcaoNamespacesController < ApplicationController
  before_action :set_hcao_namespace, only: [:show, :edit, :update, :destroy]

  # GET /hcao_namespaces
  # GET /hcao_namespaces.json
  def index
    @hcao_namespaces = HcaoNamespace.all
  end

  # GET /hcao_namespaces/1
  # GET /hcao_namespaces/1.json
  def show
  end

  # GET /hcao_namespaces/new
  def new
    @hcao_namespace = HcaoNamespace.new
  end

  # GET /hcao_namespaces/1/edit
  def edit
  end

  # POST /hcao_namespaces
  # POST /hcao_namespaces.json
  def create
    @hcao_namespace = HcaoNamespace.new(hcao_namespace_params)

    respond_to do |format|
      if @hcao_namespace.save
        format.html { redirect_to @hcao_namespace, notice: 'Hcao namespace was successfully created.' }
        format.json { render :show, status: :created, location: @hcao_namespace }
      else
        format.html { render :new }
        format.json { render json: @hcao_namespace.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /hcao_namespaces/1
  # PATCH/PUT /hcao_namespaces/1.json
  def update
    respond_to do |format|
      if @hcao_namespace.update(hcao_namespace_params)
        format.html { redirect_to @hcao_namespace, notice: 'Hcao namespace was successfully updated.' }
        format.json { render :show, status: :ok, location: @hcao_namespace }
      else
        format.html { render :edit }
        format.json { render json: @hcao_namespace.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /hcao_namespaces/1
  # DELETE /hcao_namespaces/1.json
  def destroy
    @hcao_namespace.destroy
    respond_to do |format|
      format.html { redirect_to hcao_namespaces_url, notice: 'Hcao namespace was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_hcao_namespace
      @hcao_namespace = HcaoNamespace.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def hcao_namespace_params
      params.fetch(:hcao_namespace, {})
    end
end
