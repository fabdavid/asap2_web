class ProjectsController < ApplicationController
#  before_action :authenticate_user!, except: [:index]
  before_action :set_project, only: [:show, :edit, :update, :destroy, :get_step, :get_pipeline, :get_attributes, :get_visualization, :replot, :get_file, :upload_file, :delete_batch_file, :upload_form, :clone, :direct_download]
  before_action :empty_session, only: [:show]
#  skip_before_action :verify_authenticity_token
  
  def empty_session
    session.delete(:selections)
  end

  def direct_download
    
    project_dir = Pathname.new(APP_CONFIG[:user_data_dir]) + @project.user_id.to_s + @project.key
    tmp_dir = project_dir + 'tmp'
    Dir.mkdir(tmp_dir) if !File.exist? tmp_dir
    tmp_file = tmp_dir + 'output.svg'
    File.open(tmp_file, 'w') do |f|
      f.write(params[:data_content])
    end
    cmd = "cairosvg output.svg -o output.pdf" 
    #"rsvg-convert -f pdf -o output.pdf output.svg"
    `#{cmd}`
#    send_file tmp_dir + 'output.svg', type: params[:content_type] || 'application/pdf'
    send_data params[:data_content], type: params[:content_type] || 'text', disposition: (params[:filename]) ? ("attachment; filename=" + params[:filename]) : ''
  end
  
  def get_cart
    @project = Project.where(:key => params[:project_key]).first    
    render :partial => 'cart'
  end

  def get_cells
  
    project_dir = Pathname.new(APP_CONFIG[:user_data_dir]) + @project.user_id.to_s + @project.key
    cells = File.open(project_dir + 'parsing' + 'output.tab', 'r').gets.chomp.split("\t")
    genes_header = cells.shift
    return cells
    
  end

  def upload_form
  end

  def set_viz_session
    ['geneset_type', 'custom_geneset', 'global_geneset'].each do |e|
      session[:viz_params][e] = params[e]
    end
    #    render :text => session[:viz_params].to_json
  end
  
  def clone_obj p, e, new_dir, ext #, new_dir
    e_new = e.dup
    e_new.project_id = p.id 
    e_new.save
    File.rename(new_dir + (e.id.to_s + ext), new_dir + (e_new.id.to_s + ext))    
    return e_new
  end

  def clone

    if exportable? @project #@project.sandbox == false or admin?
      new_project = @project.dup
      if current_user
        new_project.key = create_key()
        new_project.sandbox = false
      else
        if p = Project.where(:key => session[:sandbox]).first and editable? p
          delete_project(p)
        end
        new_project.key = session[:sandbox]
        new_project.sandbox = true
      end
      
      new_project.name += ' cloned'
      new_project.public = false
      new_project.user_id = (current_user) ? current_user.id : 1
      new_project.session_id = (s = Session.where(:session_id => session.id).first) ? s.id : nil
      new_project.cloned_project_id = @project.id
      new_project.parsing_job_id = nil
      new_project.filtering_job_id = nil
      new_project.normalization_job_id = nil      
      new_project.save
      
      #delete exising files if sandbox
      #new_tmp_dir = Pathname.new(APP_CONFIG[:user_data_dir]) + ((new_project.user_id == nil) ? '0' : new_project.user_id.to_s) + new_project.key
      #if !current_user
      #  FileUtils.rm_r new_tmp_dir if File.exist?(new_tmp_dir)
      #end
      
      ## copy dir                                              
      ##create user dir if doesn't exist yet
      new_tmp_dir = Pathname.new(APP_CONFIG[:user_data_dir]) + ((new_project.user_id == nil) ? '0' : new_project.user_id.to_s)
      Dir.mkdir new_tmp_dir if !File.exist? new_tmp_dir
      new_tmp_dir += new_project.key
      tmp_dir = Pathname.new(APP_CONFIG[:user_data_dir]) + @project.user_id.to_s + @project.key
      FileUtils.cp_r tmp_dir, new_tmp_dir if tmp_dir != new_tmp_dir
      
      
      ## copy object and rename files
      
      h_clusters = {}
      @project.clusters.select{|e| [3,4].include?(e.status_id)}.map{|e| 
        new_e = clone_obj(new_project, e, new_tmp_dir + 'clustering', "")
        new_e.update_attribute(:job_id, nil)
        h_clusters[e.id]=new_e.id
      }


      @project.selections.map{|e| 
        new_e = clone_obj(new_project, e, new_tmp_dir + 'selections', ".txt")
#        if e.selection_type_id == 1
          new_e.update_attribute(:obj_id, h_clusters[e.obj_id])
#        elsif e.selection_type_id == 2
#          
#        end
      }

      h_diff_exprs={}
      @project.diff_exprs.select{|e| [3,4].include?(e.status_id)}.map{|e| 
        new_e = clone_obj(new_project, e, new_tmp_dir + 'de', "")
        h_diff_exprs[e.id]=new_e.id
        new_e.update_attribute(:job_id, nil)
      }

      @project.gene_enrichments.select{|e| [3,4].include?(e.status_id)}.map{|e| 
        new_e = clone_obj(new_project, e, new_tmp_dir + 'gene_enrichment', "")
        new_e.update_attribute(:diff_expr_id, h_diff_exprs[e.diff_expr_id])
        new_e.update_attribute(:job_id, nil)
      }
      @project.project_steps.sort{|a, b| a.updated_at <=> b.updated_at}.map{|e| 
        new_e = e.dup 
        #    new_e.status_id = nil if [1, 2].include?(new_e.status_id) 
        new_project.project_steps << new_e
      }
      @project.fus.map{|e| new_e = e.dup; new_e.update_attribute(:project_key, new_project.key); new_project.fus << new_e}
 
      ## do not clone the jobs that are kept only for stat purpose
      #@project.jobs.select{|e| [3,4].include?(e.status_id)}.sort{|a, b| a.updated_at <=> b.updated_at}.map{|e| new_job = e.dup; new_job.cloned_job_id=e.id; new_project.jobs << new_job}
      
      #    psteps = new_project.project_steps.sort{|a, b| a.step_id <=> b.step_id}
      #    psteps.each_index do |i|
      #      ps = psteps[i]
      #      if [1,2].include?(ps.status_id)
      #        ps.status_id = nil
      #      end
      #    end
      h_genesets = {}
       @project.gene_sets.map{|e| 
        new_e = clone_obj(new_project, e, new_tmp_dir + 'gene_sets', ".txt")
        h_genesets[e.id]=new_e.id
        new_e.update_attribute(:ref_id, h_diff_exprs[e.ref_id])
        #  new_project.gene_sets << e.dup
      }

      @project.project_dim_reductions.map{|e|
        new_e = e.dup
        h_attrs_json = JSON.parse(new_e.attrs_json)
        h_attrs_json['custom_geneset'] = h_genesets[h_attrs_json['custom_geneset']] if h_attrs_json['custom_geneset']
        status_id = e.status_id
        status_id = nil if status_id and status_id < 3
        new_e.update_attributes({:status_id => status_id, :job_id => nil, :attrs_json => h_attrs_json.to_json})        
        new_project.project_dim_reductions << new_e
      }

      ## replace input.[extension] by a link (because cannot be changed)
      if tmp_dir != new_tmp_dir
        File.delete new_tmp_dir + ('input.' + @project.extension)
        File.symlink tmp_dir + ('input.' + @project.extension), new_tmp_dir + ('input.' + @project.extension)
      end
      
      redirect_to :action => 'show', :key => new_project.key
    else
      render :nothing => true
    end
  end

  def delete_batch_file
    tmp_dir = Pathname.new(APP_CONFIG[:user_data_dir]) + @project.user.id.to_s + params[:key]    
    File.delete(tmp_dir + "parsing" + "group.tab") if File.exist?(tmp_dir + "parsing" + "group.tab")
    File.delete(tmp_dir + "group.txt") if File.exist?(tmp_dir + "group.txt")
    render :partial => "edit"
  end
  
  def set_viz_attrs(pdr)
     if pdr and pdr.attrs_json
      h_attrs = JSON.parse(pdr.attrs_json)
      @attrs.each_index do |i|
        logger.debug("DEFAULT" + @attrs[i]['name'].to_json + "->" + h_attrs[@attrs[i]['name']].to_json)
        @attrs[i]['default']=h_attrs[@attrs[i]['name']]
      end
    end    
  end

  def get_data_for_viz(dr_id)
    @h_dim_reductions={}
    DimReduction.all.map{|s| @h_dim_reductions[s.id]=s}
    @form_inline = 1 ### to display attributes on one line                                                                                                                     
    @attrs = JSON.parse(@h_dim_reductions[dr_id].attrs_json)
    @dim_reduction = DimReduction.where(:id => dr_id).first
    pdr = ProjectDimReduction.where(:project_id => @project.id, :dim_reduction_id => dr_id).first
    if !pdr
      project_dir =  Pathname.new(APP_CONFIG[:user_data_dir]) + @project.user_id.to_s + @project.key
      output_dir = project_dir + 'visualization'
      visualization_dir = output_dir + @dim_reduction.name
      Dir.mkdir(visualization_dir) if !File.exist?(visualization_dir)
      pdr = ProjectDimReduction.new(:project_id => @project.id, :dim_reduction_id => dr_id, :user_id => (current_user) ? current_user.id : 1)
      pdr.save
    end
    @active_item_name = (session[:active_dr_id]) ? @h_dim_reductions[session[:active_dr_id]].label.downcase : 'PCA'
    return pdr
  end

  def rerun_dim_reduction(pdr)
    h_attrs = params[:attrs]
