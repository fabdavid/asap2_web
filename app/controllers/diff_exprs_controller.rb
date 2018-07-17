class DiffExprsController < ApplicationController
  before_action :set_diff_expr, only: [:show, :edit, :update, :destroy, :list_genes, :get_selection]
  
  def get_selection
    
    @project = @diff_expr.project
    filename = Pathname.new(APP_CONFIG[:user_data_dir]) + @project.user_id.to_s + @project.key + 'de' + @diff_expr.id.to_s  + 'selections.json'
    h_data = JSON.parse(File.read(filename))
   
    render :json => h_data["group#{params[:sel]}"]
    
  end

  def filter_results
    
    @project = Project.where(:key => params[:project_key]).first
    if analyzable? @project
      @diff_exprs= @project.diff_exprs
      @h_diff_expr_filters = JSON.parse(@project.diff_expr_filter_json)
      
      if @h_diff_expr_filters != params[:filter]
        @project.update_attribute(:diff_expr_filter_json, params[:filter].to_json)
        cmd = "rails filter_de_results[#{params[:project_key]}] --trace 2>&1 > log/filter_de_results.log"
        `#{cmd}`
        logger.debug("CMD2: " + cmd)
        @h_diff_expr_filters = params[:filter]
      end
      get_norm_results()
      render :partial => 'index'
    else
      render :nothing => true
    end
  end

  def get_norm_results
 
    @norm_results={}
    tmp_dir = Pathname.new(APP_CONFIG[:user_data_dir]) + @project.user_id.to_s + @project.key + 'normalization'
    filename = tmp_dir + "output.json"
    if File.exist?(filename)
      results_json = File.open(filename, 'r').read #lines.join("\n")                                                                                                                           
      @norm_results = JSON.parse(results_json)
    end
    
  end
  
  def list_genes
    @project = @diff_expr.project
    if readable? @project
      filename = Pathname.new(APP_CONFIG[:user_data_dir]) + @project.user_id.to_s + @project.key + 'de' + @diff_expr.id.to_s + ("output." + params[:type] + "_filtered.json")
      filename = Pathname.new(APP_CONFIG[:user_data_dir]) + @project.user_id.to_s + @project.key + 'de' + @diff_expr.id.to_s + ("output." + params[:type] + ".json") if !File.exist? filename
      @results = JSON.parse(File.read(filename))
      ['input_gene', 'ensembl_id', 'gene_name', 'alt_names'].each do |e|
        @results[e]=[]
      end
      @results['text'].each_index do |i|
        tab = @results['text'][i].split("|")
        @results['input_gene'][i]=tab[0]
        @results['ensembl_id'][i]=tab[1].split(",").join(", ") if tab.size > 1
        ####    @results['alt_names'][i]=GeneName.find
        @results['gene_name'][i]=tab[2].split(",").join(", ") if tab.size > 2        
        @results['alt_names'][i]=tab[3].split(",").join(", ") if tab.size > 3
      end
      respond_to do |format|
        format.html{ render :partial => 'list_genes'}
        format.text{ send_data render_to_string(:partial => 'list_genes'), :disposition => "attachment; filename=#{@project.key}_list_#{params[:type]}-regulated_genes_#{@diff_expr.id}.txt"}
      end
    end
  end
  
  # GET /diff_exprs
  # GET /diff_exprs.json
  def index
    @project = Project.where(:key => params[:project_key]).first
    @diff_exprs= @project.diff_exprs
    @h_diff_expr_filters = JSON.parse(@project.diff_expr_filter_json)    
    get_norm_results()
    
    render :partial => 'index'
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
    @project = Project.where(:key => params[:project_key]).first
    jobs = Job.where(:project_id => @project.id, :step_id => session[:active_step]).all.to_a.sort{|a, b| (a.updated_at.to_s || '0') <=> (b.updated_at.to_s || '0')}
    last_job = jobs.last
    session[:last_update_active_step] = @project.status_id.to_s + ","
    session[:last_update_active_step] += [jobs.size, last_job.status_id, last_job.updated_at].join(",") if last_job

    @h_diff_expr_filters = JSON.parse(@project.diff_expr_filter_json)
    @diff_expr = DiffExpr.new(diff_expr_params)    
    @diff_expr.project_id = @project.id
    tmp_attrs = params[:attrs]
    @diff_expr.attrs_json = tmp_attrs.to_json
    de_method = @diff_expr.diff_expr_method
    list_attrs = JSON.parse(de_method.attrs_json)
    other_params = list_attrs.reject{|attr| attr['obsolete'] == true or attr['widget'] == nil or !tmp_attrs[attr['name']]}.map{|attr| "#{attr['label']}=#{tmp_attrs[attr['name']]}"}.join(", ")
   # @diff_expr.step_id = nil
    #    if m = params[:cluster][:dim_reduction_id].match(/,(\d+)/)
    #      @cluster.dim_reduction_id=nil
    #      @cluster.step_id=m[1].to_i
    #    end
    
    #    if params[:cluster][:dim_reduction_id].match(/^\d+$/)
    #      dr_name = DimReduction.where(:id => @cluster.dim_reduction_id).first.label
    #    else
    #      step = Step.where(:id => @cluster.step_id).first
    #      dr_name = step.name + " data"
    #    end
    
    other_params = "(" + other_params + ")" if other_params != ''
    selections = []
    [@diff_expr.selection1_id, @diff_expr.selection2_id].compact.each do |sel_id|
      selections.push(Selection.where(:id => sel_id).first)
    end
    selections_txt = "on selection" + ((selections.size > 1) ? 's' : '') + " #{selections.map{|e| e.label + " [" + e.nb_items.to_s + "]"}.join(" - ")}"
    @diff_expr.label = [@diff_expr.diff_expr_method.label, other_params].join(" ")
    other_params_short = list_attrs.reject{|attr| attr['obsolete'] == true or attr['widget'] == nil or !tmp_attrs[attr['name']] or tmp_attrs[attr['name']] == 'null'}.map{|attr| tmp_attrs[attr['name']]}.join(",")
    @diff_expr.short_label =  [@diff_expr.diff_expr_method.label, (other_params_short != '') ? ("[" + other_params_short + "]") : nil].compact.join(" ")
    @existing_diff_expr = DiffExpr.where(:project_id => @project.id, :md5_sel1 => selections[0].md5, :md5_sel2 => (selections[1]) ? selections[1].md5 : nil, :label => @diff_expr.label).first
    all_des = DiffExpr.where(:project_id => @project.id).all.to_a
    max_num = all_des.map{|e| e.num}.max.to_i if all_des and all_des.size > 0
    @diff_expr.num = (max_num) ? (max_num + 1) : 1
    @diff_expr.md5_sel1 = selections[0].md5
    @diff_expr.md5_sel2 = (selections[1]) ? selections[1].md5 : nil
    @diff_expr.nb_cells_sel1 = selections[0].nb_items
    @diff_expr.nb_cells_sel2 = (selections[1]) ? selections[1].nb_items : nil
    @diff_expr.user_id =  (current_user) ? current_user.id : 1
    @project.update_attributes(:status_id => 1, :step_id => 6) if @project.status_id > 2 and !@existing_diff_expr

    respond_to do |format|

      if @existing_diff_expr
        @diff_expr = @existing_diff_expr
        @diff_exprs= DiffExpr.where(:project_id => @project.id).all
        #        get_diff_expr_data()
        format.html {
          render :partial => 'index'
        }
      elsif @diff_expr.save
        job = Basic.create_job(@diff_expr, 6, @project, :job_id, de_method.speed_id)
