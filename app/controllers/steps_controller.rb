class StepsController < ApplicationController
  before_action :set_step, only: [:show, :edit, :update, :destroy]
  before_action :check_access #, :only => [:new, :create, :destroy, :update]

  # GET /steps
  # GET /steps.json
  def index
    @steps = Step.all
  end

  # GET /steps/1
  # GET /steps/1.json
  def show
  end

  # GET /steps/new
  def new
    @step = Step.new
  end

  # GET /steps/1/edit
  def edit
  end

  # POST /steps
  # POST /steps.json
  def create
    @step = Step.new(step_params)

    respond_to do |format|
      if admin? and @step.save
        format.html { redirect_to @step, notice: 'Step was successfully created.' }
        format.json { render :show, status: :created, location: @step }
      else
        format.html { render :new }
        format.json { render json: @step.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /steps/1
  # PATCH/PUT /steps/1.json
  def update
    respond_to do |format|
      if admin? and @step.update(step_params)
        format.html { redirect_to @step, notice: 'Step was successfully updated.' }
        format.json { render :show, status: :ok, location: @step }
      else
        format.html { render :edit }
        format.json { render json: @step.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /steps/1
  # DELETE /steps/1.json
  def destroy
    if admin?
      @step.project_steps.destroy_all
      @step.std_methods.destroy_all
      @step.destroy
      respond_to do |format|
        format.html { redirect_to steps_url, notice: 'Step was successfully destroyed.' }
        format.json { head :no_content }
      end
    end
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_step
    @step = Step.find(params[:id])
  end
  
  # Never trust parameters from the scary internet, only allow the white list through.
  def step_params
    params.fetch(:step).permit(:obj_name, :name, :label, :description, :warnings, :rank, 
                               :multiple_runs, :attrs_json, :method_attrs_json, :output_json, 
                               :command_json, :has_std_dashboard, :has_std_view, :has_std_form,
                               :dashboard_card_json, :show_view_json, :hidden, :group_name
                               )
  end
  
  protected
  
  def check_access
    redirect_to root_path and return unless admin?
  end

end
