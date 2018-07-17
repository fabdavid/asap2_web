class ClustersController < ApplicationController
  before_action :set_cluster, only: [:show, :edit, :update, :destroy, :to_tab]

  def get_cluster_data
    @cluster_data={}

    if params[:project_key]

      project_dir =  Pathname.new(APP_CONFIG[:user_data_dir]) + @project.user_id.to_s + @project.key
      clustering_dir = project_dir + "clustering"
      
      @clusters = Cluster.where(:project_id => @project.id).all
      @clusters.each do |cluster|
        @cluster_data[cluster.id]=[]
        file = clustering_dir + cluster.id.to_s + "output.json"
        content_json = (File.exist?(file)) ? File.read(file) : "{}"
        h_tmp = JSON.parse(content_json)
        if h_tmp['clusters']
          h_tmp['clusters'].each_key do |cell|
            cluster_idx = h_tmp['clusters'][cell] - 1
            @cluster_data[cluster.id][cluster_idx]||=[]
            @cluster_data[cluster.id][cluster_idx].push(cell)
          end
        end
      end
    end
    
  end

  def to_tab
#    if readable? @project #and (downloadable? @project or ['png', 'pdf', 'jpeg', 'jpg'].include?(ext))    
    @project = @cluster.project
    if readable? @project
      project_dir = Pathname.new(APP_CONFIG[:user_data_dir]) + @project.user_id.to_s + @project.key
      clustering_dir = project_dir + "clustering"
      file = clustering_dir + @cluster.id.to_s + "output.json"
      content_json = (File.exist?(file)) ? File.read(file) : "{}"
      h_tmp = JSON.parse(content_json)    
      data = ["Cell\tCluster #"]
      h_tmp['clusters'].keys.sort{|a, b| h_tmp['clusters'][a] <=> h_tmp['clusters'][b]}.each do |cell|
        data.push("#{cell}\t#{h_tmp['clusters'][cell]}")
      end
      send_data data.join("\n"), type: 'text', disposition: "attachment; filename=clustering_#{@cluster.id}.tab"
    end
  end

  # GET /clusters
  # GET /clusters.json
  def index
    @clusters = []
    @project = Project.where(:key => params[:project_key]).first

    get_cluster_data()    
    render :partial => 'index'
  end

  # GET /clusters/1
  # GET /clusters/1.json
  def show
  end

  # GET /clusters/new
  def new
    @cluster = Cluster.new
  end

  # GET /clusters/1/edit
  def edit
  end

  # POST /clusters
  # POST /clusters.json
  def create

    @project = Project.where(:key => params[:project_key]).first

    if analyzable?(@project)

      jobs = Job.where(:project_id => @project.id, :step_id => session[:active_step]).all.to_a.sort{|a, b| (a.updated_at.to_s || '0') <=> (b.updated_at.to_s || '0')}
      last_job = jobs.last
      session[:last_update_active_step] = @project.status_id.to_s + ","
      session[:last_update_active_step] += [jobs.size, last_job.status_id, last_job.updated_at].join(",") if last_job
      
      @cluster = Cluster.new(cluster_params)
      @cluster.project_id = @project.id
      @cluster.user_id = (current_user) ? current_user.id : 1
      tmp_attrs = params[:attrs]
      @cluster.attrs_json = tmp_attrs.to_json
      @cluster.step_id = nil
      if m = params[:cluster][:dim_reduction_id].match(/,(\d+)/)
        @cluster.dim_reduction_id=nil
        @cluster.step_id=m[1].to_i
      end
      if params[:cluster][:dim_reduction_id].match(/^\d+$/)
        dr_name = DimReduction.where(:id => @cluster.dim_reduction_id).first.label
      else
        step = Step.where(:id => @cluster.step_id).first
        dr_name = step.name + " data"
      end
      
      cm = @cluster.cluster_method
      list_attrs = JSON.parse(cm.attrs_json)
      #    other_params = (["Input data=#{dr_name}"] + list_attrs.reject{|attr| attr['widget'] == nil}.map{|attr| "#{attr['label']}=" + ((attr['name'] == 'nbclust' and tmp_attrs['nbclust'] == '') ? 'Auto' : tmp_attrs[attr['name']].to_s)}).join(", ")
      other_params =  list_attrs.reject{|attr| attr['widget'] == nil or attr['name'] == 'nbclust'}.map{|attr| "#{attr['label']}=#{tmp_attrs[attr['name']].to_s}"}.join(", ")
      other_params = "(" + other_params + ")" if other_params != ''
      #[@diff_expr.diff_expr_method.label, other_params].join(" ")
      @cluster.label = [ClusterMethod.where(:id => @cluster.cluster_method_id).first.label, ((tmp_attrs['nbclust'] != '') ? (tmp_attrs['nbclust'].to_s + " clusters") : '[Auto]') ,  ("on " + dr_name), other_params].join(" ")
      # @cluster.label = [ClusterMethod.where(:id => @cluster.cluster_method_id).first.label, other_params].join(" ")
      @existing_cluster = Cluster.where(:project_id => @project.id, :label => @cluster.label).first
      last_cluster = Cluster.where(:project_id => @project.id).last
      @cluster.num = (last_cluster and last_cluster.num) ?  (last_cluster.num + 1) : 1
      @project.update_attributes(:status_id => 1, :step_id => 5) if @project.status_id > 2 and !@existing_cluster
      respond_to do |format|
        if @existing_cluster
          @cluster = @existing_cluster
          @clusters=[]
          get_cluster_data()
          format.html {
            render :partial => 'index'
          }
        elsif @cluster.save
          job = Basic.create_job(@cluster, 5, @project, :job_id, cm.speed_id)
   #       @cluster.update_attributes(:status_id => 1)#, :num => (last_cluster and last_cluster.num) ?  (last_cluster.num + 1) : 1)
          session[:last_step_status_id]=2
