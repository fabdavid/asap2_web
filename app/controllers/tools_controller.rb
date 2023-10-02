class ToolsController < ApplicationController
  before_action :set_tool, only: [:show, :edit, :update, :destroy]

  layout "welcome"
  # GET /tools
  # GET /tools.json
  def index
    @tools = Tool.all
  end

  # GET /tools/1
  # GET /tools/1.json
  def show
  end

  # GET /tools/new
  def new
    @tool = Tool.new
  end

  # GET /tools/1/edit
  def edit
  end

  # POST /tools
  # POST /tools.json
  def create
    @tool = Tool.new(tool_params)
    if admin?
      respond_to do |format|
        if @tool.save
          format.html { redirect_to @tool, notice: 'Tool was successfully created.' }
          format.json { render :show, status: :created, location: @tool }
        else
          format.html { render :new }
          format.json { render json: @tool.errors, status: :unprocessable_entity }
        end
      end
    else
      redirect_to tools_url, notice: 'Not autorized'
    end
  end

  # PATCH/PUT /tools/1
  # PATCH/PUT /tools/1.json
  def update
    if admin?
      respond_to do |format|
        if @tool.update(tool_params)
          format.html { redirect_to @tool, notice: 'Tool was successfully updated.' }
          format.json { render :show, status: :ok, location: @tool }
        else
          format.html { render :edit }
          format.json { render json: @tool.errors, status: :unprocessable_entity }
        end
      end
    else
      redirect_to tools_url, notice: 'Not autorized'
    end
  end

  # DELETE /tools/1
  # DELETE /tools/1.json
  def destroy
    if admin?
      @tool.destroy
      respond_to do |format|
        format.html { redirect_to tools_url, notice: 'Tool was successfully destroyed.' }
        format.json { head :no_content }
      end
    else
      redirect_to tools_url, notice: 'Not autorized'
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_tool
      @tool = Tool.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def tool_params
#      params.fetch(:tool, {})
       params.fetch(:tool).permit(:name, :description, :label, :step_ids, :tool_type_id, :tag, :package, :title, :url)
    end
end
