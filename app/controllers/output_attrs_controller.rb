class OutputAttrsController < ApplicationController
  before_action :set_output_attr, only: [:show, :edit, :update, :destroy]

  # GET /output_attrs
  # GET /output_attrs.json
  def index
    @output_attrs = OutputAttr.all
  end

  # GET /output_attrs/1
  # GET /output_attrs/1.json
  def show
  end

  # GET /output_attrs/new
  def new
    @output_attr = OutputAttr.new
  end

  # GET /output_attrs/1/edit
  def edit
  end

  # POST /output_attrs
  # POST /output_attrs.json
  def create
    @output_attr = OutputAttr.new(output_attr_params)

    respond_to do |format|
      if @output_attr.save
        format.html { redirect_to @output_attr, notice: 'Output attr was successfully created.' }
        format.json { render :show, status: :created, location: @output_attr }
      else
        format.html { render :new }
        format.json { render json: @output_attr.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /output_attrs/1
  # PATCH/PUT /output_attrs/1.json
  def update
    respond_to do |format|
      if @output_attr.update(output_attr_params)
        format.html { redirect_to @output_attr, notice: 'Output attr was successfully updated.' }
        format.json { render :show, status: :ok, location: @output_attr }
      else
        format.html { render :edit }
        format.json { render json: @output_attr.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /output_attrs/1
  # DELETE /output_attrs/1.json
  def destroy
    @output_attr.destroy
    respond_to do |format|
      format.html { redirect_to output_attrs_url, notice: 'Output attr was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_output_attr
      @output_attr = OutputAttr.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def output_attr_params
      params.fetch(:output_attr, {})
    end
end