#        @diff_expr.update_attributes(:status_id => 1)#, :num => (last_cluster and last_cluster.num) ?  (last_cluster.num + 1) : 1)                                                                                               
        session[:last_step_status_id]=2
        #@diff_expr.delay(:queue => (de_method.speed) ? de_method.speed.name : 'fast').run                                                                                                    
        delayed_job = Delayed::Job.enqueue DiffExpr::NewDiffExpr.new(@diff_expr), :queue => (de_method.speed) ? de_method.speed.name : 'fast'
        job.update_attributes(:delayed_job_id => delayed_job.id) #job.id) 
#        @diff_expr.run
#        @diff_expr.delay(:queue => (de_method.speed) ? de_method.speed.name : 'default').run
        @diff_exprs=DiffExpr.where(:project_id => @project.id).all
        
        #        get_cluster_data()
        
        format.html {
          # redirect_to @cluster, notice: 'Cluster was successfully created.'                                                                                                                                                   
          render :partial => 'index'
        }
        #  format.json { render :show, status: :created, location: @cluster }                                                                                                                                                    
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
    @project = @diff_expr.project
    if analyzable_item?(@project, @diff_expr)
      job = @diff_expr.job
      @diff_expr.update_attribute(:job_id, nil)
      Basic.kill_job(logger, job)
      project_dir =  Pathname.new(APP_CONFIG[:user_data_dir]) + @project.user_id.to_s + @project.key
      diff_expr_dir = project_dir + "de" + @diff_expr.id.to_s
      FileUtils.rm_r diff_expr_dir if File.exist?(diff_expr_dir)

      @h_diff_expr_filters = JSON.parse(@project.diff_expr_filter_json)
      @diff_expr.gene_enrichments.destroy_all
      #      @diff_expr.job.destroy if @diff_expr.status_id == 1
      @diff_expr.destroy


      @diff_exprs = DiffExpr.where(:project_id => @project.id)
      project_step = ProjectStep.where(:project_id => @project.id, :step_id => 6).first
      if @project.diff_exprs.select{|c| c.status_id == 3}.size == 0
        project_step.update_attributes(:status_id => nil)
      end

      if session[:active_step].to_i == 7 and @project.gene_enrichments.size == 0
        session[:active_step] = 6
      end
      respond_to do |format|
        #      format.html { redirect_to project_url(@gene_enrichment.project.key, :active_step => 7) }                                                                                                                                               
        format.html {
          render :partial => 'index'
        }
        format.json { head :no_content }
      end
    else
      render :nothing => true
    end
  end
  
  private
  # Use callbacks to share common setup or constraints between actions.
  def set_diff_expr
    @diff_expr = DiffExpr.find(params[:id])
  end
  
  # Never trust parameters from the scary internet, only allow the white list through.
  def diff_expr_params
    #      params.fetch(:diff_expr, {})
    params.fetch(:diff_expr).permit(:project_id, :selection1_id, :selection2_id, :diff_expr_method_id, :attrs_json, :status_id, :duration, :nber_up_genes, :nber_down_genes)
    
  end
end
