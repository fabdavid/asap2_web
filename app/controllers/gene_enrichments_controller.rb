class GeneEnrichmentsController < ApplicationController
  before_action :set_gene_enrichment, only: [:show, :edit, :update, :destroy, :get_list]
  before_action :get_project
  before_action :get_filter_params, only: [:index, :create]

  def get_list
    
    @project = @gene_enrichment.project
    if readable? @project
      filename = Pathname.new(APP_CONFIG[:user_data_dir]) + @project.user_id.to_s + @project.key + 'gene_enrichment' + @gene_enrichment.id.to_s + ("output_filtered.json")
      @results = JSON.parse(File.read(filename))
      respond_to do |format|
        format.html{ render :partial => 'get_list'}
        format.text{ send_data render_to_string(:partial => 'get_list'), :disposition => "attachment; filename=#{@project.key}_enrichment_list_#{@gene_enrichment.id}.txt"}
      end
    else
      render :nothing => true
    end
 end
    

  def get_project
    @project = Project.where(:key => params[:project_key]).first if  params[:project_key]
  end
  
  def get_filter_params
    @h_gene_enrichment_filters = JSON.parse(@project.gene_enrichment_filter_json) if @project
  end
  
  def filter_results
    
    @gene_enrichments= @project.gene_enrichments
    @h_gene_enrichment_filters = JSON.parse(@project.gene_enrichment_filter_json)
    
    if @h_gene_enrichment_filters != params[:filter]
      @project.update_attribute(:gene_enrichment_filter_json, params[:filter].to_json)
      cmd = "rails filter_ge_results[#{params[:project_key]}] --trace 2>&1 > log/filter_results.log"
      `#{cmd}`
      logger.debug("CMD2: " + cmd)
      @h_gene_enrichment_filters = params[:filter]
    end
#    get_norm_results()
    render :partial => 'index'

  end


  # GET /gene_enrichments
  # GET /gene_enrichments.json
  def index
   # @project = Project.where(:key => params[:project_key]).first
    @gene_enrichments= @project.gene_enrichments
    render :partial => 'index'
    
  end

  # GET /gene_enrichments/1
  # GET /gene_enrichments/1.json
  def show
  end

  # GET /gene_enrichments/new
  def new
    @gene_enrichment = GeneEnrichment.new
  end

  # GET /gene_enrichments/1/edit
  def edit
  end

  # POST /gene_enrichments
  # POST /gene_enrichments.json
  def create
  #  @project = Project.where(:key => params[:project_key]).first
    #    session[:last_update_active_step]= ProjectStep.where(:project_id => @project.id, :step_id => session[:active_step]).first.updated_at.to_s + " " + Job.where(:project_id => @project.id, :step_id => session[:active_step]).sort.map{|j| j.updated_at.to_s}.join(",")      
    if analyzable?(@project)
      jobs = Job.where(:project_id => @project.id, :step_id => session[:active_step]).all.to_a.sort{|a, b| (a.updated_at.to_s || '0') <=> (b.updated_at.to_s || '0')}
      last_job = jobs.last
      session[:last_update_active_step] = @project.status_id.to_s + ","
      session[:last_update_active_step] = [jobs.size, last_job.status_id, last_job.updated_at].join(",") if last_job
      
      @gene_enrichment = GeneEnrichment.new(gene_enrichment_params)
      
      @gene_enrichment.project_id = @project.id
      tmp_attrs = params[:attrs]
      to_delete = (tmp_attrs[:geneset_type] == 'global') ? :custom_geneset : :global_geneset
      tmp_attrs.delete(to_delete)

      @gene_enrichment.attrs_json = tmp_attrs.to_json
      #de_method = @gene_enrichment.diff_expr
      #list_attrs = JSON.parse(de_method.attrs_json)
      h_attr={'adj' => 'Adjusted p-value', 'p_value' =>'p-value', 'nber_best_hits' => '# of selected hits', 'type_best_hits' => 'Type of best hits', 
        'geneset_type' => 'Geneset type', 'global_geneset' => "Global geneset", "custom_geneset" => "Custom geneset" }

      other_params = tmp_attrs.keys.map{|attr| 
        tmp_val = tmp_attrs[attr] 
        if attr == 'custom_geneset' or attr == 'global_geneset'
          tmp_val = GeneSet.find(tmp_val).label
        end
        "#{h_attr[attr]}=#{tmp_val}" if tmp_val != ''}.join(", ")
      other_params = "(" + other_params + ")" if other_params != ''
      selections = []
      
      @gene_enrichment.label = ["DE #" + @gene_enrichment.diff_expr.num.to_s, other_params].join(" ")
      @existing_gene_enrichment = GeneEnrichment.where(:project_id => @project.id, :label => @gene_enrichment.label).first
      last_gene_enrichment = GeneEnrichment.where(:project_id => @project.id).last
      @gene_enrichment.num = (last_gene_enrichment and last_gene_enrichment.num) ?  (last_gene_enrichment.num + 1) : 1
      @gene_enrichment.user_id =  (current_user) ? current_user.id : 1
      @project.update_attributes(:status_id => 1, :step_id => 7) if @project.status_id > 2 and !@existing_gene_enrichment
      
      respond_to do |format|
        
        if @existing_gene_enrichment
          @gene_enrichment = @existing_gene_enrichment
          @gene_enrichments= GeneEnrichment.where(:project_id => @project.id).all
          format.html {
            render :partial => 'index'
          }
        elsif @gene_enrichment.save
          job = Basic.create_job(@gene_enrichment, 7, @project, :job_id, 1)
          #@gene_enrichment.update_attributes(:status_id => 1)#, :num => (last_cluster and last_cluster.num) ?  (last_cluster.num + 1) : 1)                                                                                            
          session[:last_step_status_id]=2
         #         @gene_enrichment.run