#    heatmap_key_to_delete = nil
#    if h_attrs[:geneset_type] == 'global'
#      heatmap_key_to_delete = 'custom_geneset'
#    elsif h_attrs[:geneset_type] == 'custom'
#      heatmap_key_to_delete = 'global_geneset'
#    end
#    h_attrs.delete(heatmap_key_to_delete) if heatmap_key_to_delete
    pdr.update_attributes(:status_id => 1, :attrs_json => (h_attrs) ? h_attrs.to_json : {})
    logger.debug("RUN!!" + pdr.id.to_s + " " + params[:attrs].to_json)
    dr = pdr.dim_reduction

    job = Basic.create_job(pdr, 4, @project, :job_id, dr.speed_id)
    ###########  pdr.delay(:queue => (dr.speed) ? dr.speed.name : 'fast').run
    delayed_job = Delayed::Job.enqueue ProjectDimReduction::NewVisualization.new(pdr, params[:attrs][:sub_step]), :queue => (dr.speed) ? dr.speed.name : 'fast'
    job.update_attributes(:delayed_job_id => delayed_job.id) #job.id)    
   # pdr.run params[:attrs][:sub_step]
  end

  def get_last_update_status
    jobs = Job.where(:project_id => @project.id, :step_id => session[:active_step], :status_id => [1, 2, 3, 4]).all.to_a
    jobs.sort!{|a, b| (a.updated_at.to_s || '0') <=> (b.updated_at.to_s || '0')} if jobs.size > 0
    last_job = jobs.last
    last_update = @project.status_id.to_s + ","
    last_update += [jobs.size, last_job.status_id, last_job.id, last_job.updated_at].join(",") if last_job
    return last_update
  end

  def get_pipeline
    @redirect_to_main_page=nil
  
    if @project
      @h_statuses={}
      Status.all.map{|s| @h_statuses[s.id]=s}

      @last_update = get_last_update_status()

      #      @active_step_pending_jobs = Job.where(:project_id => @project.id, :step_id => session[:active_step], :status_id => 1).all

#      h_obj = {
#        5 => Cluster,
#        6 => DiffExpr,
#        7 => GeneEnrichment
#      }
#      obj = h_obj[session[:active_step]]

      counts = [0, 0, 0]
      @positions = [{}, {}, {}]
      all_pending = Job.where(:status_id => 1).order("id").all
      (0 .. all_pending.size-1).to_a.each do |i|
        job = all_pending[i]
        counts[job.speed_id-1]+=1
        if job.project_id == @project.id 
          @positions[job.speed_id-1][job.id]= counts[job.speed_id-1]
        end
      end

      if session[:last_update_active_step].to_s != @last_update.to_s or session[:to_update] == 1  #!=@project.project_steps.to_json or session[:last_step_status_id] != @project.status_id or session[:last_step_id] != @project.step_id
        session[:to_update]=1
        #  @reload_step_container = 1 
        #      session[:last_step_status_id] = @project.status_id
        #      session[:last_step_id] = @project.step_id
        #      session[:project_steps]=@project.project_steps.to_json
        #        session[:reload_step] = 1
        session[:last_update_active_step] = @last_update
      end
      
#      if session[:to_update]==1
#        @reload_step_container = 1
#      end
    else
      @redirect_to_main_page = 1
    end
    render :partial => 'pipeline_upd2'
    
  end
  
  def get_viz_data(tmp_dir)
    @data_json = File.read(tmp_dir + 'output.json')
    @h_ori_data = JSON.parse(@data_json)
    @h_data={'text' => @h_ori_data['text']}
    session[:viz_params]['dim3']='1' if !@h_ori_data["PC" + (params[:dim3] || session[:viz_params]['dim3'].to_s)]
    @h_data['x']=@h_ori_data["PC" + (params[:dim1] || session[:viz_params]['dim1'].to_s)]
    @h_data['y']=@h_ori_data["PC" + (params[:dim2] || session[:viz_params]['dim2'].to_s)]
    @h_data['z']=@h_ori_data["PC" + (params[:dim3] || session[:viz_params]['dim3'].to_s)] #if params[:plot_type]=='3d'
 
  end

  #  def get_visualization
  #  
  #    pdr = get_data_for_viz(params[:active_item].to_i)
  #    set_viz_attrs(pdr)
  #    session[:active_dr_id] = params[:active_item].to_i if params[:active_item]
  #    tmp_dir = Pathname.new(APP_CONFIG[:user_data_dir]) + @project.user_id.to_s + @project.key + 'visualization' +  pdr.dim_reduction.name 
  #    if pdr and File.exist?(tmp_dir + 'output.json')
  #      get_viz_data(tmp_dir)
  #    else
  #      @button = "<button id='reset_visualization_" + params[:active_item] + "' class='replot btn btn-primary' style=''>Plot</button>"
  #    end
  #    @traces = (@h_data) ? {'2d' => [{'x' => @h_data['x'], 'y' => @h_data['y'], 'text' => @h_data['text']}], '3d' => [@h_data]} : {'2d' => [], '3d' => []}
  #    render :partial => 'visualization_layout'
  #  end
  
  def create_traces(h_results, trace_names)
  
    traces = []
    @h_data['text'].each_index do |i|
     
      text =  @h_data['text'][i]
      if h_results[text]
        x = @h_data['x'][i]
        y = @h_data['y'][i]
        z = @h_data['z'][i]
        cluster_id = h_results[text] -1 
        
        traces[cluster_id]||={'x' => [], 'y' => [], 'z' => [], 'text' => []}
        traces[cluster_id]['x'].push(x)
        traces[cluster_id]['y'].push(y)
        traces[cluster_id]['z'].push(z)
        traces[cluster_id]['text'].push(text)
        traces[cluster_id]['name'] = trace_names[cluster_id] if trace_names
      end
    end
    return traces
  end

  def replot

    @h_batches={}
    @heatmap_json =nil
    @corr_plot_json=nil
    @trajectory_plot_json=nil
    @heatmap_branches_json=[]
    @gene_expression_branches_json=[]

    get_batch_file_groups()
    @list_batches = @h_batches.keys.sort
    @list_val = nil
    @message = ''
    
    params.delete(:full_screen) if params[:full_screen] == ''
    
    @pdr = get_data_for_viz(params[:dr_id].to_i)

    if @pdr
      
      session[:active_dr_id] = (params[:active_item]) ? params[:active_item].to_i : params[:dr_id].to_i
      project_dir = Pathname.new(APP_CONFIG[:user_data_dir]) + @project.user_id.to_s + @project.key
      tmp_dir = project_dir + 'visualization' +  @pdr.dim_reduction.name
      logger.debug("RERUN! #{params[:attrs].to_json} #{@pdr.attrs_json}")
 
