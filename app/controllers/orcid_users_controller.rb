class OrcidUsersController < ApplicationController
  before_action :set_orcid_user, only: [:show, :edit, :update, :destroy]

  # GET /orcid_users
  # GET /orcid_users.json
  def index
    @orcid_users = OrcidUser.all
  end

  # GET /orcid_users/1
  # GET /orcid_users/1.json
  def show
  end

  # GET /orcid_users/new
  def new
    @orcid_user = OrcidUser.new
  end

  # GET /orcid_users/1/edit
  def edit
  end

  # POST /orcid_users
  # POST /orcid_users.json
  def create
    @orcid_user = OrcidUser.new(orcid_user_params)

    respond_to do |format|
      if @orcid_user.save
        format.html { redirect_to @orcid_user, notice: 'Orcid user was successfully created.' }
        format.json { render :show, status: :created, location: @orcid_user }
      else
        format.html { render :new }
        format.json { render json: @orcid_user.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /orcid_users/1
  # PATCH/PUT /orcid_users/1.json
  def update
    respond_to do |format|
      if @orcid_user.update(orcid_user_params)
        format.html { redirect_to @orcid_user, notice: 'Orcid user was successfully updated.' }
        format.json { render :show, status: :ok, location: @orcid_user }
      else
        format.html { render :edit }
        format.json { render json: @orcid_user.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /orcid_users/1
  # DELETE /orcid_users/1.json
  def destroy
    @orcid_user.destroy
    respond_to do |format|
      format.html { redirect_to orcid_users_url, notice: 'Orcid user was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_orcid_user
      @orcid_user = OrcidUser.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def orcid_user_params
      params.fetch(:orcid_user, {})
    end
end
