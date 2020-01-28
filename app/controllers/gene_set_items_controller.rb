class GeneSetItemsController < ApplicationController
  before_action :set_gene_set_item, only: [:show, :edit, :update, :destroy]

  # GET /gene_set_items
  # GET /gene_set_items.json
  def index
    @gene_set_items = GeneSetItem.all
  end

  # GET /gene_set_items/1
  # GET /gene_set_items/1.json
  def show
  end

  # GET /gene_set_items/new
  def new
    @gene_set_item = GeneSetItem.new
  end

  # GET /gene_set_items/1/edit
  def edit
  end

  # POST /gene_set_items
  # POST /gene_set_items.json
  def create
    @gene_set_item = GeneSetItem.new(gene_set_item_params)

    respond_to do |format|
      if @gene_set_item.save
        format.html { redirect_to @gene_set_item, notice: 'Gene set item was successfully created.' }
        format.json { render :show, status: :created, location: @gene_set_item }
      else
        format.html { render :new }
        format.json { render json: @gene_set_item.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /gene_set_items/1
  # PATCH/PUT /gene_set_items/1.json
  def update
    respond_to do |format|
      if @gene_set_item.update(gene_set_item_params)
        format.html { redirect_to @gene_set_item, notice: 'Gene set item was successfully updated.' }
        format.json { render :show, status: :ok, location: @gene_set_item }
      else
        format.html { render :edit }
        format.json { render json: @gene_set_item.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /gene_set_items/1
  # DELETE /gene_set_items/1.json
  def destroy
    @gene_set_item.destroy
    respond_to do |format|
      format.html { redirect_to gene_set_items_url, notice: 'Gene set item was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_gene_set_item
      @gene_set_item = GeneSetItem.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def gene_set_item_params
      params.fetch(:gene_set_item, {})
    end
end
