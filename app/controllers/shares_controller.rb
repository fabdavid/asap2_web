class SharesController < ApplicationController
  before_action :set_share, only: [:show, :edit, :update, :destroy]

  # GET /shares
  # GET /shares.json
  def index   
    @shares = Share.all if admin?
  end

  # GET /shares/1
  # GET /shares/1.json
  def show
  end

  # GET /shares/new
  def new
    @share = Share.new
  end

  # GET /shares/1/edit
  def edit
  end

  # POST /shares
  # POST /shares.json
  def create
    @share = Share.new(share_params)
    @project = Project.where(:key => params[:project_key]).first
    user = User.where(:email => @share.email).first
    existing_share = Share.where(:user_id => ((user) ? user.id : nil), :project_id => @project.id).first
    
    if @share.email and params[:project_key] and !existing_share
    
      @share.project_id = @project.id
      @share.user_id = user.id if user
 
      if @project and @share.save
        @shares = @project.shares.to_a
        UserMailer.invitation_mail(current_user, @share).deliver
      end
    end
    @shares = @project.shares.to_a if !@shares

    respond_to do |format|
      format.html { render :partial => 'projects/shares' }
      format.json { render :show, status: :created, location: @share }
    #else
    #      format.html {  render :partial => 'projects/shares'  }
    #      format.json { render json: @share.errors, status: :unprocessable_entity }
    #    end
    end
    
    # end
  end

  # PATCH/PUT /shares/1
  # PATCH/PUT /shares/1.json
  def update
    respond_to do |format|
      if @share.update(share_params)
        format.html { redirect_to @share, notice: 'Share was successfully updated.' }
        format.json { render :show, status: :ok, location: @share }
      else
        format.html { render :edit }
        format.json { render json: @share.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /shares/1
  # DELETE /shares/1.json
  def destroy
    @project = @share.project
    @share.destroy if admin? or @project.user_id == current_user.id
    @shares = @project.shares.to_a
    respond_to do |format|
      format.html { 
        render :partial => 'projects/shares'
        #redirect_to shares_url, notice: 'Share was successfully destroyed.' 
      }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_share
      @share = Share.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def share_params
#      params.fetch(:share, {})
        params.fetch(:share).permit(:email, :view_perm, :analyze_perm, :export_perm, :download_perm)
    end
end