#      params[:attrs][:dataset] = params[:dataset] if params[:dataset]

      if params[:attrs] 
    
        ### clean params       
        
        heatmap_key_to_delete = nil
        if params[:attrs][:geneset_type] == 'global'
          heatmap_key_to_delete = 'custom_geneset'
        elsif params[:attrs][:geneset_type] == 'custom'
          heatmap_key_to_delete = 'global_geneset'
        end
        params[:attrs].delete(heatmap_key_to_delete) if heatmap_key_to_delete
        
        ### determine if the current view is done with the same parameters, if not, restart it                                                                               
        #h_tmp_attrs = JSON.parse(@pdr.attrs_json)
        
        #logger.debug("blabla: " + " : " + @pdr.to_json)
  #      if params[:attrs].to_json != @pdr.attrs_json and !params[:active_item]
        # if    (!params[:attrs][:dim1] and (!@pdr.status_id or [4,5].include?(@pdr.status_id))) or (params[:attrs].to_json != @pdr.attrs_json and !params[:active_item])
        if (!params[:attrs][:dim1] and (!@pdr.status_id or [4,5].include?(@pdr.status_id)) and @pdr.dim_reduction_id < 5) or (params[:attrs].to_json != @pdr.attrs_json and !params[:active_item]) #or params[:dataset] != h_tmp_attrs['dataset']
          
          #logger.debug("blabla 2: " + params[:attrs][:dim1] + " : " + @pdr.to_json)
          if analyzable?(@project) and (@pdr.dim_reduction_id < 5 or owner?(@project))
            #  logger.debug("blabla 3")
            logger.debug("RERUN2! #{params[:attrs].to_json} #{@pdr.attrs_json}")
            File.delete tmp_dir + 'output.json' if File.exist? tmp_dir + 'output.json'
            rerun_dim_reduction(@pdr)
          end
        end
        
      end
      
      if @pdr.dim_reduction_id < 5
        standard_plot(@pdr, project_dir)
      elsif @pdr.dim_reduction_id == 5
        heatmap_plot(@pdr, project_dir)
      elsif @pdr.dim_reduction_id == 6
        correlation_plot(@pdr, project_dir)  
      elsif @pdr.dim_reduction_id == 7
        trajectory_plot(@pdr, project_dir)
      end
    end
    
    if params[:full_screen] 
      render :partial => 'full_screen_visualization_layout'
    else
      render :partial => 'visualization_layout'
    end
  end

  def trajectory_plot(pdr, project_dir)
    tmp_dir = project_dir + 'visualization' +  pdr.dim_reduction.name
    @pdr_params = (pdr.attrs_json) ? JSON.parse(pdr.attrs_json) : {}
    @cells = get_cells().map{|e| [e, e]}
    ['geneset_type', 'custom_geneset', 'global_geneset'].each do |e|
      session[:viz_params][e] = @pdr_params[e]
    end
    @trajectory_exists = File.exist?(tmp_dir + 'monocle_trajectory.json')
    #  if @trajectory_plot_exists
    #    @trajectory_plot_json = File.read(tmp_dir + 'monocle_trajectory.json')
    #  end
    # Dir.glob(tmp_dir + 'monocle_heatmap_branch_*.json').sort.each { |filename|
    #   @heatmap_branches_json.push(File.read(filename).html_safe)
    # }
    # Dir.glob(tmp_dir + 'monocle_geneexpression_branch_*.json').sort.each { |filename|
    #   @gene_expression_branches_json.push(File.read(filename).html_safe)
    # }
    #@button = "<button id='reset_visualization_" + params[:dr_id] + "' class='replot btn btn-primary' style=''>Plot</button>"
  end

  def correlation_plot(pdr, project_dir)
    
    tmp_dir = project_dir + 'visualization' +  pdr.dim_reduction.name

    @pdr_params = JSON.parse(pdr.attrs_json) #: {}
    @cells = get_cells().map{|e| [e, e]}
    @h_ori_data = {}
    if File.exist?(tmp_dir + 'output.json')
      @corr_plot_json = File.read(tmp_dir + 'output.json')
      @corr_plot_json = nil if @heatmap_json == ''
    end
