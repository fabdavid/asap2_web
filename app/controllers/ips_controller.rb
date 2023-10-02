class IpsController < ApplicationController
  before_action :set_ip, only: [:show, :edit, :update, :destroy]

  layout 'welcome'

  # GET /ips
  # GET /ips.json
  def index
    @ips = (current_user) ? ((admin?) ? Ip.all : current_user.ips) : [] 
  end

  # GET /ips/1
  # GET /ips/1.json
  def show
  end

  # GET /ips/new
  def new
    @ip = Ip.new
  end

  # GET /ips/1/edit
  def edit
  end

  # POST /ips
  # POST /ips.json
  def create
    @ip = Ip.new(ip_params)
   
    @found_ip = Ip.where(:ip => @ip.ip).first
    
    if current_user and !@found_up
      @ip.key = create_key2(20)      
    end
    respond_to do |format|
      if !@found_ip
        if @ip.key and @ip.save
          if !@ip.users.include? current_user
            @ip.users << current_user
          end
          
          format.html { redirect_to @ip, notice: 'Ip was successfully created.' }
          format.json { render :show, status: :created, location: @ip }
        else
          format.html { render :new }
          format.json { render json: @ip.errors, status: :unprocessable_entity }
        end
      else
        if @ip.key and @ip.update_attributes({:key => @ip.key})
          if !@ip.users.include? current_user
            @ip.users << current_user
          end
          format.html { redirect_to @ip, notice: 'Ip was successfully updated.' }
          format.json { render :show, status: :created, location: @ip }
        else
          format.html { render :new }
          format.json { render json: @ip.errors, status: :unprocessable_entity }
        end
      end
    end
  end

  # PATCH/PUT /ips/1
  # PATCH/PUT /ips/1.json
  def update
    respond_to do |format|
      if current_user and @ip.update(ip_params)
        format.html { redirect_to @ip, notice: 'Ip was successfully updated.' }
        format.json { render :show, status: :ok, location: @ip }
      else
        format.html { render :edit }
        format.json { render json: @ip.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /ips/1
  # DELETE /ips/1.json
  def destroy
    if current_user and @ip
      @ip.users.delete(current_user)
    end
   
    respond_to do |format|
      format.html { redirect_to ips_url, notice: 'Ip was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_ip
      @ip = Ip.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def ip_params
      params.fetch(:ip).permit(:ip)
    end
end
