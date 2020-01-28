class HcaoTermsController < ApplicationController
  before_action :set_hcao_term, only: [:show, :edit, :update, :destroy]

  # GET /hcao_terms
  # GET /hcao_terms.json
  def index
    @hcao_terms = HcaoTerm.all
  end

  # GET /hcao_terms/1
  # GET /hcao_terms/1.json
  def show
  end

  # GET /hcao_terms/new
  def new
    @hcao_term = HcaoTerm.new
  end

  # GET /hcao_terms/1/edit
  def edit
  end

  # POST /hcao_terms
  # POST /hcao_terms.json
  def create
    @hcao_term = HcaoTerm.new(hcao_term_params)

    respond_to do |format|
      if @hcao_term.save
        format.html { redirect_to @hcao_term, notice: 'Hcao term was successfully created.' }
        format.json { render :show, status: :created, location: @hcao_term }
      else
        format.html { render :new }
        format.json { render json: @hcao_term.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /hcao_terms/1
  # PATCH/PUT /hcao_terms/1.json
  def update
    respond_to do |format|
      if @hcao_term.update(hcao_term_params)
        format.html { redirect_to @hcao_term, notice: 'Hcao term was successfully updated.' }
        format.json { render :show, status: :ok, location: @hcao_term }
      else
        format.html { render :edit }
        format.json { render json: @hcao_term.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /hcao_terms/1
  # DELETE /hcao_terms/1.json
  def destroy
    @hcao_term.destroy
    respond_to do |format|
      format.html { redirect_to hcao_terms_url, notice: 'Hcao term was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_hcao_term
      @hcao_term = HcaoTerm.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def hcao_term_params
      params.fetch(:hcao_term, {})
    end
end