#    @button = "<button id='reset_visualization_" + params[:dr_id] + "' class='replot btn btn-primary' style=''>Plot</button>"
    
  end

  def heatmap_plot(pdr, project_dir)

    tmp_dir = project_dir + 'visualization' +  pdr.dim_reduction.name

    @pdr_params =  JSON.parse(pdr.attrs_json)

    ['geneset_type', 'custom_geneset', 'global_geneset'].each do |e|
      session[:viz_params][e] = @pdr_params[e]
    end

    @geneset_names=[]

    ### get data                  
    if File.exist?(tmp_dir + 'output.json')
      @data_json = File.read(tmp_dir + 'output.json')
      @h_ori_data = JSON.parse(@data_json)
    end

    if File.exist?(tmp_dir + 'output.heatmap.json')                                           
      @heatmap_json = File.read(tmp_dir + 'output.heatmap.json')
      @heatmap_json = nil if @heatmap_json == ''
    end    
     @button = "<button id='reset_visualization_" + params[:dr_id] + "' class='replot btn btn-primary' style=''>Plot</button>" if owner? @project
  end

  def standard_plot(pdr, project_dir)

    tmp_dir = project_dir + 'visualization' +  pdr.dim_reduction.name
    
    traces = nil

    ### write parameters in session
    ['dim1', 'dim2', 'dim3', 'color_by', 'gene_text', 'dataset', 'cluster_id', 'selection_id'].each do |e|
      session[:viz_params][e]=params[e.intern] if params[e.intern]
    end
        
    ### get data
    if File.exist?(tmp_dir + 'output.json')
      get_viz_data(tmp_dir)
    else
      @button = "<button id='reset_visualization_" + params[:dr_id] + "' class='replot btn btn-primary' style=''>Plot</button>"
    end
    
    ### get gene expression data for a given gene
    if params[:color_by] == 'gene_text' and params[:gene_text] and params[:gene_text] != ''
      ensembl_ids = params[:gene_text].split(" ").first
      h_ensembl_ids = {}
      ensembl_ids.split(",").map{|e| h_ensembl_ids[e] = 1}
      #gene = Gene.where(:ensembl_id => params[:gene_text].split(" ").first).first
      list_genes = JSON.parse(File.read(project_dir + 'parsing' + 'gene_names.json')) 
      i = 0
      catch (:done) do
        list_genes.each do |e|
          e[1].split(",").each do |ensembl_id|
            throw :done if h_ensembl_ids[ensembl_id]
          end
          e[0].split(",").each do |input_gene_name|
            throw :done if h_ensembl_ids[input_gene_name]
          end
          i+=1
        end
      end
      h_header = {}
      @i = i
      logger.debug("GET_COLOR: #{@i} " + (project_dir + params[:dataset] + 'output.tab').to_s)
      File.open(project_dir + params[:dataset] + 'output.tab', 'r') do |f|
        header = f.gets
        header.chomp!
        t_h = header.split("\t")
        t_h.shift
        while(l = f.gets) do
          l.chomp!
          t = l.split("\t").map{|e| e.to_f}
          k = t.shift
          if k.to_i == i
            h_data = {}
            t.each_index{|i| h_data[t_h[i]]=t[i]}
            @list_val = []
            @h_data['text'].each do |k2|
              @list_val.push(h_data[k2])
            end
            break
          end
        end
      end
      
      traces = [@h_data]
      @message = 'Data not found for this gene (filtered out). You can plot the Original Data instead.' if !@list_val
    elsif params[:color_by] == 'batch_group_list'
      h_batches = {}
      trace_names = []
      @list_batches.each_index do |i|
        k = @list_batches[i]
        trace_names[i]="Group #{k}"
        @h_batches[k].each do |e|
          h_batches[e]=i+1
        end
      end
      traces = create_traces(h_batches, trace_names)
      
    elsif  params[:color_by] == 'clustering_list'
      
      filename = project_dir + 'clustering' + params[:cluster_id] + "output.json"
      h_results = JSON.parse(File.read(filename)) if File.exist?(filename)
      trace_names = (1 .. h_results['clusters'].keys.size).to_a.map{|e| "Cluster #{e}"}
      # @trace_names= trace_names
      traces = create_traces(h_results['clusters'], trace_names)
      
    elsif  params[:color_by] == 'selection_list'
      
      filename = project_dir + 'selections' + "#{params[:selection_id]}.txt"
      #      h_results = JSON.parse(File.read(filename)) if File.exist?(filename)      
      list_cells = File.read(filename).split("\n")
      h_cells = {}      
      list_cells.map{|e| h_cells[e]=1}
      traces = create_traces(h_cells, nil)
      #    compl_data = {'x' => [], 'y' => [], 'z' => [], 'text' => [], 'marker' => {'color' => (1 .. list_cells.size).to_a.map{|i| 1}}}
      
      traces[0]['marker']={'color'=>(1 .. traces[0]['x'].size ).map{|i| 1}}
      
      @h_data['x'].each_index do |i|
        if ! h_cells[@h_data['text'][i]]
          ['x', 'y', 'z', 'text'].each do |k|
            traces[0][k].push(@h_data[k][i])
          end
          traces[0]['marker']['color'].push(0)
        end
      end
      #      traces.push(compl_data)
      #      if traces[0]
      #        traces[0]['marker']={'color'=>(1 .. traces[0]['x'].size ).map{|i| 0}}
      #      end
    else
      traces = [@h_data]
    end
    
    ##create traces_2d
    traces_2d = []
    traces.each_index do |i|
      if traces[i]
        traces_2d[i]= {'x' => traces[i]['x'], 'y' => traces[i]['y'], 'text' => traces[i]['text']}
      end
    end
    
    
    @traces = {'2d' => traces, '3d' => traces}
    
    @nber_points = 0
    traces.each do |trace|
      @nber_points += trace['x'].size if trace and  trace['x']
    end
    
    set_viz_attrs(pdr)
    

  end
  
  def get_results
    
    t = [:parsing, :filtering, :normalization]
    (1 .. session[:active_step].to_i).each do |i|
      step_name = t[i-1]
      tmp_dir = Pathname.new(APP_CONFIG[:user_data_dir]) + @project.user_id.to_s + @project.key + step_name.to_s              
      filename = tmp_dir + "output.json"       
      if @project.step_id >= i and File.exist?(filename)
        results_json = File.open(filename, 'r').read #lines.join("\n")                                                                                       
        begin
          @all_results[step_name] = JSON.parse(results_json)
        rescue Exception => e
        end
      end
    end
    @results = @all_results[t[session[:active_step]-1]]
  
  end
  
  def get_batch_file_groups
    batch_file = Pathname.new(APP_CONFIG[:user_data_dir]) + @project.user_id.to_s + @project.key + 'parsing' + 'group.tab'
    if File.exist?(batch_file)
      File.open(batch_file, "r") do |f|
        header = f.gets
        while(l = f.gets)
          t = l.chomp.split("\t")
          if t.size == 2
            @h_batches[t[1]]||=[] 
            @h_batches[t[1]].push(t[0])
          end
        end
      end
    end
  end

  def get_step

    ### redefine the current project (if other windows will change them to this project)
    session[:current_project]=@project.key
    
    @h_steps={}
    Step.all.map{|s| @h_steps[s.id]=s}

    @h_pdr={}
    ProjectDimReduction.where(:project_id => @project.id).all.map{|pdr| @h_pdr[pdr.dim_reduction_id]=pdr}
  
    @results = {}
    @all_results = {}
    @results_parsing={}
    @h_batches={}
    session[:active_step] = params[:active_step].to_i if params[:active_step]
    #jobs = Job.where(:project_id => @project.id, :step_id => session[:active_step], :status_id => [1, 2, 3, 4]).all.to_a.compact
    #jobs.sort!{|a, b| (a.updated_at.to_s || '0') <=> (b.updated_at.to_s || '0')} if jobs.size > 0
    #last_job = jobs.last
    #@last_update = @project.status_id.to_s + ","
    #@last_update += [jobs.size, last_job.status_id, last_job.updated_at].join(",") if last_job
    @last_update = get_last_update_status()
   # session[:last_update_active_step]= @last_update
    session[:active_dr_id] ||= 1
    session[:active_viz_type] ||= 'dr'
    if readable? @project #(current_user and current_user.id == @project.user_id) or admin? or @project.public == true or @project.sandbox == true
  #    tmp_dir = Pathname.new(APP_CONFIG[:user_data_dir]) + @project.user_id.to_s + @project.key + @h_steps[session[:active_step]].label.downcase
  #    filename = tmp_dir + "output.json"
  #    logger.debug("FILE: " + filename.to_s)
      
      get_results()
      get_batch_file_groups()      
      #      if  session[:active_step] > 1
      #        tmp_dir = Pathname.new(APP_CONFIG[:user_data_dir]) + @project.user_id.to_s + @project.key + "parsing"
      #        filename = tmp_dir + "output.json"
      #        results_json = File.open(filename, 'r').read
      #        @results_parsing = JSON.parse(results_json)
      #      end
      
    end
    
    respond_to do |format|
      format.html { 
        session[:to_update] = 0
        render :partial => "get_step"
        session[:to_update] = 0
#        active_step_name = @h_steps[session[:active_step]].name
#        if @project.step_id < session[:active_step] and !(@project.step_id ==3 and @project.status_id == 3) and session[:active_step] < 5
#          render :partial => "form_" + active_step_name
#          session[:to_update] = 0
#        else
#          render :partial => active_step_name
#          session[:to_update] = 0
#        end
        #   format.json { render json: @project }
      }
    end
  end
  
  def get_attributes
 
    h_obj = {
      'filter_method' => FilterMethod,
      'norm' => Norm,
      'cluster_method' => ClusterMethod,
      'diff_expr_method' => DiffExprMethod
    }

    h_step = {
      'filter_method' => 2,
      'norm' => 3,
      'cluster_method' => 5,
      'diff_expr_method' => 6

    }

    tmp_dir = Pathname.new(APP_CONFIG[:user_data_dir]) + @project.user_id.to_s + @project.key
    
    @attrs = []

    step = Step.where(:id => h_step[params[:obj_name]]).first
    @ps = ProjectStep.where(:project_id => @project.id, :step_id => step.id).first

    @div_class=nil
    if ['diff_expr_method', 'cluster_method'].include? params[:obj_name]
      @div_class='attr_table'
    elsif ['filter_method', 'norm'].include? params[:obj_name]
      @div_class='form-inline'
    end

    @obj_inst = nil
    if obj = h_obj[params[:obj_name]]
      @obj_inst = obj.find(params[:obj_id])
    end
    
    @attrs = JSON.parse(@obj_inst.attrs_json)
    #   end
    
    @h_attrs = {}
    if params[:obj_name] == 'filter_method'
      @h_attrs = JSON.parse(@project.filter_method_attrs_json || "{}")
    elsif params[:obj_name] == 'norm'
      @h_attrs = JSON.parse(@project.norm_attrs_json || "{}")
    elsif params[:obj_name] == 'cluster_method'
      @h_attrs = JSON.parse((c = Cluster.where(:project_id => @project.id, :cluster_method_id => @obj_inst.id).order("id desc").first && c && c.attrs_json) || "{}")
    elsif params[:obj_name] == 'diff_expr_method'
      @h_attrs = JSON.parse((de = DiffExpr.where(:project_id => @project.id, :diff_expr_method_id => @obj_inst.id).order("id desc").first && de && de.attrs_json) || "{}")
    end

    @warning = @obj_inst.warning if @obj_inst.respond_to?(:warning)
    
    @batch_file_exists = 1 if File.exist?(tmp_dir + "parsing" + "group.tab") 
    @ercc_file_exists = 1 if File.exist?(tmp_dir + "parsing" + "ercc.tab")

    render :partial => 'attributes', locals: {h_attrs: @h_attrs} 
    
  end

  def get_file_old
 
    tmp_dir = Pathname.new(APP_CONFIG[:user_data_dir]) + @project.user.id.to_s + params[:key]
    
    ### get gene_file
    if File.exists?(tmp_dir + "parsing" + 'gene_names.json')
      list_gene_names = JSON.parse(File.read(tmp_dir + "parsing" + 'gene_names.json'))
    end
    ### get file    
    filename = params[:filename] || "output.tab"
    data = ""
    tmp_data = []
    if filename == "output.tab"
      File.open(tmp_dir + params[:step] + filename, 'r') do |f|
        if list_gene_names
          tmp_data.push(f.gets) ## get header 
          i = 0
          while l = f.gets do
            t = l.split("\t")
            j = t.shift        
            e = [[0,1,2].map{|j| list_gene_names[i][j]}.select{|e| e and e!=''}.join("|")]
            tmp_data.push((e + t).join("\t")) 
            i+=1
          end
          data = tmp_data.join("")
        else
          data = f.readlines.join("")
        end
      end  
    else
      data = File.read(tmp_dir + params[:step] + filename)
    end
    send_data data, type: params[:content_type] || 'text', disposition: (!params[:display]) ? ("attachment; filename=" + params[:step] + "_" + filename) : ''
  end
  
  def get_file
    filename = params[:filename] || 'dl_output.tab'
    ext =  filename.split(".").last
    obj = c.constantize if params[:step] and c= params[:step].classify and ['GeneSet'].include?(c)
    item_id = (params[:item_id]) ? params[:item_id] : ((params[:filename] and m = params[:filename].match(/^(\d+)\.\w{1,3}/)) ? m[1].to_i : nil) 
    if readable?(@project) and (exportable? @project or ['png', 'pdf', 'jpeg', 'jpg'].include?(ext)) or (params[:step] == 'visualization' and filename.match(/trajectory/) and ext == 'json') or (params[:step] and obj.present? and item = obj.where(:id => item_id).first and exportable_item?(@project, item))
      tmp_dir = Pathname.new(APP_CONFIG[:user_data_dir]) + @project.user.id.to_s + params[:key] + params[:step]
      tmp_dir += params[:item_id].to_s if params[:item_id]
      filepath = tmp_dir + filename
      send_file filepath.to_s, type: params[:content_type] || 'text', # type: 'application/octet-stream'
      x_sendfile: true, buffer_size: 512, disposition: (!params[:display]) ? ("attachment; filename=" + params[:step] + "_" + filename) : ''
    else
      render :text => 'Not authorized to download this file'
    end
    
  end
  
  def upload_file
    
    if params[:key] #and current_user
      user = current_user || User.find(1)
      user = @project.user if @project

      tmp_dir = Pathname.new(APP_CONFIG[:user_data_dir]) + user.id.to_s
      Dir.mkdir(tmp_dir) if !File.exist?(tmp_dir)
      tmp_dir += (@project) ? @project.key : params[:key]
      Dir.mkdir(tmp_dir) if !File.exist?(tmp_dir)
      
      filename = tmp_dir + (params[:type] + ".txt")     
      #Multipart.
      File.open(filename, 'w') do |f|         
        f.write(params[(params[:type] + "_file").intern].read.force_encoding(Encoding::ISO_8859_1).encode(Encoding::UTF_8))
      end
      `dos2unix #{filename}`
      `mac2unix #{filename}`    
    end    
    #    render :text => params[(params[:type] + "_file").intern].original_filename
    render :text => '{}'
    # render :text => params.to_json
  end

  def get_projects
    
    [:limit, :public_limit, :free_text, :public_free_text].each do |e|
      session[:settings][e] = params[e] if params[e] 
    end
    settings = session[:settings]

  #  settings[:limit]=10
  #  settings[:public_limit]=10
    public_base_search = (settings[:public_free_text] and !settings[:public_free_text].empty?) ? Project.where("lower(name) ~ ?", settings[:public_free_text].downcase) : Project

    h = {:public => true}
    h[:user_id] = 1 if !current_user
    @h_counts={:public => 0, :private => 0}
    @h_counts[:public] =  public_base_search.where(h).count
    @public_projects = public_base_search.where(h).order("updated_at desc").limit(settings[:public_limit]).all.to_a
    
    base_search = (settings[:free_text] and !settings[:free_text].empty?) ? Project.joins("join users on (users.id = user_id)").where("lower(name) ~ ? or key ~ ? or users.email ~ ?", settings[:free_text].downcase, settings[:free_text].downcase, settings[:free_text].downcase) : Project

    shared_project_ids = []
    if current_user and !admin?
      shares = Share.where(:user_id => current_user.id).all
      shared_project_ids =  Share.where(:user_id => current_user.id).map{|e| e.project_id} if shares.size > 0
    end

    tmp_projects = (current_user) ? ((admin?) ? base_search : 
                                     base_search.where("user_id = ? or projects.id IN (?)", current_user.id, shared_project_ids)) : 
      #  base_search.where("user_id = ?", current_user.id)) :
      base_search.where(:user_id => 1, :sandbox => true, :key => session[:sandbox])
    
    tmp_projects = tmp_projects.order("updated_at desc")
    @h_counts[:private] = tmp_projects.count
    @projects = tmp_projects.limit(settings[:limit]).all.to_a