#         @cluster.delay(:queue => (cm.speed) ? cm.speed.name : 'default').run
          delayed_job = Delayed::Job.enqueue Cluster::NewClustering.new(@cluster), :queue => (cm.speed) ? cm.speed.name : 'default'
          job.update_attributes(:delayed_job_id => delayed_job.id) #job.id) 
        #            @cluster.run
          @clusters=[]
          
          get_cluster_data()
          
          format.html { 
            # redirect_to @cluster, notice: 'Cluster was successfully created.' 
            render :partial => 'index'
          }
          #  format.json { render :show, status: :created, location: @cluster }
        else
          format.html { render :new }
          format.json { render json: @cluster.errors, status: :unprocessable_entity }
        end
      end
    else
      render :nothing => true
    end
  end

  # PATCH/PUT /clusters/1
  # PATCH/PUT /clusters/1.json
  def update
    respond_to do |format|
      if @cluster.update(cluster_params)
        format.html { redirect_to @cluster, notice: 'Cluster was successfully updated.' }
        format.json { render :show, status: :ok, location: @cluster }
      else
        format.html { render :edit }
        format.json { render json: @cluster.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /clusters/1
  # DELETE /clusters/1.json
  def destroy
    @project = @cluster.project
    if analyzable_item?(@project, @cluster)
      job = @cluster.job
      @cluster.update_attribute(:job_id, nil)
      Basic.kill_job(logger, job)
      project_dir =  Pathname.new(APP_CONFIG[:user_data_dir]) + @project.user_id.to_s + @project.key
      clustering_dir = project_dir + "clustering" + @cluster.id.to_s
      FileUtils.rm_r clustering_dir if File.exist?(clustering_dir)
      
      @cluster.destroy
      @cluster.job.destroy if @cluster.status_id == 1

      project_step = ProjectStep.where(:project_id => @project.id, :step_id => 5).first
      if @project.clusters.select{|c| c.status_id == 3}.size == 0
        project_step.update_attributes(:status_id => nil)
      end

    end
    @clusters = []
    params[:project_key] = @project.key
    get_cluster_data()
    
    respond_to do |format|
      #      format.html { redirect_to project_url(@gene_enrichment.project.key, :active_step => 7) }                                                                                                                                                 
      format.html {
        render :partial => 'index'
      }
      
#    @cluster.selections.destroy_all
#    @cluster.destroy
#    respond_to do |format|
#      format.html { redirect_to project_url(@cluster.project.key, :active_step => 5) }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_cluster
      @cluster = Cluster.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def cluster_params
#project_id int references projects (id),
#cluster_method_id int references cluster_methods (id),
#cluster_attrs_json text,
#      params.fetch(:cluster, {})
      params.fetch(:cluster).permit(:project_id, :cluster_method_id, :attrs_json, :status_id, :duration, :dim_reduction_id, :step_id)
    end
end