#          @gene_enrichment.delay(:queue => 'fast').run
          delayed_job = Delayed::Job.enqueue GeneEnrichment::NewGeneEnrichment.new(@gene_enrichment), :queue => 'fast'
          job.update_attributes(:delayed_job_id => delayed_job.id) #job.id)             
          @gene_enrichments=GeneEnrichment.where(:project_id => @project.id).all
          
          format.html {
            render :partial => 'index'
          }
        else
          
          format.html { render :new }
          format.json { render json: @gene_enrichment.errors, status: :unprocessable_entity }
        end
      end
    else
      render :nothing => true
    end
  end
  
  # PATCH/PUT /gene_enrichments/1
  # PATCH/PUT /gene_enrichments/1.json
 # def update
 #   respond_to do |format|
 #     if @gene_enrichment.update(gene_enrichment_params)
 #       format.html { redirect_to @gene_enrichment, notice: 'Gene enrichment was successfully updated.' }
 #       format.json { render :show, status: :ok, location: @gene_enrichment }
 #     else
 #       format.html { render :edit }
 #       format.json { render json: @gene_enrichment.errors, status: :unprocessable_entity }
 #     end
 #   end
 # end

  # DELETE /gene_enrichments/1
  # DELETE /gene_enrichments/1.json
    def destroy
      
      @project = @gene_enrichment.project
      if analyzable_item?(@project, @gene_enrichment)
        job = @gene_enrichment.job
        @gene_enrichment.update_attribute(:job_id, nil)
        Basic.kill_job(logger, job)
        project_dir =  Pathname.new(APP_CONFIG[:user_data_dir]) + @project.user_id.to_s + @project.key
        gene_enrichment_dir = project_dir + "gene_enrichment" + @gene_enrichment.id.to_s
        FileUtils.rm_r gene_enrichment_dir if File.exist?(gene_enrichment_dir)

        @gene_enrichment.destroy
        @gene_enrichment.job.destroy if @gene_enrichment.status_id == 1

        @gene_enrichments = GeneEnrichment.where(:project_id => @project.id)
        project_step = ProjectStep.where(:project_id => @project.id, :step_id => 7).first
        if @project.gene_enrichments.select{|c| c.status_id == 3}.size == 0
          project_step.update_attributes(:status_id => nil)
        end
        
        respond_to do |format|
          #      format.html { redirect_to project_url(@gene_enrichment.project.key, :active_step => 7) }
          format.html {
            @h_gene_enrichment_filters = JSON.parse(@project.gene_enrichment_filter_json)
            render :partial => 'index'
          }          
          format.json { head :no_content }
        end
      else
        render :nothing => true
      end
    end

#  def destroy
#    @gene_enrichment.destroy
#    respond_to do |format|
#      format.html { redirect_to gene_enrichments_url, notice: 'Gene enrichment was successfully destroyed.' }
#      format.json { head :no_content }
#    end
#  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_gene_enrichment
    @gene_enrichment = GeneEnrichment.find(params[:id])
  end
  
  # Never trust parameters from the scary internet, only allow the white list through.
  def gene_enrichment_params
    params.fetch(:gene_enrichment).permit(:project_id, :diff_expr_id, :attrs_json, :status_id, :duration)
  end
end
  