#    if current_user and !admin?
#      shares = Share.where(:user_id => current_user.id).all
#      @projects|= base_search.where({:id => Share.where(:user_id => current_user.id)}.map{|e| e.project_id}).all if shares.size > 0
#    end
  end

  # GET /projects
  # GET /projects.json
  def index
    get_projects()

    @h_organisms = {}
    Organism.all.map{|o| @h_organisms[o.id]=o}

     respond_to do |format|
      format.html { 
        if params[:nolayout]
          render :partial => 'index'
        else
          render :layout => 'welcome'
        end
      }
      format.json { render json: @projects }
    end
    
  end

  # GET /projects/1
  # GET /projects/1.json
  def show

    @error = ''
    if @project
      ### define the current project
      session[:current_project]=@project.key
      #    session[:reload_step]=0
      
      if readable? @project
        session[:viz_params]={
          'dim1' => 1,
          'dim2' => 2,
          'dim3' => 3,
          'color_by' => 'gene_text',
          'gene_text' => '',
          'dataset' => 'normalization',
          'cluster_id' => nil,
          'selection_id' => nil,
          'geneset_type' => 'all',
          'global_geneset' => (global_geneset = GeneSet.where(:user_id => 1, :project_id => nil, :organism_id => @project.organism_id).order("label").first && global_geneset && global_geneset.id) || nil,
          'custom_geneset' => (custom_geneset = GeneSet.where(:project_id => @project.id).order("label").first && custom_geneset && custom_geneset.id) || nil,
          'geneset_name' => ''
          #        'heatmap_input_type' => 'normalization'
        }
        session[:cart_display]=nil
        
        last_ps =  ProjectStep.where(:project_id => @project.id, :status_id => [1, 2, 3, 4]).order("updated_at desc").first
        last_step_id = (last_ps) ? last_ps.step_id : 1
        @last_update = get_last_update_status()
        session[:active_step]=last_step_id
        ### override active step if coming from update project form                                                                                                                     
        session[:active_step] = session[:override_active_step] if session[:override_active_step]
        session.delete(:override_active_step)
        
        params[:active_step]=last_step_id
        session[:last_step_status_id]=@project.status_id
        params[:last_step_status_id]=@project.status_id
        session[:last_step_id]=last_step_id
        
        ### setup selections
        session[:selections]={}
        if readable?(@project)
          project_dir =  Pathname.new(APP_CONFIG[:user_data_dir]) + @project.user_id.to_s + @project.key
          selection_dir = project_dir + 'selections'
          Dir.mkdir selection_dir if !File.exist?(selection_dir)
          @project.selections.each do |selection|
            file = selection.id.to_s + ".txt"
            File.open(selection_dir + file, 'r') do |f|
              session[:selections][selection.id]={:item_list => f.readlines.map{|e| e.chomp}.sort, :edited => selection.edited}
            end
          end
        end
        @h_statuses={}
        Status.all.map{|s| @h_statuses[s.id]=s}
        @h_steps={}
        Step.all.map{|s| @h_steps[s.id]=s}
      end
    else
      @error = "The project doesn't exist or the session has expired. Please create a new project."
    end
  end
  
  # GET /projects/new
  def new
    project_key = (current_user) ? create_key() : session[:sandbox]

    ### reset upload

    h = {:upload_type => 1, :project_key => project_key, :user_id => (current_user) ? current_user.id : 1}
    @fu_inputs = Fu.where(h).all
     
    if @fu_inputs.count > 0
      @fu_inputs.to_a.each do |fu_input|
        if fu_input.upload_file_name
          file_path = Pathname.new(APP_CONFIG[:upload_data_dir]) + fu_input.id.to_s + fu_input.upload_file_name
          File.delete file_path if File.exist?(file_path)
        end
        fu_input.destroy
        # end
      end
    end

    h[:status]= 'new'
    @fu_input = Fu.new(h)
    @fu_input.save!
    
    ### reset project

    @project = Project.where(:key => project_key).first
    if @project and editable? @project
      delete_project(@project)
    end
 
    @project = Project.new
    @project.key = project_key
    @shares = @project.shares.to_a
  
  end

  # GET /projects/1/edit
  def edit
    tmp_dir = Pathname.new(APP_CONFIG[:user_data_dir]) + @project.user.id.to_s + params[:key]
    @existing_group_file = 1 if File.exist?(tmp_dir + "parsing" + "group.tab")
    @h_steps={}
    @results = {}
    @all_results = {}
    @shares = @project.shares.to_a
    Step.all.map{|s| @h_steps[s.id]=s}
    active_step_name = @h_steps[session[:active_step]].name
    get_results()
    respond_to do |format|
      format.html {
        if params[:global]
          render :partial => "edit"
        else
          @h_attrs_parsing = JSON.parse(@project.parsing_attrs_json) if @project.parsing_attrs_json
          render :partial => "form_" + active_step_name 
        end
      }#:layout => nil }
    end
  end

  def manage_access
    existing_shares = @project.shares
    
    if params[:shares]
      #   h_existing_emails = {}
      h_shares = {}
      existing_shares.each do |share|
        #     h_existing_emails[share.email]=share
        h_shares[share.id]=share
      end
      
      
      params[:shares].each_key do |sid|
        h = {
          :analyze_perm => params[:shares][sid]['analyze_perm'],
          :export_perm => params[:shares][sid]['export_perm']
        }
        h_shares[sid.to_i].update_attributes(h)
      end
      
    end

    existing_shares.each do |share|
      if !params[:shares] or !params[:shares][share.id.to_s]
        share.update_attributes(:analyze_perm => false, :export_perm => false)
      end
    end
    ### read access
    #  if  @project.read_access
    #    @project.read_access.split(/\s*,\s*/).map{|e| e.gsub(/\s+/, '')}.each do |email|
    #      h_share={:read_access => true, :write_access => false}
    #      u = User.where(:email => email.downcase).first
    #      if u
    #        h_detected_users[u.id]=1
  #        if h_existing_users[u.id]
  #          h_existing_users[u.id].update_attributes(h_share)
  #        else
  #          h_share.merge({:user_id => u.id, :project_id => @project.id}) 
  #          share = Share.new(h_share)
  #          share.save
  #        end
  #      end
  #    end
  #  end
    
    ### write access
   # if  @project.write_access
   #   @project.write_access.split(/\s*,\s*/).map{|e| e.gsub(/\s+/, '')}.each do |email|
   #     h_share={:read_access => true, :write_access => true}
   #     u = User.where(:email => email.downcase).first
   #     h_detected_users[u.id]=1
   #     if u
   #       if h_existing_users[u.id]
   #         h_existing_users[u.id].update_attributes(h_share)
   #       else
   #         h_share.merge({:user_id => u.id, :project_id => @project.id})
   #         share = Share.new(h_share)
   #         share.save
   #       end
   #     end
   #   end
   # end

    ## reset accesses
    #    existing_shares.each do |share|
    #      if !h_detected_users[share.email]
    #        #        share.update_attributes(h_share)
    #        share.destroy
    #      end
    #    end
    
  end

  # POST /projects
  # POST /projects.json
  def create
    @project = Project.new(project_params)

    #    tmp_dir = Pathname.new(APP_CONFIG[:user_data_dir]) + @project.user_id.to_s
    #    Dir.mkdir(tmp_dir) if !File.exist?(tmp_dir)
    #    tmp_dir += @project.key
    #    Dir.mkdir(tmp_dir) if !File.exist?(tmp_dir)

    ### delete project if already exists with this key    
    if p = Project.where(:key => @project.key).first and editable? p
      delete_project(p)
    end
    
    tmp_attrs = params[:attrs] || {}
    tmp_attrs[:has_header] = 1 if tmp_attrs[:has_header]
    [:file_type, :sel_name, :nb_cells, :nb_genes].each do |k|
      tmp_attrs[k] = params[k] if !params[k].strip.empty?
    end
    if tmp_attrs[:file_type] != 'RAW_TEXT' ## delete the RAW_TEXT parsing options
      [:delimiter, :col_gene_name, :has_header].each do |k|
        tmp_attrs.delete(k)
      end
    end
    @project.parsing_attrs_json = tmp_attrs.to_json
    
    @project.user_id = (current_user) ? current_user.id : 1
    @project.sandbox = (current_user) ? false : true
    @project.session_id = (s = Session.where(:session_id => session.id).first) ? s.id : nil

    input_file = Fu.where(:project_key => @project.key).first
    @project.input_filename = input_file.upload_file_name

    file_path = Pathname.new(APP_CONFIG[:upload_data_dir]) + input_file.id.to_s + input_file.upload_file_name

    logger.debug("CMD_ls0 " + `ls -alt #{file_path}`)
    
    default_diff_expr_filters = {
      :fc_cutoff => '2',
      :fdr_cutoff => '0.05'
    }    
    @project.diff_expr_filter_json = default_diff_expr_filters.to_json
    
    default_gene_enrichment_filters = {
      :fdr_cutoff => '0.05'
    }
    @project.gene_enrichment_filter_json = default_gene_enrichment_filters.to_json

