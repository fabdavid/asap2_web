class DiffExprsController < ApplicationController
  before_action :set_diff_expr, only: [:show, :edit, :update, :destroy]

  # GET /diff_exprs
  # GET /diff_exprs.json
  def index
    @diff_exprs = DiffExpr.all
  end

  # GET /diff_exprs/1
  # GET /diff_exprs/1.json
  def show
  end

  # GET /diff_exprs/new
  def new
    @diff_expr = DiffExpr.new
  end

  # GET /diff_exprs/1/edit
  def edit
  end

  # POST /diff_exprs
  # POST /diff_exprs.json
  def create
    @diff_expr = DiffExpr.new(diff_expr_params)

    respond_to do |format|
      if @diff_expr.save
        format.html { redirect_to @diff_expr, notice: 'Diff expr was successfully created.' }
        format.json { render :show, status: :created, location: @diff_expr }
      else
        format.html { render :new }
        format.json { render json: @diff_expr.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /diff_exprs/1
  # PATCH/PUT /diff_exprs/1.json
  def update
    respond_to do |format|
      if @diff_expr.update(diff_expr_params)
        format.html { redirect_to @diff_expr, notice: 'Diff expr was successfully updated.' }
        format.json { render :show, status: :ok, location: @diff_expr }
      else
        format.html { render :edit }
        format.json { render json: @diff_expr.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /diff_exprs/1
  # DELETE /diff_exprs/1.json
  def destroy
    @diff_expr.destroy
    respond_to do |format|
      format.html { redirect_to diff_exprs_url, notice: 'Diff expr was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_diff_expr
      @diff_expr = DiffExpr.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def diff_expr_params
      params.fetch(:diff_expr, {})
    end
end