#    tmp_dir = Pathname.new(APP_CONFIG[:user_data_dir]) + @project.user_id.to_s
#    File.delete tmp_dir + ('input.' + @project.extension) if File.exist?(tmp_dir + ('input.' + @project.extension))
    logger.debug("1. File #{file_path} exists!") if File.exist?(file_path)

    respond_to do |format|
      if input_file and @project.save

        session[:active_dr_id] = 1
        
        ### get extension
        ext = input_file.upload_file_name.split(".").last
        if !['zip', 'gz', 'h5', 'loom'].include? ext
          ext = 'txt'
        end
        @project.update_attribute(:extension, ext)

        ### set the project id to the upload file
        input_file.update_attributes(:project_id => @project.id)
        
        ### link upload to working directory
        tmp_dir = Pathname.new(APP_CONFIG[:user_data_dir]) + @project.user_id.to_s 
        Dir.mkdir(tmp_dir) if !File.exist?(tmp_dir)
        tmp_dir += @project.key   
        Dir.mkdir(tmp_dir) if !File.exist?(tmp_dir)
        upload_path =  Pathname.new(APP_CONFIG[:upload_data_dir]) + input_file.id.to_s + input_file.upload_file_name
        #`dos2unix #{upload_path}`
        #`mac2unix #{upload_path}`        
        ### to be sure because normally it is already deleted
        File.delete tmp_dir + ('input.' + @project.extension) if File.exist?(tmp_dir + ('input.' + @project.extension))
        # ext = input_file.upload_file_name.split(".").last
        # if ext != 'zip' and ext != 'gz'
        #   ext = 'txt'
        # end
        
        File.delete tmp_dir + ('input.' + ext) if File.exist?(tmp_dir + ('input.'+ ext))
        File.symlink upload_path, tmp_dir + ('input.' + ext) 
#        logger.debug("2. File #{file_path} exists!") if File.exist?(file_path)
        ### parse batch_file

        #        @project.parse_batch_file()

        ### init project_steps
        
        (1 .. Step.count).each do |step_id|
          project_step = ProjectStep.where(:project_id => @project.id, :step_id => step_id).first
          if !project_step
            project_step = ProjectStep.new(:project_id => @project.id, :step_id => step_id, :status_id => (step_id == 1) ? 1 : nil  )
            project_step.save
          end
        end

        ### read_write access

        manage_access()
        logger.debug("3. File #{file_path} exists!") if File.exist?(file_path)
        
        @project.parse_files()
        logger.debug("4. File #{file_path} exists!") if File.exist?(file_path)
        
        #        @project.parse()
        session[:active_step]=1
        format.html { redirect_to project_path(@project.key) #, notice: 'Project was successfully created.'
        }
        format.json { render :show, status: :created, location: @project }
      else
        format.html { render :new }
        format.json { render json: @project.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /projects/1
  # PATCH/PUT /projects/1.json
  def update

    require "csv"

    tmp_dir = Pathname.new(APP_CONFIG[:user_data_dir]) + @project.user.id.to_s + params[:key]
    
    @h_steps={}
    Step.all.map{|s| @h_steps[s.id]=s}

    if params[:project][:step_id]
#      session[:active_step]= params[:project][:step_id]
      (params[:project][:step_id].to_i + 1 .. Step.all.size).to_a.each do |step_id|
        project_step = ProjectStep.where(:project_id => @project.id, :step_id => step_id).first
        project_step.update_attribute(:status_id, nil)
      end
      project_step = ProjectStep.where(:project_id => @project.id, :step_id => params[:project][:step_id]).first
      project_step.update_attributes(:status_id => 1)
      params[:project][:status_id]=1
      params[:project][:duration]=0
      step = @h_steps[params[:project][:step_id].to_i] # Step.where(:id => params[:project][:step_id].to_i).first
      params[:attrs]||={}
      params[:project][(step.obj_name + "_attrs_json").to_sym]=(params[:attrs].keys.size > 0) ? params[:attrs].to_json : "{}" 
    else ### update of project details 
      
      #@project.parse_batch_file()
      cmd = "rails parse_batch_file[#{@project.key}]"
      `#{cmd}`
      
      ### if organism changes, update the gene file                                                                                                                                                
      if @project.organism_id != params[:project][:organism_id].to_i
        parsing_dir =  tmp_dir + 'parsing'
        gene_names_file = parsing_dir + 'gene_names.json'
        cmd = "java -jar #{Rails.root}/lib/ASAP.jar -T RegenerateNewOrganism -organism #{params[:project][:organism_id]} -j #{gene_names_file} -o #{parsing_dir}"
        logger.debug("CMD: " + cmd)
        `#{cmd}`
        
        ### rewrite download files
        Step.where(["id <= ?", @project.step_id]).all.select{|e| e.id < 4}.each do |step|
          output_dir =  tmp_dir + step.name 
          output_file = output_dir + 'output.tab'
          cmd = "java -jar #{Rails.root}/lib/ASAP.jar -T CreateDLFile -f #{output_file} -j #{gene_names_file} -o #{output_dir + 'dl_output.tab'}"
          logger.debug("CMD: " + cmd)
          `#{cmd}`
        end

        
        ### delete pending jobs on gene_enrichment and de                                                                                                                                                                     
        list_pending_jobs = @project.jobs.select{|j| [6, 7].include?(j.step_id) and j.status_id == 1}
        Delayed::Job.where(:id => list_pending_jobs.map{|j| j.delayed_job_id}).all.destroy_all
        list_pending_jobs.map{|j| j.destroy}
        
        ### remove foreign keys
        
        @project.diff_exprs.map{|de| de.update_attribute(:job_id, nil)}
        @project.gene_enrichments.map{|ge| ge.update_attribute(:job_id, nil)}
        
        ### kill current jobs                                                                                                                                                                        
        
        Basic.kill_jobs(logger, @project.id, 6, @project)
        Basic.kill_jobs(logger, @project.id, 7, @project)

        
        ## delete existing DE et gene enrichments
        @project.gene_enrichments.destroy_all
        @project.diff_exprs.destroy_all
        
      end
      
      #      ### read_write access      
      #      manage_access()

    end
    respond_to do |format|
      if @project.update(project_params)
        
        ### read_write access                                                                                                                                   
        manage_access()

        if params[:project][:step_id]

          list_steps = (params[:project][:step_id].to_i .. 7).to_a

          ### remove foreign keys to jobs  

          list_steps.each do |step_id|
            if step_id == 1
              @project.update_attribute(:parsing_job_id, nil)
            elsif step_id == 2
              @project.update_attribute(:filtering_job_id, nil)
            elsif step_id == 3
              @project.update_attribute(:normalization_job_id, nil)
            elsif step_id == 4
              @project.project_dim_reductions.each do |pdr|
                pdr.update_attribute(:job_id, nil)
              end
            elsif step_id == 5
              @project.clusters.map{|cluster| cluster.update_attribute(:job_id, nil)}
            elsif step_id == 6
              @project.diff_exprs.map{|de| de.update_attribute(:job_id, nil)}
            elsif step_id == 7
              @project.gene_enrichments.map{|ge| ge.update_attribute(:job_id, nil)}
            end
          end
          
          ### remove pending delayed jobs
          list_pending_jobs = @project.jobs.select{|j| list_steps.include?(j.step_id) and j.status_id == 1}
          Delayed::Job.where(:id => list_pending_jobs.map{|j| j.delayed_job_id}).all.destroy_all
          list_pending_jobs.map{|j| j.destroy}

          
          ### kill jobs
          list_steps.each do |step_id|
            if step_id !=4
              Basic.kill_jobs(logger, @project.id, step_id, @project)
            else
              @project.project_dim_reductions.each do |pdr|
                Basic.kill_jobs(logger, @project.id, step_id, pdr)
              end
            end
          end

          #### remove files
          list_steps.each do |step_id|
            if ! (step_id == 5 and params[:project][:step_id].to_i == 3)
              ProjectStep.where(:project_id => @project.id, :step_id => step_id).all.each do |ps|
                step_name = ps.step.name
                if File.symlink?(tmp_dir + step_name)
                  File.delete(tmp_dir + step_name)
                else
                  FileUtils.rm_r Dir.glob((tmp_dir + step_name).to_s + "/*")
                end
                ps.update_attributes(:status_id => nil) if ps.step_id != params[:project][:step_id].to_i
                logger.debug("PROJECTSTEP: " + ps.to_json)
              end
            end
          end
          
          ### clean existing clusters / de analyses / visualization / diff_exprs                                                                                                                                                              
          if params[:project][:step_id].to_i < 4
            @project.gene_enrichments.destroy_all
            @project.diff_exprs.destroy_all
            @project.project_dim_reductions.destroy_all
            @project.clusters.select{|c| !c.step_id or c.step_id > 2}.map{|c| c.destroy} if params[:project][:step_id].to_i != 3
          end
             
          if @project.step_id==1
            @project.parse_files()
          elsif @project.step_id==2
            @project.run_filter()
          elsif @project.step_id==3
            @project.run_norm()          
          end

          ### kill processes that are in steps > @project.step_id

          #          if @project.step_id < 4 ###kill the latest pid running
          #            if @project.pid and `ps -ef | grep pid`
          #              Process.kill("KILL", @project.pid)
          #            end
          #          end
          #def killPid(cmd)
          #   pid=exec("pidof #{cmd}")
          #   Process.kill "USR2", pid
          #end
        end

 
        format.html {
          if params[:render_nothing] and step
   #         jobs = Job.where(:project_id => @project.id, :step_id => session[:active_step]).all.to_a
   #         jobs.sort!{|a, b| (a.updated_at.to_s || '0') <=> (b.updated_at.to_s || '0')} if jobs.size > 0
   #         last_job = jobs.last
   #         last_update = @project.status_id.to_s + ","
   #         last_update += [jobs.size, last_job.status_id, last_job.updated_at].join(",") if last_job
   #           logger.debug("COUNT_JOBS 2:" + jobs.size.to_s + " -> " + jobs.last.updated_at.to_s)
            @last_update =  get_last_update_status()
          #  if session[:last_update_active_step] != last_update 
          #    @reload_step_container = 1
          #    session[:last_update_active_step] = last_update
          #  end
            
            render :partial => 'pipeline_upd2' #:nothing => true
          else
            ### reset active_step
            session[:override_active_step]=1
            redirect_to project_path(@project.key), notice: '' 
          end
        }
        format.json { render :show, status: :ok, location: @project }
      else
        format.html { render :edit }
        format.json { render json: @project.errors, status: :unprocessable_entity }
      end
    end
  end

  def delete_project(p)

      ## remove foreign keys to jobs    
      p.update_attributes(:parsing_job_id => nil, :filtering_job_id => nil, :normalization_job_id => nil)
      p.project_dim_reductions.map{|de| de.update_attribute(:job_id, nil)}
      p.clusters.map{|cluster| cluster.update_attribute(:job_id, nil)}
      p.diff_exprs.map{|de| de.update_attribute(:job_id, nil)}
      p.gene_enrichments.map{|ge| ge.update_attribute(:job_id, nil)}
      
      ### kill jobs
      list_steps = (1 .. 7).to_a
      list_steps.each do |step_id|
        if step_id !=4
          Basic.kill_jobs(logger, p.id, step_id, p)
        else
          p.project_dim_reductions.each do |pdr|
            Basic.kill_jobs(logger, p.id, step_id, pdr)
          end
        end
      end
      
      ## delete files                                                                                            
      new_tmp_dir = Pathname.new(APP_CONFIG[:user_data_dir]) + ((p.user_id == nil) ? '0' : p.user_id.to_s) + p.key
      FileUtils.rm_r new_tmp_dir if File.exist?(new_tmp_dir)
      
      # delete objects
      p.shares.destroy_all
      #p.fus.destroy_all
      p.project_steps.destroy_all
      p.gene_enrichments.destroy_all
      p.diff_exprs.destroy_all
      p.project_dim_reductions.destroy_all
      p.selections.destroy_all
      p.clusters.destroy_all
      p.gene_sets.destroy_all
      # p.jobs.select{|j| j.status_id == 1}.map{|j| j.destroy}
      list_pending_jobs = p.jobs.select{|j| j.status_id == 1}
      Delayed::Job.where(:id => p.jobs.map{|j| j.delayed_job_id}).all.destroy_all
      list_pending_jobs.map{|j| j.destroy}
      
      p.destroy

  end
  
  # DELETE /projects/1
  # DELETE /projects/1.json
  def destroy
    
    if editable? @project
      delete_project(@project)
    end
    get_projects()

    @h_organisms = {}
    Organism.all.map{|o| @h_organisms[o.id]=o}
    
    respond_to do |format|
      #      format.html { redirect_to projects_url, notice: 'Project was successfully destroyed.' }
      format.html {
        render :partial => 'index'
      }
      
      format.json { head :no_content }
    end
  end
  
  private
  # Use callbacks to share common setup or constraints between actions.
  def set_project
    
    @project = Project.find_by_key(params[:key])
    
  end
  
  # Never trust parameters from the scary internet, only allow the white list through.
  def project_params
    #      params.fetch(:project, {})
    params.fetch(:project).permit(:name, :key, :organism_id, :group_filename, :input_filename, :status_id, :duration, :step_id, :filter_method_id, :norm_id, :parsing_attrs_json, :filter_method_attrs_json, :norm_attrs_json, :public, :pmid, :diff_expr_filter_json, :gene_enrichment_filter_json, :read_access, :write_access)
  end
end
  
