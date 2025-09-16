class ProjectsController < ApplicationController
#  before_action :authenticate_user!, except: [:index]
  before_action :set_project, only: [:show, :edit, :update, :destroy, :upd_pred, :do_import_metadata, :prepare_metadata,
                                    # :compute_module_score,
                                   #  :batch_shares,
                                     :instructions, :set_public, :get_loom_files_json,
                                     :broadcast_on_project_channel, :live_upd, 
                                     :form_select_input_data, :form_new_analysis, :form_new_metadata,                                     
                                     :upd_cat_alias, :upd_sel_cats,
                                     :parse_form, :parse, :get_step, :get_step_via_post, :get_pipeline,
                                     :get_run, :get_lineage, :get_step_header,
                                     :autocomplete_genes, :autocomplete_gene_set_items, :get_rows, :extract_row, :extract_metadata, 
                                     :filter_de_results, :filter_ge_results, :cluster_comparison, :provider_projects,
                                     :get_autocomplete_genes, :get_dr_options, 
                                     :new_selection, :save_metadata_from_selection, :dr_plot, :cell_scatter_plot, 
                                     :del_gene,
                                     :get_commands, :save_plot_settings, :get_annot_info, :upd_marker_genes, :get_marker_gene_stats, :upd_gene_expr_stats,
                                     :confirm_delete, :delete_all_runs_from_step,
                                     :get_attributes, :set_input_data, :set_geneset, :get_visualization, :replot, :get_file, :tsv_from_json, :upload_file, 
                                     :delete_batch_file, :upload_form, :clone, :direct_download,
                                     :set_landing_page, :set_ott_project
                                    ]
  before_action :empty_session, only: [:show]
#  skip_before_action :verify_authenticity_token
  include ApplicationHelper

  layout "project"


  def empty_session
    session.delete(:selections)
  end

  def set_ott_project
    if editable? @project
      h_ott_project = {
        :project_id => @project.id,
        :ontology_term_type_id => params[:ontology_term_type_id]
      }
      
      @ott_project = OttProject.where(h_ott_project).first
      h_ott_project[:not_applicable] = (params[:not_applicable] == '1') ? true : false
      if !@ott_project
        @ott_project = OttProject.new(h_ott_project)
        @ott_project.save
      else
        @ott_project.update(h_ott_project)
      end
    end
    render :partial => 'set_ott_project'
  end
  
  def set_landing_page
    if editable? @project and params[:landing_page_key]      
      @project.update_column(:landing_page_key, params[:landing_page_key])
    end

    render :partial => "set_landing_page"
  end
  
  def set_search_session
    [:search_type].each do |e|
      session[:settings][e] = params[e] if params[e]
    end
    #    render :text => session[:viz_params].to_json               
  end

  def upd_sel
    if params[:type]
      if params[:type] == 'add'
        session[:project_cart][params[:p_key]] = 1
      elsif params[:type] == 'clear'
        session[:project_cart] = {}
      else
        session[:project_cart].delete(params[:p_key])
      end
    end
    @sel_projects = Project.where(:key => session[:project_cart].keys).all
    render :partial => 'upd_sel'
  end
  
  def search_results
  end

  def upd_project_tag
    if current_user
      tag = ProjectTag.where(:name => params[:tag_name]).first
      if !tag
        tag = ProjectTag.new({:name => params[:tag_name]})
        tag.save
      end
      if params[:add_project_keys]
        Project.where(:key => params[:add_project_keys].split(",")).all.each do |p|
          if editable? p
            tag.projects << p if !tag.projects.include? p
          end
        end
      end
      if params[:del_project_keys]
        Project.where(:key => params[:del_project_keys].split(",")).all.each do |p|
          if editable? p
            p.project_tags.delete(tag)
          end
        end
      end
      render :partial => 'upd_project_tag'
    end    
  end

  def search_fca
     session[:settings][:free_text] = '[FCA]'
    session[:settings][:search_view_type] ||= 'card'
   # if params[:nolayout] == "1"
    render 'search' #, :layout => nil
    # else
   #   render 'search, ':layout => 'welcome'
   # end
  end

  def search
    session[:settings][:search_view_type] ||= 'card'
    session[:settings][:search_type] = params[:search_type] if params[:search_type]
    if params[:nolayout] == "1"
      render :layout => nil
    else
      render :layout => 'welcome'
    end
  end

  def do_search
    session[:settings][:search_view_type] ||= 'card'
    session[:settings][:search_view_type] = params[:search_view_type] if params[:search_view_type] and params[:search_view_type] != ''
    session[:settings][:free_text] ||= ''
    session[:settings][:free_text]=params[:free_text] if params[:free_text]
    session[:settings][:search_type] ||= 'public'
    ['my', 'public'].each do |prefix|      
      session[:settings][(prefix + "_per_page").to_sym]||=50 #if !session[:settings][(prefix + "_per_page").to_sym] or session[:settings][(prefix + "_per_page").to_sym]== 0
      session[:settings][(prefix + "_per_page").to_sym]=50 if  session[:settings][(prefix + "_per_page").to_sym]==0
      session[:settings][(prefix + "_page").to_sym]||=1
       session[:settings][(prefix + "_page").to_sym]=1 if session[:settings][(prefix + "_page").to_sym]==0
      session[:settings][(prefix + "_order_by").to_sym]||=0

      ['per_page', 'page', 'order_by'].each do |e|
        session[:settings][(prefix + "_" + e).to_sym]=params[(prefix + "_" + e).to_sym].to_i if params[(prefix + "_" + e).to_sym] and (params[(prefix + "_" + e).to_sym].to_i != 0 or e == 'order_by')
      end
    end

    
    orders = [:modified_at, :score, :order_name, :nber_cols, :disk_size]
    order_directions = [:desc, :desc, :asc, :desc, :desc]
    h_order = {}
    h_order_direction = {}
    ["public", "my"].each do |prefix|
      k = (prefix + "_order_by").to_sym
      session[:settings][k] = 0 if session[:settings][k] > orders.size
      h_order[prefix.to_sym] = orders[session[:settings][k]]
      h_order_direction[prefix.to_sym] = order_directions[session[:settings][k]]
    end

    free_text = session[:settings][:free_text]
    
    #    [:per_page, :page, :public_per_page, :public_page].each do |e|
    #      session[:settings][e]=params[e] if params[e]
    #    end
    
    free_text.strip!

    words = free_text.split(/\s*[; ]\s*/)

    @h_providers={}
    Provider.all.map{|p| @h_providers[p.id] = p}
    @h_statuses = {}
    Status.all.map{|s| @h_statuses[s.id] = s}
    @h_archive_statuses = {}
    ArchiveStatus.all.map{|s| @h_archive_statuses[s.id] = s}
    @h_organisms = {}
    Organism.all.map{|o| @h_organisms[o.id] = o}
    @h_steps = {}
    Step.all.map{|s| @h_steps[s.id] = s}

    @public_projects = []
    @projects = []
    @h_counts = {
      :all_public => Project.where(:public => true).count, #where("replaced_by_project_key != (?)", ['', nil]).count, # .where.not("name ~ '^\\[FCA\\]' and public_id > 1").count,
      :all_my => (admin?) ? Project.count : ((current_user) ? (Project.where(:user_id => current_user.id).count + Share.select("distinct project_id").where(:user_id => current_user.id).count) : nil)
    }
    
#    if params[:free_text] != '' 
      
    #    if  session[:settings][:search_type] == 'public'
    @query = Project.search do
      fulltext words.join(" ").gsub(/\$\{jndi\:/, '')
      with :public, true
      with :replaced_by_project_key, nil
      # without(:project_tags, 'FCA') if !admin? #public_id 
      order_by(h_order[:public], h_order_direction[:public])
      paginate :page => session[:settings][:public_page], :per_page => session[:settings][:public_per_page]
      end
    @public_projects= @query.results#.select{|p| ['', nil].include? p.replaced_by_project_key}
    
    #    elsif session[:settings][:search_type] == 'public' 
    if current_user and !admin?
      @query = Project.search do
        fulltext words.join(" ").gsub(/\$\{jndi\:/, '')
        with :shared_user_ids, current_user.id
#        with :replaced_by_prokect_key, nil
        order_by(h_order[:my], h_order_direction[:my]) #modified_at
        paginate :page => session[:settings][:my_page], :per_page =>  session[:settings][:my_per_page]
      end
    elsif admin?       
      @query = Project.search do
        fulltext words.join(" ").gsub(/\$\{jndi\:/, '')
        order_by(h_order[:my], h_order_direction[:my]) #modified_at
        paginate :page => session[:settings][:my_page], :per_page =>  session[:settings][:my_per_page]
      end
    end
    #    end
    @projects = @query.results
      
 #   end
      
#    if session[:settings][:search_type] == 'public'
#      
#      sample_identifiers = SampleIdentifier.where(:identifier => words).all
#      exp_entry_identifiers = ExpEntryIdentifier.where(:identifier => words).all
#      provider_projects = ProviderProject.where(:key => words).all
#      
#      exp_entry_ids = sample_identifiers.map{|e| e.exp_entry_id}
#      exp_entry_ids |= exp_entry_identifiers.map{|e| e.exp_entry_id}    
#      
#      #    exp_entries = ExpEntry.where(:id => exp_entry_ids).all
#      
#      query_parts = ["(exp_entry_id in (?) or identifier in (?))"]
#      query_parts.push "public is true" 
#      @projects = Project.joins(:exp_entries).where([query_parts.join(" and "), exp_entry_ids, words]).all
#
#    elsif current_user
#      
#      all_projects = Project.where(:user_id => current_user.id).all
#      @h_counts[:all_my] = all_projects.size
#      
#      h_identifiers = {}
#      all_projects.each do |p|
#        list_identifiers = [
#                            p.key,
#                            "ASAP#{p.public_id}"
#                           ]       
#        list_identifiers |= p.exp_entries.map{|ee| ee.identifier}
#        
    #      end

    @sel_projects = Project.where(:key => session[:project_cart].keys).all if session[:project_cart]
    
    now = Time.now
    if params[:auto] and (params[:public_project_ids] == @public_projects.map{|p| p.id}.join(",") and params[:my_project_ids] == @projects.map{|p| p.id}.join(",") and 
                          @public_projects.select{|p| now -p.modified_at <10}.size == 0 and @projects.select{|p| now -p.modified_at <10}.size == 0) 
      render :nothing => true, :body => nil
    else
      render :partial => 'do_search' #'search_' + session[:settings][:search_view_type] + "_view"
    end

  end

  def compute_module_score geneset_annot_id, geneset_annot_cat
    project_dir = Pathname.new(APP_CONFIG[:user_data_dir]) + @project.user_id.to_s + @project.key
    geneset_annot = Annot.where(:id => geneset_annot_id).first
    loom_file = project_dir + geneset_annot.filepath
    @cmd = "java -jar lib/ASAP.jar -T ModuleScore -loom #{loom_file} -metadata \"#{geneset_annot.name}\" -sel \"#{geneset_annot_cat}\" -dataset /matrix -m seurat -seed 42 -nBins 24 -nBackgroundGenes 100"
    return Basic.safe_parse_json(`#{@cmd}`, {})
    #    render :partial => "compute_module_score"
  end

  def compute_module_score_geneset loom_file, geneset_id, geneset_item_id
   # project_dir = Pathname.new(APP_CONFIG[:user_data_dir]) + @project.user_id.to_s + @project.key
    # geneset_annot = Annot.where(:id => geneset_annot_id).first
   # loom_file = project_dir + geneset_annot.filepath
    @cmd = "java -jar lib/ASAP.jar -T ModuleScore -loom #{loom_file} -geneset #{geneset_item_id} -dataset /matrix -h postgres:5434/asap2_data_v#{@h_env['asap_data_db_version']} -m seurat"
    @res = `#{@cmd}`
    @log4 = @res
    return Basic.safe_parse_json(@res, {})
    #    render :partial => "compute_module_score"                                                                                                                                                                     
  end

  def upd_pred 
    @annots = Annot.where(:id => params[:annot_ids].split(",")).all
    @std_method = StdMethod.where(:id => params[:std_method_id]).first
    @step = @std_method.step

    @h_results = {}
    @h_vals = {
      '0' => '&epsilon;',
      'NA' => '?'
    }
    @h_title = {
      'NA' => 'Not enough benchmarked data yet to make this prediction.'
    }
    to_render = ""
    
    if @annots.size > 0 and @std_method
      
      h_annot = {}
      biggest_annot = @annots.sort{|a,b| b.nber_cols * b.nber_rows <=> a.nber_cols * a.nber_rows}.first
      data_dir = Pathname.new(APP_CONFIG[:data_dir])
      model_dir = data_dir + 'models'
      biggest_annot_run = biggest_annot.run

      # find the last asap_docker image
      asap_docker = @docker_images.select{|e| e.name == 'fabdavid/asap_run'}.sort{|a, b| a.id <=> b.id}.last
      asap_docker_version = nil
      if m = asap_docker.tag.match(/v(\d+)/)
        asap_docker_version = m[1]
      end

      @cmd = "docker run --entrypoint '/bin/sh' --rm -v /data/asap2:/data/asap2 -v /srv/asap_run/srv:/srv fabdavid/asap_run:#{asap_docker.tag} -c 'Rscript prediction.tool.2.R predict /data/asap2/pred_models/#{@version.id} #{params[:std_method_id]} " +
     #   ((biggest_annot.dim == 1) ? "#{biggest_annot.nber_cols} #{biggest_annot.nber_rows}" : "#{biggest_annot.nber_rows} #{biggest_annot.nber_cols}") +
         "#{biggest_annot.nber_rows} #{biggest_annot.nber_cols}" + 
        " 2>&1'"
      #    cmd = "Rscript /srv/asap_run/srv/prediction.tool.2.R predict /data/asap2/pred_models/#{@project.version_id} #{biggest_annot_run.std_method_id} #{biggest_annot.nber_cols} #{biggest_annot.nber_rows} #{biggest_annot.nber_cols}"
      
      results_json = `#{@cmd}`.split("\n").first #.gsub(/^(\{.+?\})/, "\1")
      @h_results = Basic.safe_parse_json(results_json, {})
   #   to_render =  "console.log(''); console.log('#{results_json}'); $('#pred_process_duration').val('" + ((h_results['predicted_time']=='NA') ? '' : h_results['predicted_time'].to_s) + "');" +
   #     " $('#pred_max_ram').val('" + ((h_results['predicted_ram']=='NA') ? '' : h_results['predicted_ram'].to_s) + "');" +
   #     " $('#method_pred').html(\"Resource prediction: <span class='badge badge-light' title='#{h_title[h_results['predicted_ram']]}'>" +
   #   "Execution time: " + ((h_vals[h_results['predicted_time']]) ? h_vals[h_results['predicted_time']] : duration(h_results['predicted_time'])) +
   #   "</span> <span class=' badge badge-light' title='#{h_title[h_results['predicted_ram']]}'>Required RAM: " +
   #   ((h_vals[h_results['predicted_ram']]) ? h_vals[h_results['predicted_ram']] : display_mem(h_results['predicted_ram']*1000)) + "</span>\"); " +
   #     "$('#method_pred').fadeOut(0).fadeIn(300)"
      #    else
   #   to_render = "$('#method_pred').html('')"
    end
    
#    render :plain => to_render
    render :partial => 'upd_pred' 

  end

  def instructions
    f_common = "app/views/projects/_instructions.html.erb"
    f = "app/views/projects/_instructions_#{(@project.public) ? 'public' : 'private'}.html.erb"
    send_data File.read(f_common).gsub(/\#\{\@project\.key\}/, @project.key) + File.read(f).gsub(/\#\{\@project\.key\}/, @project.key), :filename => ("instructions_to_reproduce_" + @project.key + ".txt") 
  end

  def broadcast_on_project_channel
    if APP_CONFIG['authorized_service_keys'].include? params[:service_key] and @project
      @project.broadcast
    end
  end

  def upd_marker_genes
    
    project_dir = Pathname.new(APP_CONFIG[:user_data_dir]) + @project.user_id.to_s + @project.key
    @annot = Annot.where(:id => params[:annot_id]).first
    @cat_i = params[:cat_idx].to_i
    list_cats = Basic.safe_parse_json(@annot.list_cat_json, [])
    cat_name = list_cats[@cat_i]
    loom_file = project_dir + @annot.filepath
    matrix = Annot.where(:project_id => @project.id, :dim => 3, :name => "/matrix", :filepath => @annot.filepath).first

    h_marker_genes_attrs = {
#      :input_matrix_filename =>  project_dir + @annot.filepath, 
#      :input_matrix_dataset => '/matrix',
      :input_matrix => {"annot_id" => matrix.id,"run_id" => matrix.run_id},
      :groups_filename => project_dir + @annot.filepath, #[{:annot_id => matrix.id, :run_id => matrix.run_id, :output_filename => matrix.filepath  }],                             
      :groups_dataset => @annot.name,
      :groups_id => @annot.id
    }
    @marker_genes_run = Run.where(:project_id => @project.id, :attrs_json => h_marker_genes_attrs.to_json).first
    marker_genes_filepath = project_dir + 'markers' + @marker_genes_run.id.to_s + ("cat_" + (@cat_i + 1).to_s + ".tsv")
#    @marker_genes_data = File.readlines(marker_genes_filepath)

    params[:displayed_nber_genes] ||= "10"
    params[:fdr_threshold] ||= "0.05"
    params[:fc_threshold] ||= "2"
    
    [:fdr_threshold, :fc_threshold].each do |e|
      params[e] = params[e].to_f
    end
    
    session[:marker_genes][@project.id]||={}
    [:highlight_gene_type, :displayed_nber_genes, :fdr_threshold, :fc_threshold].each do |e|
      session[:marker_genes][@project.id][e] = params[e]
    end
    
    s = session[:marker_genes][@project.id]
    
    @log2fc_threshold = Math.log2(s[:fc_threshold])
    
    ## get the list of potential transcription factors                                                                                                                                                         
    
    @h_gene_types = {
      :transcription_factors => ['GO:0003677', 'GO:0006355'],
      :surface_markers => ['GO:0009986', 'GO:0005887']
    }

    @h_highlight_gene_ids = {}
    if s[:highlight_gene_type] and  s[:highlight_gene_type]!= ''
      h_types_by_go_identifier = {}
      @h_gene_types.keys.map{|k|
        @h_gene_types[k].each do |go_identifier|
          h_types_by_go_identifier[go_identifier] ||= []
          h_types_by_go_identifier[go_identifier].push k
        end
      }

      res = Basic.sql_query2(:asap_data, @h_env['asap_data_db_version'], 'gene_set_items', 'join gene_sets on (gene_set_items.gene_set_id = gene_sets.id)', 'content', "identifier IN (" + @h_gene_types[s[:highlight_gene_type].to_sym].map{|e| ("'#{e}'")}.join(", ") + ") and gene_sets.organism_id = #{@project.organism_id}")
      tmp_gene_ids = nil
      res.each do |gs|
        tmp = gs.content.split(",").map{|gid| gid.to_i}
        tmp_gene_ids ||= tmp
        tmp_gene_ids |= tmp
      end

      ##get genes                                                                                                                                                                                               
      res2 = Basic.sql_query2(:asap_data, @h_env['asap_data_db_version'], 'genes', '' , 'id, ensembl_id', "id in (#{tmp_gene_ids.join(",")})")
      @h_ensembl_ids = {}
      res2.each do |e|
        @h_ensembl_ids[e.id.to_i] = e.ensembl_id
      end
      
      if tmp_gene_ids
        tmp_gene_ids.each do |gid|
          @h_highlight_gene_ids[@h_ensembl_ids[gid]] = 1
        end
      end
    end

#    @cmd = "java -jar #{APP_CONFIG[:local_asap_run_dir]}/ASAP.jar -T ExtractMetadata -loom #{loom_file} -meta /row_attrs/Original_Gene"
#    #   @log+= @cmd2
#    h_res = Basic.safe_parse_json(`#{@cmd}`, {})
#    @cmd = "java -jar #{APP_CONFIG[:local_asap_run_dir]}/ASAP.jar -T ExtractMetadata -loom #{loom_file} -meta /row_attrs/Gene"
#    h_res2 = Basic.safe_parse_json(`#{@cmd}`, {})
#    @cmd = "java -jar #{APP_CONFIG[:local_asap_run_dir]}/ASAP.jar -T ExtractMetadata -loom #{loom_file} -meta /row_attrs/Accession"
#    h_res3 = Basic.safe_parse_json(`#{@cmd}`, {})
    
    
    file = marker_genes_filepath
    h_down_genesets = {}
    h_up_genesets = {}
    
    up_genes = []
    down_genes = []
    nber_up_genes = 0
    nber_down_genes = 0
    t = []
    if File.exist? file
      File.open(file, 'r') do |f|
        header = f.gets
        while (l = f.gets) do # and (t.size == 0 or t[4].abs > -@log2fc_threshold)) do
          t = l.chomp.split("\t")
          (4 .. 8).map{|i| t[i] = t[i].to_f}
          if t[4].abs >= @log2fc_threshold 
            if !(down_genes.size == s[:displayed_nber_genes].to_i and up_genes.size == s[:displayed_nber_genes].to_i) 
              if t[6].to_f <= s[:fdr_threshold].to_f
                if t[4] >= @log2fc_threshold 
                  if up_genes.size < s[:displayed_nber_genes].to_i
                    (4 .. 8).map{|i| t[i] = (t[i].abs > 9999 or (t[i].abs < 0.009 and t[i] != 0)) ?  "%.2E" % t[i] : t[i].round(2)}
                    up_genes.push t
                  else
                    nber_up_genes +=1
                  end
                else
                  if down_genes.size < s[:displayed_nber_genes].to_i
                    (4 .. 8).map{|i| t[i] = (t[i].abs > 9999 or (t[i].abs < 0.009 and t[i] != 0)) ?  "%.2E" % t[i] : t[i].round(2)}
                    down_genes.push t
                  else
                    nber_down_genes +=1
                  end
                end
              end
            else
              if t[6].to_f <= s[:fdr_threshold].to_f
                if t[4] >= @log2fc_threshold
                  nber_up_genes += 1
                else
                  nber_down_genes += 1
               end
              end
            end
          else
            break
          end
        end
      end
    end
    
    nber_up_genes += up_genes.size
    nber_down_genes += down_genes.size

    ## get the cell ids
    cmd = "java -jar lib/ASAP.jar -T ExtractMetadata -loom #{h_marker_genes_attrs[:groups_filename]} -stable_ids -meta '#{@annot.name}'"
    cat_res = Basic.safe_parse_json(`#{cmd}`, {})
    if cat_res['values']
      group_cell_idx = (0 .. cat_res['values'].size-1).select{|i| cat_res['values'][i] == cat_name}
    end
#    ## get expression data for genes
#    expr_data = {}
    up_genes.map{|e| e[6].to_f.abs}.sort.last(10).map{|e| s[:up][e]=1}
    down_genes.map{|e| e[6].to_f.abs}.sort.last(10).map{|e| s[:down][e]=1}
#    list_stable_ids = {}
    
#    list_stable_ids[:up] = up_genes.map{|e| e[0].to_i}.sort.first(10)
#    #up_genes.map{|e| e[0].to_i}.sort    
#    cmd = "java -jar lib/ASAP.jar -T ExtractRow -loom #{h_marker_genes_attrs[:groups_filename]} -iAnnot /matrix -stable_ids #{list_stable_ids[:up].join(",")}"
#    expr_data[:up] = Basic.safe_parse_json(`#{cmd}`, {})
#    list_stable_ids[:down] = down_genes.map{|e| e[0].to_i}.sort
#    cmd = "java -jar lib/ASAP.jar -T ExtractRow -loom #{h_marker_genes_attrs[:groups_filename]} -iAnnot /matrix -stable_ids #{list_stable_ids[:down].join(",")}"
#    expr_data[:down] = Basic.safe_parse_json(`#{cmd}`, {})


#    ## get expression data for genes            
#    sum_expr_data = {}
#    cmd = "java -jar lib/ASAP.jar -T GetGeneStats --loom #{h_marker_genes_attrs[:groups_filename]} --iAnnot /matrix --stable-ids #{list_stable_ids[:up].join(",")}"
#    sum_expr_data[:up] = Basic.safe_parse_json(`#{cmd}`, {})
#    cmd = "java -jar lib/ASAP.jar -T GetGeneStats --loom #{h_marker_genes_attrs[:groups_filename]} --iAnnot /matrix --stable-ids #{list_stable_ids[:down].join(",")}"
#    sum_expr_data[:down] = Basic.safe_parse_json(`#{cmd}`, {})

#    up_genes = res.select{|e| e[6] <= s[:fdr_threshold].to_f and s[4] > 0}

#    `less #{file}`.split("\n").map{|e| e.split("\t")}
#    res.shift
#    res = res.map{|l| l.map{|e| e.to_f}}
#    #    @tmp_res = res
#    down_genes = []
#    @tmp = ""
#    res.each_index do |i|
#      t = res[i]
#    #  t_f = t.map{|f|}
#      # t = l.split("\t")                                                      
#      if t[2] != 'NA' and t[0] != 'NA' and t[2].to_f <= s[:fdr_threshold].to_f and t[0].to_f <= -@log2fc_threshold
#        #        break if t[0].to_f > 0
#        down_genes.push [h_res2["values"][i] || h_res["values"][i], h_res3["values"][i], t.map{|e| (e.abs > 9999 or (e.abs < 0.009 and e != 0)) ? "%.2E" % e : e.round(2)}]
#        break if down_genes.size == s[:displayed_nber_genes].to_i
#      end
#    end
#    
#    up_genes = []
#    reversed_res = res.reverse
#    reversed_res.each_index do |i|
#      # t = l.split("\t")              
#      j = res.size-1-i
#      t = res[j]
#     # @tmp +='gogo'
#      if t[2] != 'NA' and t[0] != 'NA' and t[2].to_f <= s[:fdr_threshold].to_f and t[0].to_f >= @log2fc_threshold
#    #    @tmp += j.to_s + ":" +  t[0] + "-" + t[2] + "-" + s[:fdr_threshold].to_f.to_json + "-" + @log2fc_threshold.to_json
#        #      break if t[0].to_f < 0
#        up_genes.push [h_res2["values"][j] || h_res["values"][j], h_res3["values"][j], t.map{|e| (e.abs > 9999 or e.abs < 0.009 and e != 0) ? "%.2E" % e : e.round(2)}]
#        break if up_genes.size == s[:displayed_nber_genes].to_i
#      end
#    end
    
    @h_res = {
      :run_id => @marker_genes_run.id, #h_attrs_by_run_id[r.id]["group_ref"], h_attrs_by_run_id[r.id]["group_comp"],  
      :up_genes => up_genes, 
      :down_genes => down_genes, #, @h_ge[r.id], h_attrs_by_run_id[r.id]["groups"][0]['run_id'].to_i
      :nber_up_genes => nber_up_genes,
      :nber_down_genes => nber_down_genes,
#      :expr_data => expr_data,
#      :sum_expr_data => sum_expr_data,
      :cats => cat_res,
      :group_cell_idx => group_cell_idx
    }
    # @res.push(tmp_res)
  

    render :partial => "upd_marker_genes"

  end

  def upd_gene_expr_stats

    project_dir = Pathname.new(APP_CONFIG[:user_data_dir]) + @project.user_id.to_s + @project.key
    @annot = Annot.where(:id => params[:annot_id]).first
    if @annot
      @list_cats = Basic.safe_parse_json(@annot.list_cat_json, [])
      @h_cat_info = Basic.safe_parse_json(@annot.cat_info_json, {})
      @h_sel_clas = {}
      @nber_clas = {}
      @h_cots = {}
      @h_genes = {}
      @sel_clas = []
      if @h_cat_info['selected_cla_ids']
        
        #      sel_clas = Cla.where(:id => @h_cat_info['selected_cla_ids'].select{|e| e != ''}).all.to_a                                                                                                       
        h_cat_mapping = {}
        @sel_clas = (0 .. @list_cats.size-1).to_a.map{|e| nil}
        @nber_clas = (0 .. @list_cats.size-1).to_a.map{|e| 0}
        annot_cell_sets = AnnotCellSet.where(:annot_id => @annot.id, :cat_idx => (0 .. @list_cats.size-1).to_a).all
        annot_cell_sets.map{|e| h_cat_mapping[e.cell_set_id] = e.cat_idx}
        cell_sets = CellSet.where(:id => h_cat_mapping.keys).all
        cell_sets.map{|e| @nber_clas[h_cat_mapping[e.id]] = e.nber_clas}
        Cla.where(:id => cell_sets.map{|e| e.cla_id}).all.map{|cla| cat_idx = h_cat_mapping[cla.cell_set_id]; @sel_clas[cat_idx] = cla}
        #@sel_clas = sel_clas                                                                                                                                                                            
        cot_ids = []
        tmp_up_gene_ids = []
        tmp_down_gene_ids = []
        @sel_clas.compact.each do |cla|
          @h_sel_clas[cla.id] = cla
          cot_ids |= cla.cell_ontology_term_ids.split(",").map{|e| e.to_i} if cla.cell_ontology_term_ids
          tmp_up_gene_ids |= cla.up_gene_ids.split(",").map{|e| e.to_i} if cla.up_gene_ids
          tmp_down_gene_ids |= cla.down_gene_ids.split(",").map{|e| e.to_i} if cla.down_gene_ids
        end
        
        if cot_ids.size > 0
          CellOntologyTerm.where(:id => cot_ids).all.each do |cot|
            @h_cots[cot.id] = cot
          end
        end
        
        @tmp_genes = []
        tmp_gene_ids = tmp_up_gene_ids | tmp_down_gene_ids
        if @h_env
          @tmp_genes = Basic.sql_query2(:asap_data, @h_env['asap_data_db_version'], 'genes', '', 'id, name, ensembl_id', "id IN (" + tmp_gene_ids.join(",") + ")")
          @tmp_genes.each do |gene|
            @h_genes[gene.id.to_i] = gene
          end
        end
      end
      

      loom_file = project_dir + @annot.filepath
      gene_stable_id = 1
      cmd = "java -jar lib/ASAP.jar -T ExtractMetadata -loom #{loom_file} -meta #{@annot.name}"
      @cmd = cmd
      res = Basic.safe_parse_json(`#{cmd}`, {})
      @cat_cells = {}
      if res and res['values'] and res['values'].size > 0
        res['values'].each_index do |i|
          @cat_cells[res['values'][i]]||=[]
          @cat_cells[res['values'][i]].push i
        end
      end
    end

   render :partial => 'upd_gene_expr_stats'

  end



  def get_marker_gene_stats

    project_dir = Pathname.new(APP_CONFIG[:user_data_dir]) + @project.user_id.to_s + @project.key
    @annot = Annot.where(:id => params[:annot_id]).first
    @cat_i = params[:cat_idx].to_i
    list_cats = Basic.safe_parse_json(@annot.list_cat_json, [])
    cat_name = list_cats[@cat_i]
    loom_file = project_dir + @annot.filepath
    matrix = Annot.where(:project_id => @project.id, :dim => 3, :name => "/matrix", :filepath => @annot.filepath).first

    h_marker_genes_attrs = {
      :input_matrix => {"annot_id" => matrix.id,"run_id" => matrix.run_id},
#      :input_matrix_filename =>  project_dir + @annot.filepath,
#      :input_matrix_dataset => '/matrix',
      :groups_filename => project_dir + @annot.filepath, #[{:annot_id => matrix.id, :run_id => matrix.run_id, :output_filename => matrix.filepath  }],       
      :groups_dataset => @annot.name,
      :groups_id => @annot.id
    }
    
    #    nber_up_genes += up_genes.size
    #    nber_down_genes += down_genes.size

#    ## get the cell ids                                                                                                                                                                                     #  
#    cmd = "java -jar lib/ASAP.jar -T ExtractMetadata -loom #{h_marker_genes_attrs[:groups_filename]} -stable_ids -meta '#{@annot.name}'"
#    cat_res = Basic.safe_parse_json(`#{cmd}`, {})
#    group_cell_idx = (0 .. cat_res['values'].size-1).select{|i| cat_res['values'][i] == cat_name}
    
    ## get expression data for genes                                                                                                                                                                          
    expr_data = {}
    #   s[:up] ||=  up_genes.map{|e| e[0].to_i}.sort.first(10)                                                                                                                                                
    list_stable_ids = {}

    type = params[:type]
#    k = (type + "_stable_ids").to_sym

    list_stable_ids = params[:gene_stable_ids] #up_genes.map{|e| e[0].to_i}.sort.first(10)
    #up_genes.map{|e| e[0].to_i}.sort                                                                                                                                                                         
#    cmd = "java -jar lib/ASAP.jar -T ExtractRow -loom #{h_marker_genes_attrs[:groups_filename]} -iAnnot /matrix -stable_ids #{list_stable_ids[:up].join(",")}"
#    expr_data[:up] = Basic.safe_parse_json(`#{cmd}`, {})
    
#    list_stable_ids[:down] = params[:down_stable_ids] #down_genes.map{|e| e[0].to_i}.sort
#    cmd = "java -jar lib/ASAP.jar -T ExtractRow -loom #{h_marker_genes_attrs[:groups_filename]} -iAnnot /matrix -stable_ids #{list_stable_ids[:down].join(",")}"
#    expr_data[:down] = Basic.safe_parse_json(`#{cmd}`, {})


    ## get expression data for genes                                                                                                                                                                          
    sum_expr_data = {}
    
    cmd = "java -jar lib/ASAP.jar -T GetGeneStats --loom #{h_marker_genes_attrs[:groups_filename]} --id #{@annot.id} --index #{@cat_i+1} --iAnnot /matrix --stable-ids #{list_stable_ids}"
    r = `#{cmd}`
    i=0
    while (r == '' and i< 10) do
      r = `#{cmd}`
      i+=1
      sleep 0.1
    end
    sum_expr_data = Basic.safe_parse_json(r, {})
    #    cmd = "java -jar lib/ASAP.jar -T GetGeneStats --loom #{h_marker_genes_attrs[:groups_filename]} --iAnnot /matrix --stable-ids #{list_stable_ids[:down].join(",")}"
#    sum_expr_data[:down] = Basic.safe_parse_json(`#{cmd}`, {})

     @h_res = {
      :cmd => cmd,
      :res => r,
      :sum_expr_data => sum_expr_data
    }

    render :partial => "get_marker_gene_stats"

  end

  def get_annot_info

    project_dir = Pathname.new(APP_CONFIG[:user_data_dir]) + @project.user_id.to_s + @project.key

#    @h_std_methods = {}
    
    std_methods = StdMethod.where(:docker_image_id => @docker_images.map{|e| e.id}).all
    @h_steps = {}
   # Step.where(:version_id => @project.version_id).all.map{|s| @h_steps[s.id] = s}
    Step.where(:id => std_methods.map{|e| e.step_id}.uniq).all.map{|s| @h_steps[s.id] = s}
    @h_statuses = {}
    Status.all.map{|s| @h_statuses[s.id] = s}

    ## reinitialize selected marker genes
    session[:marker_genes][@project.id]={:up => {}, :down => {}}

    @annot = Annot.where(:id => params[:annot_id]).first
    @cat_i = params[:cat_idx].to_i
    loom_file = project_dir + @annot.filepath

    @annot_cell_set = AnnotCellSet.where(:annot_id => @annot.id, :cat_idx => @cat_i).first
    matrix = Annot.where(:project_id => @project.id, :dim => 3, :name => "/matrix", :filepath => @annot.filepath).first

    h_marker_genes_attrs = {
       :input_matrix => {"annot_id" => matrix.id,"run_id" => matrix.run_id},
#      :input_matrix_filename =>  project_dir + @annot.filepath,
#      :input_matrix_dataset => '/matrix',
      :groups_filename => project_dir + @annot.filepath, #[{:annot_id => matrix.id, :run_id => matrix.run_id, :output_filename => matrix.filepath  }],
      :groups_dataset => @annot.name,
      :groups_id => @annot.id
    }
    @marker_genes_run = Run.where(:project_id => @project.id, :attrs_json => h_marker_genes_attrs.to_json).first

    if !@marker_genes_run
      h_markers = Basic.find_markers(logger, @project, @annot, @annot.user_id)                                                                                        
      h_marker_enrichment = Basic.find_marker_enrichment(logger, @project, @annot, h_markers[:run], @annot.user_id)         
    end
    
    @marker_genes_run = Run.where(:project_id => @project.id, :attrs_json => h_marker_genes_attrs.to_json).first

   # marker_genes_filepath = project_dir + 'markers' +  @marker_genes_run.id.to_s + ("cat_" + (@cat_i + 1).to_s + ".tsv")
   # @marker_genes_data = File.readlines(marker_genes_filepath)
#    @cla = Cla.new(:project_id => @project.id, :annot_id => params[:annot_id], :cat => params[:cat_name], :cat_idx => params[:cat_idx].to_i)
     @cla = Cla.new(:project_id => @project.id, :annot_id => params[:annot_id], :cat => params[:cat_name], :cat_idx => params[:cat_idx].to_i, :cell_set_id => (@annot_cell_set) ? @annot_cell_set.cell_set_id : nil)
    #    @all_clas = Cla.where(:project_id => @project.id).all
  #  @all_clas = Cla.where(:project_id => @project.id, :annot_id => params[:annot_id], :cat_idx => params[:cat_idx].to_i).all
    @all_clas = Cla.where(:cell_set_id => @annot_cell_set.cell_set_id).all
    @h_votes = {}
    if current_user
      my_votes = ClaVote.where(:cla_id => @all_clas.map{|c| c.id}, :user_id => current_user.id).all
      my_votes.each do |v|
        @h_votes[v.cla_id] = v
      end
      #votes.map{|v| h_votes[v.user_id] = v}
      #h_my_votes[my_vote.id] = my_vote
    end
    @h_cots = {}
    @h_genes = {}
    tmp_cot_ids = []
    tmp_down_gene_ids = []
    tmp_up_gene_ids = []
    @all_clas.each do |cla|
      tmp_cot_ids |= cla.cell_ontology_term_ids.split(",").map{|e| e.to_i} if cla.cell_ontology_term_ids
      tmp_up_gene_ids |= cla.up_gene_ids.split(",").map{|e| e.to_i} if cla.up_gene_ids
      tmp_down_gene_ids |= cla.down_gene_ids.split(",").map{|e| e.to_i} if cla.down_gene_ids
    end
    
    @h_cla_sources = {}
    ClaSource.all.map{|e| @h_cla_sources[e.id] = e}
    
    @h_all_cla_votes = {}
    
    all_votes = ClaVote.where(:cla_id => @all_clas.map{|e| e.id}).all.to_a
    
    all_votes.each do |vote|
      @h_all_cla_votes[vote.cla_id]||=[]
      @h_all_cla_votes[vote.cla_id].push vote
    end

    
    if tmp_cot_ids.size > 0
      CellOntologyTerm.where(:id => tmp_cot_ids).all.each do |cot|
        @h_cots[cot.id] = cot
      end
    end
    
    tmp_gene_ids = tmp_up_gene_ids | tmp_down_gene_ids
    if @h_env
      tmp_genes = Basic.sql_query2(:asap_data, @h_env['asap_data_db_version'], 'genes', '', 'id, name, ensembl_id', "id IN (" + tmp_gene_ids.join(",") + ")")
      tmp_genes.each do |gene|
        @h_genes[gene.id.to_i] = gene
      end
    end

    # get depth
    cmd = "java -jar #{APP_CONFIG[:local_asap_run_dir]}/ASAP.jar -T ExtractMetadata -loom #{loom_file} -meta /col_attrs/_Depth"
    @depth = Basic.safe_parse_json(`#{cmd}`, {})
    
    render :partial => 'annot_info'

  end

  def get_std_methods
    @h_std_methods = {} #h_methods_steps[:std_methods]
    std_methods = StdMethod.where(:docker_image_id => @docker_images.map{|e| e.id}).all
    std_methods.map{|s| @h_std_methods[s.id] = s}
    return std_methods
  end
  
  def get_steps std_methods
    @h_steps = {}
    steps = Step.where(:id => std_methods.map{|e| e.step_id}.uniq).all
    steps |= Step.where(:docker_image_id => @docker_images.map{|e| e.id}).all
    steps.map{|s| @h_steps[s.id] = s}
    return steps
  end

  def get_loom_files_json

    project_dir =  Pathname.new(APP_CONFIG[:user_data_dir]) + @project.user_id.to_s + @project.key
   # h_env = Basic.safe_parse_json(@project.version.env_json, {})
   # docker_name = "#{h_env['docker_images']['asap_run']['name']}:#{h_env['docker_images']['asap_run']['tag']}"

    list_files = []
    h_data_types = {}
    DataType.all.each do |dt|
      h_data_types[dt.id] = dt
    end

    std_methods = get_std_methods()
    get_steps(std_methods)
      
    #    @h_steps = {}    
    #    Step.where(:version_id => @project.version_id).all.map{|s| @h_steps[s.id] = s}
    
    #    @h_std_methods = {}
    #    StdMethod.where(:version_id => @project.version_id).all.map{|s| @h_std_methods[s.id] = s}
    
    not_found = Run.where(:project_id => @project.id).all.select{|e| !@h_steps[e.step_id]}.map{|e| e.step_id}.uniq
    logger.debug("NOT_FOUND: #{not_found.to_json}; #{@docker_images.map{|e| e.id}}")
    #runs = Run.where(:project_id => @project.id).all.select{|e| @h_steps[e.step_id]}.sort{|a, b| [@h_steps[a.step_id].rank, a.created_at] <=> [@h_steps[b.step_id].rank, b.created_at] }
    runs = Run.where(:project_id => @project.id).all.sort{|a, b| [@h_steps[a.step_id].rank, a.created_at] <=> [@h_steps[b.step_id].rank, b.created_at] } 
    h_annots_by_run_id = {}
    annots = Annot.where(:project_id => @project.id).all
    annots.each do |annot|
      h_annots_by_run_id[annot.run_id]||=[]
      h_annots_by_run_id[annot.run_id].push annot
    end
    
    h_std_method_attrs = get_std_method_details(runs.select{|r| h_annots_by_run_id[r.id]})
    get_dashboards
    
    h_file_details = {}
    h_annots_by_path = {}
    
    runs.select{|r| h_annots_by_run_id[r.id]}.each do |r|
      h_annots_by_run_id[r.id].each do |a|
        h_annots_by_path[a.filepath]||=[]
        h_attrs = Basic.safe_parse_json(r.attrs_json, {})
        
        h_a = {
          :name => a.name,
          #          :run_name => display_run2(r, @h_steps[r.step_id], @h_std_methods[r.std_method_id]),
          #          :run_params => display_run_attrs_txt(r, h_attrs, h_std_method_attrs), 
          :nber_cols => a.nber_cols,
          :nber_rows => a.nber_rows,
          :data_type => (h_data_types[a.data_type_id]) ? h_data_types[a.data_type_id].name : 'NA',
          :imported => a.imported
        }
        h_annots_by_path[a.filepath].push(h_a)
        if a.dim==3 and ! h_file_details[a.filepath]
          h_file_details[a.filepath] = {
            :file_size => File.size(project_dir + a.filepath),
            :run_name =>  display_run_short_txt(r), #display_run(r, @h_steps[r.step_id], @h_std_methods[r.std_method_id]), 
            :run_attrs => display_run_attrs(r, h_attrs, h_std_method_attrs, {}),
            :nber_cols => a.nber_cols, :nber_rows => a.nber_rows
          }
        end
      end
    end
    
    
    
    h_annots_by_path.each_key do |k|
      h5ad_file = k.dup
      h5ad_file.gsub!(/loom$/, 'h5ad')

      ## create h5ad file if doesn't exist
      #if !File.exist? project_dir + h5ad_file
      #  rscript_cmd = "Rscript -e 'library(\\\"sceasy\\\"); loom_file <- \\\"#{project_dir + k}\\\"; sceasy::convertFormat(loom_file, from=\\\"loom\\\", to=\\\"anndata\\\", outFile=\\\"#{project_dir + h5ad_file}\\\")'"
      #  cmd = "docker run --entrypoint '/bin/sh' --rm -v #{APP_CONFIG[:data_dir]}:#{APP_CONFIG[:data_dir]} #{docker_name} -c \"#{rscript_cmd}\""
      #  logger.debug("CREATE H5AD file: " + cmd)
      #  `#{cmd}`
      #end

      h_file = {
        :name => k,
        :file_size => display_mem(h_file_details[k][:file_size]),
        :run_name => h_file_details[k][:run_name],
        :run_attrs => h_file_details[k][:run_attrs],
        :nber_cols => h_file_details[k][:nber_cols],
        :nber_rows => h_file_details[k][:nber_rows],
        :url => APP_CONFIG[:server_url] + "/projects/#{@project.key}/get_file?filename=#{k}",
        :url_h5ad => APP_CONFIG[:server_url] + "/projects/#{@project.key}/get_file?filename=#{h5ad_file}",
        :content => h_annots_by_path[k]
      }
      list_files.push(h_file)
    end
    
    #    store_runs = Run.where(:id => h_store_run_ids.keys).all 
    if params[:download]
      send_data list_files.to_json, :filename => "loom_files_#{@project.key}.json"
    else
      render :json => list_files 
    end
  end

  def set_public
    now = Time.now
    h_upd = { 
      :public => true, 
      :frozen_at => now 
    }
    if @project.public == false
      h_upd[:public_at] = now
      h_upd[:public_id] = Project.select("public_id").where("public_id is not null").order("public_id desc").limit(1).first.public_id.to_i + 1
    end
    @project.update_attributes(h_upd)
    render :partial => "set_public"
  end

  def confirm_delete
    render :partial => "confirm_delete"
  end

  def delete_all_runs_from_step 
    runs = Run.where(:project_id => @project.id, :step_id => params[:step_id]).all
    runs.each do |run|
      RunsController.destroy_run_call(@project, run)
    end
    render :partial => "delete_all_runs_from_step"
  end

  def dashboard_markers

    params[:displayed_nber_genes] ||= "10"
    params[:fdr_threshold] ||= "0.05"
    params[:fc_threshold] ||= "2"
    
    [:fdr_threshold, :fc_threshold].each do |e|
      params[e] = params[e].to_f
    end
    
    @log2fc_threshold = Math.log2(params[:fc_threshold].to_f)
 
    ## get the list of potential transcription factors

    @h_gene_types = {
      :transcription_factors => ['GO:0003677', 'GO:0006355'],
      :surface_markers => ['GO:0009986', 'GO:0005887']
    }

    @h_highlight_gene_ids = {}
    if params[:highlight_gene_type] and  params[:highlight_gene_type]!= ''
      h_types_by_go_identifier = {}
      @h_gene_types.keys.map{|k| 
        @h_gene_types[k].each do |go_identifier|
          h_types_by_go_identifier[go_identifier] ||= []
          h_types_by_go_identifier[go_identifier].push k
        end
      }
      
      res = Basic.sql_query2(:asap_data, @h_env['asap_data_db_version'], 'gene_set_items', 'join gene_sets on (gene_set_items.gene_set_id = gene_sets.id)', 'content', "identifier IN (" + @h_gene_types[params[:highlight_gene_type].to_sym].map{|e| ("'#{e}'")}.join(", ") + ") and gene_sets.organism_id = #{@project.organism_id}")
      tmp_gene_ids = nil
      res.each do |gs|
        tmp = gs.content.split(",").map{|gid| gid.to_i}
        tmp_gene_ids ||= tmp
        tmp_gene_ids |= tmp
      end

      ##get genes
      res2 = Basic.sql_query2(:asap_data, @h_env['asap_data_db_version'], 'genes', '' , 'id, ensembl_id', "id in (#{tmp_gene_ids.join(",")})")
      @h_ensembl_ids = {}
      res2.each do |e|
        @h_ensembl_ids[e.id.to_i] = e.ensembl_id 
      end

      if tmp_gene_ids
        tmp_gene_ids.each do |gid|
          @h_highlight_gene_ids[@h_ensembl_ids[gid]] = 1
        end
      end
    end

    @successful_runs = @runs.select{|r| r.status_id == 3}

    if params[:de_markers_run_id]
      session[:de_markers][@project.id] = params[:de_markers_run_id].to_i
    end
    session[:de_markers][@project.id] ||= @successful_runs.first.id 
    @log = ''
    
    h_std_method_attrs = get_std_method_details(@successful_runs)
    
    h_attrs_by_tag = {}
    h_attrs_by_run_id = {}
    h_annots = {}
    h_runs = {}
    @successful_runs.map{|r|
      h_tmp = Basic.safe_parse_json(r.attrs_json, {})
      @log+= h_tmp.to_json
      h_tmp.each_key do |k|
        v = h_tmp[k]
        if (v.is_a? Hash and v['annot_id'])
          h_annots[v['annot_id'].to_i] = nil
          h_runs[v['run_id'].to_i] = nil
        elsif v.is_a? Array
          v.each do |ve|
            if  (ve.is_a? Hash and ve['annot_id'])
              h_annots[ve['annot_id'].to_i]=nil
            end
          end
        end
      end
    

      # h_tmp = JSON.parse(r.attrs_json)
      h_attrs_by_run_id[r.id] = h_tmp
      # if (h_tmp['group_comp'] == ''){
      h_filtered_attrs={}
      h_filtered_attrs['method'] = r.std_method.name
      h_tmp.keys.reject{|k| 
        ['group_comp', 'group_ref'].include? k or 
        ((std_method_attr = (e = h_std_method_attrs[r.std_method_id]) ? e[k] : nil) and
         attr_default = (std_method_attr['default']) ? std_method_attr['default'].to_s : '' and 
         attr_default == h_tmp[k].to_s)
      }.map{|k| h_filtered_attrs[k] = h_tmp[k]}
      
      tag = h_filtered_attrs
      
      h_attrs_by_tag[tag]||=[]
      h_attrs_by_tag[tag].push({:run => r, :h_attrs => h_tmp})
      # }
    } 

    Annot.where(:id => h_annots.keys).all.map{|a| h_annots[a.id] = a}
    Run.where(:id => h_runs.keys).all.map{|r| h_runs[r.id] = r}
    @l= [] 
    @list_runs = []


    if h_attrs_by_tag
      h_attrs_by_tag.each_key do |tag|
        # @log += 'tag'
        tmp_list_runs = h_attrs_by_tag[tag].map{|e| e[:run]}
        @l.push([display_attrs_txt(@h_step_id_by_name['de'], tag, {:h_annots => h_annots, :h_runs => h_runs}) + " (#{h_attrs_by_tag[tag].size} clusters)", tmp_list_runs.map{|e| e.id}.join(",")]) 
        if h_attrs_by_tag[tag].map{|e| e[:run].id}.include? session[:de_markers][@project.id]
          #   @log += 'tbtbtb'
          @list_runs = tmp_list_runs #.map{|e| e.id]}.join(",")
        end
      end 
    end
    
#    @log = @list_runs.to_json

    @res = []
    #    @h_cat_aliases = Basic.safe_parse_json(@cat_annot.cat_aliases_json, {})
    @h_cat_aliases ={}
    h_user_ids = {}
    @h_annots_by_run_id = {}
    Annot.where(:dim => 1, :run_id => @list_runs.map{|r| h_attrs_by_run_id[r.id]["groups"][0]['run_id']}).all.each do |annot|
      @h_annots_by_run_id[annot.run_id] = annot
      @h_cat_aliases[annot.run_id] = Basic.safe_parse_json(annot.cat_aliases_json, {}) 
      if @h_cat_aliases[annot.run_id]['user_ids']
        @h_cat_aliases[annot.run_id]['user_ids'].each_key do |cat_id|
          h_user_ids[@h_cat_aliases[annot.run_id]['user_ids'][cat_id]] = 1
        end
      end
    end
    
    @h_users = {}
    User.where(:id => h_user_ids.keys).all.each do |u|
      @h_users[u.id] = u
    end

    filtered_stats_file =  @project_dir + 'tmp' + "#{(current_user) ? current_user.id : 1}_ge_filtered_stats.json" #+ 'ge' + 'filtered_stats.json'
    @h_filtered_stats = {}
    if File.exist? filtered_stats_file
      @h_filtered_stats = Basic.safe_parse_json(File.read(filtered_stats_file), {})
    end

    ##### WE ALREADY HAVE FILTERED STATS
    ## get summary gene_enrichment
    #sum_ge_file = @project_dir + 'ge' + 'sum.json' 
    #h_sum_ge = {}
    #if File.exist?(sum_ge_file)
    #  h_sum_ge = Basic.safe_parse_json(File.read(sum_ge_file), {})
    #end
    
    ### get gene enrichments                                                                                                                        
    @successful_ge_runs = Run.joins(:step).where(:project_id => @project.id, :steps => {:name => 'ge'}, :status_id => 3).all
    @h_ge_runs = {}
    @successful_ge_runs.map{|r| @h_ge_runs[r.id] = r}

    ##### WE ALREADY HAVE FILTERED STATS
    ### compute and write sum if not up-to-date
    #if @successful_ge_runs.map{|e| e.id}.sort != h_sum_ge.keys.sort
    #  @successful_ge_runs.each do |r|
    #    if !h_sum_ge[r.id]
    #      file_ge =  @project_dir + 'ge' + r.id.to_s + "output.json"                                                                                                    
    #      nber_down = h_ge_data['down'].size
    #      #    h_up_genesets[ge_run_id] = h_ge_data['up'].first(10)                                                                                                           #    
    ##  end                      
    #      h_sum_ge[r.id]= {:up => nber_up, :down => nber_down}
    #    end
    #  end
    #end

    h_gene_set_ids = {}
    @h_ge = {}
    @successful_ge_runs.each do |r|
      h_attrs = Basic.safe_parse_json(r.attrs_json, {})
      @h_ge[h_attrs['input_de']["run_id"].to_i]||=[]
      @h_ge[h_attrs['input_de']["run_id"].to_i].push [r.id, h_attrs]
      h_gene_set_ids[h_attrs['gene_set_id']] = 1
    end
    
    ## get geneset ids
    @h_gene_sets = {}
    # Thread.new do
    res = Basic.sql_query2(:asap_data, @h_env['asap_data_db_version'], 'gene_sets', '', '*', "id IN (#{h_gene_set_ids.keys.join(",")})")
    res.each do |gs|
      @h_gene_sets[gs.id.to_i] = gs
    end

    #      ConnectionSwitch.with_db(:data_with_version, @h_env['asap_data_db_version']) do
    #        GeneSet.where(:id => h_gene_set_ids.keys).all.each do |gs|
    #          @h_gene_sets[gs.id] = gs
    #        end
    #   end
    # end
    @list_runs.each do |r|
      file = @project_dir + 'de' + r.id.to_s + "output.txt"
      h_down_genesets = {}
      h_up_genesets = {}
      #  @h_ge[r.id].each do |ge_run_id|
      #    file_ge =  @project_dir + 'ge' + ge_run_id.to_s + "output.json"
      #    h_down_genesets[ge_run_id] = h_ge_data['down'].first(10)
      #    h_up_genesets[ge_run_id] = h_ge_data['up'].first(10)
      #  end
      
      #      h_ge_data = Basic.safe_parse_json(File.read(file_ge), {})
   #   down_genes = `head -#{params[:displayed_nber_genes].to_i} #{file}`.split("\n").map{|l| l.split("\t")}.select{|t| t[7].to_f <= params[:fdr_threshold].to_f}
    
      res = `less #{file}`.split("\n").map{|e| e.split("\t")}
      down_genes = []
      res.each do |t|
       # t = l.split("\t")
        if t[7] != 'NA' and t[5] != 'NA' and t[7].to_f <= params[:fdr_threshold].to_f and t[5].to_f <= -@log2fc_threshold
          break if t[5].to_f > 0
          down_genes.push t
          break if down_genes.size == params[:displayed_nber_genes].to_i
        end
      end
      #   up_genes = `tail -#{params[:displayed_nber_genes].to_i} #{file}`.split("\n").reverse.map{|l| l.split("\t")}.select{|t| t[7].to_f <= params[:fdr_threshold].to_f}
      
      up_genes = []
      res.reverse.each do |t|
       # t = l.split("\t")
        if t[7] != 'NA' and t[5] != 'NA' and t[7].to_f <= params[:fdr_threshold].to_f and t[5].to_f >= @log2fc_threshold
          break if t[5].to_f < 0
          up_genes.push t
          break if up_genes.size == params[:displayed_nber_genes].to_i 
        end
      end

      #      down_genesets = []
      #      up_genesets = []
      #      down_genesets = h_ge_data['down'].first(10)
      #      up_genesets = h_ge_data['up'].first(10)

      tmp_res = [r.id, h_attrs_by_run_id[r.id]["group_ref"], h_attrs_by_run_id[r.id]["group_comp"],  up_genes, down_genes, @h_ge[r.id], h_attrs_by_run_id[r.id]["groups"][0]['run_id'].to_i]
      @res.push(tmp_res)      
    end
    
  end
  
  def cluster_comparison
    
    @project_dir =  Pathname.new(APP_CONFIG[:user_data_dir]) + @project.user_id.to_s + @project.key
  
    [:run_id1, :run_id2, :op].map{|e| session[:clust_comparison][@project.id][e] = params[e]}

    @res = []
    p = session[:clust_comparison][@project.id]
    @log = "e"
    @vals = []
    @h_clusters = {}
    @h_runs = {}
    if p[:run_id1] and p[:run_id2] and p[:op]
      @log += 'bla'
      list_run_ids = [p[:run_id1], p[:run_id2]]
      Run.where(:id => list_run_ids).all.map{|r| @h_runs[r.id.to_s] = r}
      annots = Annot.where(:run_id => list_run_ids).all
      @h_annots={}
      annots.map{|a| @h_annots[a.run_id.to_s] = a}
      
      @list_cats = []
      list_run_ids.each do |e|
        @log += e
        #  cats = Basic.safe_parse_json(@h_annots[e].categories_json, {}).keys.map{|e| e.to_i}
        cats = Basic.safe_parse_json(@h_annots[e].list_cat_json, [])
        @list_cats.push cats#.map
        loom_file = @project_dir + @h_annots[e].filepath      
        @cmd = "java -jar #{APP_CONFIG[:local_asap_run_dir]}/ASAP.jar -T ExtractMetadata -loom #{loom_file} -meta \"#{@h_annots[e].name}\" -names"
        tmp_res = Basic.safe_parse_json(`#{@cmd}`, {})
        h_vals = {}
        cats.each do |cat|
           h_vals[cat] = []
        end
        #        if tmp_res['list_meta'] and meta = tmp_res['list_meta'][0]
        tmp_res['values'].each_index do |i|
          h_vals[tmp_res['values'][i]].push(tmp_res['cells'][i]) 
        end
        @vals.push(h_vals)
        #        end
      end

      if p[:op] == "1" 
        
        @list_cats[0].each_index do |i| 
          @res[i] = []
          set1 = @vals[0][@list_cats[0][i]]
          if set1
            @list_cats[1].each_index do |j|
              set2 = @vals[1][@list_cats[1][j]]
              @res[i][j] = set1 - set2
            end
          end
        end
      elsif p[:op] == "2" 
        @list_cats[0].each_index do |i|
          @res[i] = []
          set1 = @vals[0][@list_cats[0][i]]
          @list_cats[1].each_index do |j|
            set2 = @vals[1][@list_cats[1][j]]
            @res[i][j] = set2 - set1
          end
        end
      else
        @list_cats[0].each_index do |i|
          @res[i] = []
          set1 = @vals[0][@list_cats[0][i]]
          @list_cats[1].each_index do |j|
            set2 = @vals[1][@list_cats[1][j]]
            @res[i][j] = set1 & set2
          end
        end        
      end
      
    end
    
    
    
    render :partial => "cluster_comparison_results"
  end
  
  
  def filter_de annots, type
#    @log4 = annots.to_json
    @log2 = ''
    if type == 'de_results'
      @h_de_filters = Basic.safe_parse_json(@project.de_filter_json, {})
    else
      @h_de_filters = session[:tmp_de_filter][@project.id]
    end
    @ts = [] 
    #    start_time = Time.now
    
    #  @log2 += 'blablablabla'

    h_ensembl_ids = {}
    h_ensembl_ids_by_loom_path = {}
    h_gene_names_by_loom_path = {}
    # store_run_ids_to_do = annots.select{|annot| !File.exist? @project_dir + 'de' + annot.id.to_s + 'output.txt'}.map{|annot| annot.store_run_id}
    # store_runs = Run.where(:id => store_run_ids_to_do).all
    h_annots_by_loom_path = {}
#   @log4= "-" + annots.to_json
    @log4 =''
    @log7 = annots.size.to_s
    
#    @log4=  "-" + output_txt_filename
    annots_to_do = annots.select{|annot| 
      output_txt_filename = @project_dir + 'de' + annot.run_id.to_s + 'output.txt'; 
  #    @log7+= output_txt_filename.to_s
  #    @log4+=output_txt_filename.to_s
      (!File.exist? output_txt_filename or File.size(output_txt_filename) == 0)
    }
    annots_to_do.each do |annot|
      h_annots_by_loom_path[annot.filepath]||=[]
      h_annots_by_loom_path[annot.filepath].push annot
    end
    @h_genes = {}
#    @log+=annots_to_do.to_json
    #    @log+= 'bli'
    #   loom_paths.each do |loom_path|
    #   store_runs.each do |store_run|
    #  @ensembl_ids = nil
    # @log2 += annots_to_do.to_json
    #    @log += annots_to_do.to_json
    loom_paths = annots_to_do.map{|a| a.filepath}.uniq
    loom_paths.each do |loom_path|
      #    @ensembl_ids = nil
#      gene_names = nil
      #      store_run_step = store_run.step
      #      output_file = @project_dir + store_run_step.name
      #      output_file += store_run.id.to_s if store_run_step.multiple_runs == true
      #      output_file += 'gene_list.txt'
      # loom_path = annot.filepath
      @log += loom_path
      ## Check if at least one file is not found
      to_compute = 0
      h_annots_by_loom_path[loom_path].each do |annot|
        output_file = @project_dir + 'de' + annot.run_id.to_s + 'output.txt' 
        if !File.exist?(output_file) or File.size(output_file) == 0
          to_compute = 1
          break
        end
      end
      @log += "to_compute:" + to_compute.to_s
      if to_compute == 1
        h_ensembl_ids[loom_path] = {}
        loom_file = @project_dir + loom_path
        @cmd = "java -jar #{APP_CONFIG[:local_asap_run_dir]}/ASAP.jar -T ExtractMetadata -loom #{loom_file} -meta /row_attrs/Accession"
        @log += @cmd
        
        h_res = Basic.safe_parse_json(`#{@cmd}`, {})
        #    if h_res['list_meta'] and meta = h_res['list_meta'][0]
        if h_res['values']
          h_res['values'].each do |v|
            h_ensembl_ids[v] = 1        
          end
        end
        #   end
        
        h_ensembl_ids_by_loom_path[loom_path] = h_res['values']
        # @ensembl_ids = h_res['values']
        
        @cmd2 = "java -jar #{APP_CONFIG[:local_asap_run_dir]}/ASAP.jar -T ExtractMetadata -loom #{loom_file} -meta /row_attrs/Gene"
        @log+= @cmd2
        h_res = Basic.safe_parse_json(`#{@cmd2}`, {})
       # h_gene_names_by_loom_path[loom_path] = (h_res['list_meta'] and meta = h_res['list_meta'][0]) ? meta['values'] : []
        h_gene_names_by_loom_path[loom_path] =h_res['values']
      end
    end

    if annots_to_do.size > 0
      ## get genes
    #  Thread.new do
      res = Basic.sql_query2(:asap_data, @h_env['asap_data_db_version'], 'genes', '', 'ensembl_id, organism_id, name, description, alt_names', "organism_id = #{@project.organism_id}")
      res.select{|g| h_ensembl_ids[g.ensembl_id]}.each do |g|
        @h_genes[g.ensembl_id] = g
      end
      
#        ConnectionSwitch.with_db(:data_with_version, @h_env['asap_data_db_version']) do        
#          Gene.select("ensembl_id, organism_id, name, description, alt_names").where(:organism_id => @project.organism_id).all.select{|g| h_ensembl_ids[g.ensembl_id]}.map{|g| @h_genes[g.en#sembl_id] = g}
#        end
    #  end
    end
    
 #   @log7+="/" + annots_to_do.size.to_s
    #    @log4 = annots_to_do.to_json
    annots_to_do.select{|a| File.exist?  @project_dir + 'de' + a.run_id.to_s}.each do |annot|
      loom_path = annot.filepath
      loom_file = @project_dir + loom_path
      output_file =  @project_dir + 'de' + annot.run_id.to_s + 'output.txt'
     # cmd = "head -1 #{output_file.to_s}"
      #     @log4+=cmd
#      @log7+='bla'
      if !File.exist?(output_file) or File.size(output_file) == 0  #or `head -1 #{output_file.to_s}`.split("\t").size != 10
        @cmd3 = "java -jar #{APP_CONFIG[:local_asap_run_dir]}/ASAP.jar -T ExtractMetadata --scientific -prec 5 -loom #{loom_file} -meta \"#{annot.name}\""
        @log7+= @cmd3
        #@h_results = {}
        @ensembl_ids = h_ensembl_ids_by_loom_path[loom_path]
        gene_names =  h_gene_names_by_loom_path[loom_path]        
       # @log+= "ensembl_ids: #{@ensembl_ids.to_json}"
       # @log += `#{@cmd3}`
        @h_results = Basic.safe_parse_json(`#{@cmd3}`.force_encoding(Encoding::ISO_8859_1).encode(Encoding::UTF_8), {})
        ##### 3 next lines TO REMOVE when output of Extractmetadata is numbers and not strings  
        if @h_results['values']
          @h_results['values'].each_index do |i|
            @h_results['values'][i] = @h_results['values'][i].map{|e| (e) ? e.to_f : 'NA'} if  @h_results['values'][i] 
          end
        end
        #        @h_results = (h_all_results['list_meta'] and meta = h_all_results['list_meta'][0]) ? meta : {}
        
        # if File.exist? output_file
        File.open(output_file, "w") do |f|
          if @h_results['values'] and @h_results['values'][0] and @h_results['values'][0].size > 0
            f.write (0 .. @h_results['values'][0].size-1).to_a.select{|e| @h_results['values'][0][e]}.sort{|a, b| @h_results['values'][0][a].to_f <=> @h_results['values'][0][b].to_f}.map{|i|
              if @ensembl_ids and @ensembl_ids[i] and g = @h_genes[@ensembl_ids[i]]
                details_genes = [i, g.ensembl_id, g.name, g.alt_names, g.description]
              else
                details_genes = [i, nil, (gene_names) ? gene_names[i] : nil, nil, nil]
              end
              (details_genes + (0 .. 4).map{|vi| 
                 (@h_results['values'][vi][i]) ? (([1, 2].include?(vi) or !@h_results['values'][vi][i].is_a?(Float)) ? 
                                                  @h_results['values'][vi][i] : 
                                                  ((@h_results['values'][vi][i].is_a?(Float) and  @h_results['values'][vi][i].abs > 0.001) ? ("%.3f" % @h_results['values'][vi][i]) : ("%.3e" % @h_results['values'][vi][i]))) : 'NA'}).join("\t")
            }.join("\n") + "\n"
          end
          #   end
        end
      end
    end
      
    #    @ts.push (Time.now - start_time)
    # @cmd4 = "bla"
    
    #    filter_cmd = "echo '" + annots.map{|annot| annot.id}.join("\n") + "' | xargs -P 10 -I {} -c 'rails filter_de[{}]'"
    
    #    annots.each do |annot|
    #            Thread.new do
    
    
    #    filtered_stats_txt_file = (type=='de_results') ? (@project_dir + 'de' + 'filtered_stats.txt') : (@project_dir + 'tmp' + "#{(current_user) ? current_user.id : "1"}_filtered_stats.txt")
#    @log7+= annots.size.to_s
    list_of_run_ids = annots.map{|annot| annot.run_id}
#    @log7+=list_of_run_ids.to_json
    
#    @cmd = 'toto'

    #    logger.debug("BLAAAAA: "+ annots.size.to_s)
    @log7+= annots.size.to_s

    filtered_stats_txt_file = (type=='de_results') ? (@project_dir + 'tmp' + "#{(current_user) ? current_user.id : 1}_de_filtered_stats.txt") : (@project_dir + 'tmp' + "#{(current_user) ? current_user.id : "1"}_ge_form_filtered_stats.txt")
    File.delete(filtered_stats_txt_file) if File.exist? filtered_stats_txt_file
    # !!! store in a text file the result of the parallelized code => cannot keep the values outside of the Parallel block
    
    # to uncomment to benchmark
    # timing_file = @project_dir + 'de' + 'timing_file.txt'
   # @log7=''
    #   start_time = Time.now

    @cmd = "echo '#{list_of_run_ids.join("\n")}' | xargs -P 24 -I '{}' lib/filter_de '#{@project_dir}' #{@h_de_filters['fdr_cutoff']} #{@h_de_filters['fc_cutoff']} #{type} #{(current_user) ? current_user.id : 1} '{}' > #{@project_dir + 'toto.txt'}"
    
    script_file = @project_dir + "tmp" + "#{(current_user) ? current_user.id : 1}_de_script.sh"
    File.open(script_file, "w") do |f2|
      # f2.write(annots.size.to_s)
      f2.write(@cmd)
    end
    
    `sh #{script_file}`
#    `#{@cmd}` #.join("-")

    
#    Parallel.map(annots, in_processes: 10) { |annot| 
#      start_time = Time.now
#      loom_file = @project_dir + annot.filepath
#      
#      #      @cmd4 = "rails filter_de[#{annot.id}]"
#      #      `#{@cmd4}`
#      
#      input_file = @project_dir + "de" + annot.run_id.to_s + "output.txt"
#      ######    log_fc_threshold = Math.log2(@h_de_filters['fc_cutoff']) #### to put back when output of Extractmetadata is numbers and not strings  
#      log_fc_threshold = Math.log2(@h_de_filters['fc_cutoff'].to_f)
#      final_lists = {:down => [], :up => []}
#      final_sorted_lists = {:down => [], :up => []}
#      i_line = 0
#      if File.exist? input_file
#        if type == 'ge_form'
#          File.open(input_file, 'r') do |f|
#            while (l = f.gets) do
#              t = l.chomp.split("\t")
#              ######   if t[6].to_f <= @h_de_filters['fdr_cutoff'] #### to put back when output of Extractmetadata is numbers and not strings                        #                             
#              if t[7] != 'NA' and t[7].to_f <= @h_de_filters['fdr_cutoff'].to_f
#                if t[5].to_f >= 0 and t[5].to_f >= log_fc_threshold
#                  final_lists[:up].push t[0].to_i 
#                elsif t[5].to_f <= 0 and t[5].to_f <= -log_fc_threshold
#                  final_lists[:down].push t[0].to_i 
#                end
#              end
#              i_line+=1
#            end
#          end
#          
#        else
#          File.open(input_file, 'r') do |f|
#            while (l = f.gets) do
#              t = l.chomp.split("\t")
#              ######   if t[6].to_f <= @h_de_filters['fdr_cutoff'] #### to put back when output of Extractmetadata is numbers and not strings
#              if t[7] != 'NA' and t[7].to_f <= @h_de_filters['fdr_cutoff'].to_f
#                if t[5].to_f >= 0 and t[5].to_f >= log_fc_threshold
#                  final_lists[:up].push [i_line, t[5], t[7]]
#                elsif t[5].to_f <= 0 and t[5].to_f <= -log_fc_threshold
#                  final_lists[:down].push [i_line, t[5], t[7]]
#                end
#              end
#              i_line+=1
#            end
#          end
#        end
#      end
#      @log7 += "SIZE: " + final_lists[:up].size.to_s + " : " + i_line.to_s
#      #      final_sorted_lists[:up] = final_lists[:up].reverse
#      #      final_sorted_lists[:down] = final_lists[:down]
#      #      final_sorted_lists[:up] = final_lists[:up].sort{|a, b| b[1] <=> a[1]}
#      #      final_sorted_lists[:down] = final_lists[:down].sort{|a, b| a[1] <=> b[1]}
#      
#      #      final_lists.each_key do |k|
#      #      filename = @project_dir + 'de' + annot.run_id.to_s + "filtered.#{k}.json"
#      if type == 'ge_form'
#        filename = @project_dir + 'tmp' + "#{(current_user) ? current_user.id : 1}_#{annot.run_id}_filtered.json"
#        @log7=filename
#        #if File.exist? filename
#        File.open(filename, 'w') do |f|
#          f.write(final_lists.to_json)
#          #   end
#        end
#      else
#        final_lists.each_key do |k|
#          filename = @project_dir + 'de' + annot.run_id.to_s + "filtered.#{k}.json"
#        #  if File.exist? filename
#          File.open(filename, 'w') do |f|
#            f.write final_lists[k].map{|e| e[0]}.to_json
#          end
#          #  end
#        end
#      end
#      #  end
#      
#      #        @h_stats[annot.run_id.to_s] = {'up' => final_sorted_lists[:up].size, 'down' => final_sorted_lists[:down].size}
#      #      filename = @project_dir + 'de' + 'filtered_stats.txt'
#      File.open(filtered_stats_txt_file, "a") do |f|
#        f.write [annot.run_id, final_lists[:up].size, final_lists[:down].size].join("\t") + "\n"
#      end
#
#        
#        #      filtered_stats_txt_file = @project_dir + 'de' + 'filtered_stats.txt'
#        #      File.open(filtered_stats_txt_file, "r") do |f|
#        #        while (l = f.gets) do
#        #          t = l.chomp.split("\t")
#        #          @h_stats[t[0]] = {:up => t[1], :down => t[2]}
#        #        end
#        #      end
#        
#        #      start_time = Time.now
#        #      @cmd4 = "java -jar #{APP_CONFIG[:local_asap_run_dir]}/ASAP.jar -T FilterDEMetadata -loom #{loom_file} -iAnnot #{annot.name} -fdr #{@h_de_filters['fdr_cutoff']} -fc #{@h_de_filters['fc_cutoff']}"
#        #      @h_results_filtered = JSON.parse(`#{@cmd4}`)
#        #      
#        #      @ts.push (Time.now - start_time)      
#        #      start_time = Time.now
#        #      ## write filtered file                                                                                                  ##                            #                                                                        
#        #      @h_results_filtered.each_key do |k|
#        #        filename = @project_dir + 'de' + annot.run_id.to_s + "filtered.#{k}.json"
#        #        File.open(filename, 'w') do |f|
#        #          f.write @h_results_filtered[k].to_json
#        #        end
#        #        @h_stats[annot.run_id] ||= {}
#        #        @h_stats[annot.run_id][k] = @h_results_filtered[k].size
#        #      end
#        #      @ts.push (Time.now - start_time)
#    
# #      end 
# 
#      # to uncomment to benchmark
#      #      File.open(timing_file, 'a') do |f|
#      #        f.write (Time.now - start_time).to_s + "\n" 
#      #      end
#    }
#    @ts.push (Time.now - start_time)
#    @log7= filtered_stats_txt_file
    #    filtered_stats_txt_file = @project_dir + 'de' + 'filtered_stats.txt'                                                                           
    # @h_stats['6o6o']=  filtered_stats_txt_file
    if File.exist? filtered_stats_txt_file
#      @log7="filtered_stats_txt_file: " + filtered_stats_txt_file
      #   @h_stats['6o6o']= "bla"
      File.open(filtered_stats_txt_file, "r") do |f|                                                                                                 
        while (l = f.gets) do                                                                                                                        
          t = l.chomp.split("\t")                                                                                                                    
          @h_stats[t[0]] = {"up" => t[1].to_i, "down" => t[2].to_i}                                                                                              
        end                                                                                                                                          
      end               
      
      filtered_stats_file = @project_dir + 'tmp' + "#{(current_user) ? current_user.id : 1}_de_filtered_stats.json"
      if type == 'ge_form'
        filtered_stats_file = @project_dir + 'tmp' + "#{(current_user) ? current_user.id : 1}_ge_form_filtered_stats.json"
      end
      File.open(filtered_stats_file, "w") do |f|
        f.write(@h_stats.to_json)
      end
    else
      logger.debug("Cannot find " + filtered_stats_txt_file.to_s)
      #      @log7="#{filtered_stats_txt_file} not found"
    end
    
    
    return @h_stats
    
  end

  def filter_de_results
    get_base_data()
    
    #    params[:step_id] ||= Step.where(:version_id => @project.version_id, :name => 'de').first.id
    params[:step_id ]||=  Step.where(:docker_image_id => @asap_docker_image.id, :name => 'de').first.id
    common_get_step()
    annots = [] 
    @h_results = {}
    @h_stats = {}
    @log = ""
    @ida = session[:input_data_attrs][@project.id][params[:step_id]]
    @project_dir = Pathname.new(APP_CONFIG[:user_data_dir]) + @project.user_id.to_s + @project.key

    if params[:type] == 'de_results'
      annots = Annot.where(:run_id => @runs.map{|r| r.id}).all
      @h_de_filters = Basic.safe_parse_json(@project.de_filter_json, {})
    else
      annots =  Annot.where(:run_id => @ida[params[:attr_name]].map{|e| e[:run_id]}).all
      @h_de_filters = session[:tmp_de_filter][@project.id]
    end

#    @log4 = "--> " + annots.to_json
    
    #    @h_de_filters = Basic.safe_parse_json(@project.de_filter_json, {})
    
    if @h_de_filters != params[:filter] or params[:type] == 'ge_form'
      if params[:type] == 'de_results'
        @project.update_attribute(:de_filter_json, {:fc_cutoff => params[:filter][:fc_cutoff].to_f, :fdr_cutoff => params[:filter][:fdr_cutoff].to_f}.to_json)
      else
         session[:tmp_de_filter][@project.id] = params[:filter]
      end
      # recompute the nbers 
      #    annots.each do |annot|
      #      loom_file = @project_dir + annot.filepath
      #      @cmd = "java -jar #{APP_CONFIG[:local_asap_run_dir]}/ASAP.jar -T FilterDEMetadata -loom #{loom_file} -iAnnot #{annot.name} -fdr #{params[:filter][:fdr_cutoff]} -fc #{params[:filter][:fc_cutoff]} -light#"
      #      @h_results[annot.id] = JSON.parse(`#{@cmd}`)
      #    end
      #    File.open(filtered_stats_file, "w") do |f|
      #       f.write(@h_results.to_json)
      #    end
      @log += 'bla'
      @h_stats = filter_de(annots, params[:type])
      #      annots.each do |annot|
      #        loom_file = @project_dir + annot.filepath
      #        @cmd = "java -jar #{APP_CONFIG[:local_asap_run_dir]}/ASAP.jar -T FilterDEMetadata -loom #{loom_file} -iAnnot #{annot.name} -fdr #{params[:filter][:fdr_cutoff]} -fc #{params[:filter][:fc_cutoff]}"
      #        @h_results = JSON.parse(`#{@cmd}`)
      #        ## write filtered file
      #        @h_results.each_key do |k|
      #          filename = @project_dir + 'de' + annot.run_id.to_s + "filtered.#{k}.json"          
      #          #       @h_results[annot.run_id].each_key do |k|
      #          @h_stats[annot.run_id] ||= {}
      #          @h_stats[annot.run_id][k] = @h_results[k].size 
      #        end
      #      end
      #end
      #      File.open(filtered_lists_file, "w") do |f|
      #        f.write(@h_results.to_json)
      #      end
      #      File.open(filtered_stats_file, "w") do |f|
      #        f.write(@h_stats.to_json)
      #      end
      
    end
    
#    render :text => "refresh('step_container', '#{get_step_project_path(@project.id, :step_id => 6)}', {loading:'fa-2x'})" #:partial => 'de_table'
     if params[:type] == 'de_results'
       render :partial => 'filter_de_results'
     elsif params[:type] == 'ge_form'
       @h_runs = {}
       runs = Run.where(:id => @ida[params[:attr_name]].map{|e| e[:run_id]}).all
       runs.map{|r| @h_runs[r.id] = r}
       render :partial => 'ge_filtered_de', :locals => {:attr_name => params[:attr_name]}
       #       render :partial => 'attribute', :locals => {:attr_name => params[:attr_name], :horiz_element => horiz_element}
     end
  end

  def filter_ge runs, type, to_compute
    project_dir =  Pathname.new(APP_CONFIG[:user_data_dir]) + @project.user_id.to_s + @project.key
    ge_dir = project_dir + 'ge'
    h_stats = {}
    @h_ge_filters = Basic.safe_parse_json(@project.ge_filter_json, {})
    
    @headers = []
    h_headers = {}

   # to_compute = 0
   # h_annots_by_loom_path[loom_path].each do |annot|
   #   output_file = @project_dir + 'de' + annot.run_id.to_s + 'output.txt'
   #   if !File.exist?(output_file) or File.size(output_file) == 0
   #     to_compute = 1
   #     break
   #   end
   # end


    @successful_runs = @runs.select{|r| r.status_id == 3}
    first_run = @successful_runs.first
    if first_run
      result_filename = ge_dir + first_run.id.to_s + "output.json"
      if File.exist? result_filename
        h_output = Basic.safe_parse_json(File.read(result_filename), {})
        ### define header once for all                                                                                                                                                                                            
        if @headers.size == 0
          @headers = h_output['headers']
          @headers.each_index do |i|
            h_headers[@headers[i]] = i
          end
        end
        
        filtered_stats_file = project_dir + 'tmp' + "#{(current_user) ? current_user.id : 1}_ge_filtered_stats.json" #+ 'ge' + 'filtered_stats.json'
        filtered_stats_txt_file = project_dir + 'tmp' + "#{(current_user) ? current_user.id : 1}_ge_filtered_stats.txt" #'ge' + 'filtered_stats.txt'
        # @log = '' #filtered_stats_file
        if File.exist? filtered_stats_file
          if to_compute == 0
            h_stats = Basic.safe_parse_json(File.read(filtered_stats_file), {})
            #     @log+= h_stats.to_json
          end
          # File.delete(filtered_stats_txt_file) if File.exist? filtered_stats_txt_file
        end
        File.delete(filtered_stats_txt_file) if File.exist? filtered_stats_txt_file
        
        runs_to_compute = @successful_runs.select{|r| !h_stats[r.id.to_s]}
        #  @log += 'kkk' + to_compute.to_s + "-" + h_stats.to_json + runs_to_compute.map{|e| e.id}.to_s
        if runs_to_compute.size > 0
          
          @cmd = "echo '#{runs.map{|r| r.id}.join("\n")}' | xargs -P 24 -I '{}' lib/filter_ge '#{@project_dir}' #{@h_ge_filters['fdr_cutoff']} ge_results #{(current_user) ? current_user.id : 1} '{}' > #{@project_dir + 'toto_ge.txt'}"
          logger.debug("ge_filter cmd : #{@cmd}")
#          #        
          script_file = @project_dir + "tmp" + "#{(current_user.id) ? current_user.id : 1}_ge_script.sh"
          File.open(script_file, "w") do |f2|
            f2.write(@cmd)
          end
          
          `sh #{script_file}`
          


#          #@log += 'COMPUTE'
#          Parallel.map(runs_to_compute, in_processes: 10) { |run|
#            #@runs.each_index do |run_i|
#            # run = @runs[run_i]
#            # h_stats[run.id.to_s]={}
#            result_filename = ge_dir + run.id.to_s + "output.json"
#            h_output = Basic.safe_parse_json(File.read(result_filename), {})
#            
#            #            h_stats[run.id] = result_filename + "-->" + h_output.to_json.first(100)
#            h_lists = {:up => [], :down => []}
#            h_lists.each_key do |k|
#              if  h_output[k.to_s]
#                h_output[k.to_s].each do |e|
#                  if e[h_headers['fdr']] <= @h_ge_filters['fdr_cutoff'].to_f
#                    h_lists[k].push e 
#                  else
#                    break
#                  end
#                end
#              end
#            end
#            
#            File.open(filtered_stats_txt_file, "a") do |f|
#              f.write [run.id, h_lists[:up].size, h_lists[:down].size].join("\t") + "\n"
#            end
#            
#          }
        end
        
        if File.exist? filtered_stats_txt_file
          File.open(filtered_stats_txt_file, "r") do |f|
            while (l = f.gets) do
              t = l.chomp.split("\t")
              h_stats[t[0]] = {"up" => t[1].to_i, "down" => t[2].to_i}
            end
          end
          
          File.open(filtered_stats_file, "w") do |f|
            f.write(h_stats.to_json)
          end
          
        end
      end
    end
    
    return h_stats
  end
  
  def filter_ge_results
    get_base_data()
#    params[:step_id] ||= Step.where(:version_id => @project.version_id, :name => 'ge').first.id
    params[:step_id] ||= Step.where(:docker_image_id => @asap_docker_image.id, :name => 'ge').first.id
    common_get_step()
    annots = []
    @h_results = {}
    @h_stats = {}
    @log = ""
    @ida = session[:input_data_attrs][@project.id][params[:step_id]]
    @project_dir = Pathname.new(APP_CONFIG[:user_data_dir]) + @project.user_id.to_s + @project.key

    if params[:type] == 'ge_results'
      @h_ge_filters = Basic.safe_parse_json(@project.ge_filter_json, {})
    end

    @log4 = @annots.to_json

    if @h_ge_filters != params[:filter]
      to_compute = 0
      if params[:type] == 'ge_results'
        if @project.ge_filter_json != {'fdr_cutoff' => params[:filter][:fdr_cutoff].to_f}.to_json
          @project.update_attribute(:ge_filter_json, {:fdr_cutoff => params[:filter][:fdr_cutoff].to_f}.to_json)
         # @log += 
          to_compute = 1
        end
      end
      @log += 'bla'
      @h_stats = filter_ge(@runs, params[:type], to_compute)
    end
    if params[:type] == 'ge_results'
      render :partial => 'filter_ge_results'
    end
  end

  
  def get_commands

    get_base_data()
    get_dashboards()

    version = (@project.version_id) ? @project.version : nil
    if version
      h_env = Basic.safe_parse_json(version.env_json, {})
      
      docker_name = "#{h_env['docker_images']['asap_run']['name']}:#{h_env['docker_images']['asap_run']['tag']}"
      asap_data_db = "asap_data_v#{h_env['asap_data_db_version']}"

      @list_cmds= []

     #    @list_cmds.push("export ASAP_RUN_DIR=./path_to_asap_run")    
      @list_cmds.push("## This script contains all commands executed in the PROJECT #{@project.key} and can be run again using the ASAP_run docker (https://hub.docker.com/layers/fabdavid/asap_run)")
      @list_cmds.push("echo '*******************Reproducing analysis of PROJECT #{@project.key}" + ((@project.public) ?  " / ASAP#{@project.public_id}" : "")  + "**********************'")
      @list_cmds.push("echo '***************************************************************************************'")
     # @list_cmds.push("## Manually create a directory ASAP_PROJECTS_DIR and change the owner of the file to 1006:1006 (UID:GID)")
      @list_cmds.push("## CONFIGURATION - Next lines until the separator can be configured to adapt to your setup")
      @list_cmds.push("export ASAP_PROJECTS_DIR=/asap_projects ## change this to write analysis results there (there will be subdirectory for each project key).")
      # @list_cmds.push("## If the project is public, everything should work automatically from here; If the project is private, one needs to download the Inital Loom file from the Report section of the project (Loom file generated after the parsing step) and to save it is the $LOOM_DIR/")      
      @list_cmds.push("export LOOM_DIR=$ASAP_PROJECTS_DIR/loom_files")
      @list_cmds.push("export ASAP_DATA_DB_HOST=localhost; export ASAP_DATA_DB_PORT=5432")
      @list_cmds.push("export PSQL_DIR=/usr/pgsql-10/bin")
      @list_cmds.push("## =========================================================\n")
  #    @list_cmds.push("export ASAP_DATA_DB_NAME=#{asap_data_db}")
      @list_cmds.push("export PROJECT_DIR=$ASAP_PROJECTS_DIR/#{@project.key}")

      @list_cmds.push("docker run --entrypoint '/bin/sh' --rm -v $ASAP_PROJECTS_DIR:$ASAP_PROJECTS_DIR #{docker_name} -c \"mkdir -p $LOOM_DIR; chmod 777 $LOOM_DIR\"")
      if @project.public == true
        @list_cmds.push("echo 'This project is PUBLIC => Nothing to do'")
      else
        @list_cmds.push("echo 'This project is PRIVATE => Please download the Inital Loom file from the Report section of the project (Loom file generated after the parsing step) and save it in LOOM_DIR'")
        @list_cmds.push("read -p 'When ready press any key to continue... ' -n1 -s")
      end

      ## get docker images
      @list_cmds.push("## Pull docker images")
      h_env['docker_images'].each_key do |docker_name|
        tmp_docker_name = "#{h_env['docker_images'][docker_name]['name']}:#{h_env['docker_images'][docker_name]['tag']}"
        @list_cmds.push("docker pull #{tmp_docker_name}")
      end
      
      ##get postgresql database
      asap_data_db_url = APP_CONFIG[:server_url] + "/dumps/#{asap_data_db}.sql.gz"
      @list_cmds.push("if ! psql -lqt | cut -d \| -f 1 | grep -qw #{asap_data_db}; then echo 'Create database #{asap_data_db}'; echo '$PSQL_DIR/createdb -p $ASAP_DATA_DB_PORT #{asap_data_db}'; $PSQL_DIR/createdb -p $ASAP_DATA_DB_PORT #{asap_data_db}; echo 'wget -qO - #{asap_data_db_url} | gunzip | grep -v \'AS integer\' | $PSQL_DIR/psql -p $ASAP_DATA_DB_PORT #{asap_data_db}'; wget -qO - #{asap_data_db_url} | gunzip | grep -v \'AS integer\' | $PSQL_DIR/psql -p $ASAP_DATA_DB_PORT #{asap_data_db}; fi")

#      @list_cmds.push("export ASAP_PROJECTS_DIR=./ ## change this to write your analysis results somewhere else. This directory should be writable for UID:GID 1006:1006")
#      @list_cmds.push("# chmod -R 777 $ASAP_PROJECTS_DIR")
#      @list_cmds.push("export PROJECT_DIR=$ASAP_PROJECTS_DIR/#{@project.key}")

      @list_cmds.push("docker run --entrypoint '/bin/sh' --rm -v $ASAP_PROJECTS_DIR:$ASAP_PROJECTS_DIR #{docker_name} -c \"mkdir -p $PROJECT_DIR\"")
      #    if parsing_run = Run.where(:project_id => @project.id, :step_id => 'parsing').first and parsing_run.status_id == 3
      #      operation = "Download initial input file"
      #      @list_cmds.push("## #{operation}")
      #      @list_cmds.push("echo '-> #{operation}'")
      #      @list_cmds.push("wget -O $PROJECT_DIR/input.#{@project.extension} '#{APP_CONFIG[:server_url]}/projects/#{@project.key}/get_file?filename=input.#{@project.extension}'")
      #    end
      
      project_dir =  Pathname.new(APP_CONFIG[:user_data_dir]) + @project.user_id.to_s + @project.key
      
      ## parsing need to have the docker ASAP_data_vX
#      @list_cmds.push("## Parsing")
      
#      p = JSON.parse(@project.parsing_attrs_json) if @project.parsing_attrs_json
#      opts = []
#      opts.push({'opt' => "-sel", 'value' => p['sel_name']}) if p['sel_name']
#      opts.push({'opt' => "-col", 'value' => p["gene_name_col"]}) if p["gene_name_col"]
#      opts.push({'opt' => "-d", 'value' => p["delimiter"]}) if p["delimiter"] and p['delimiter'] != ''
#      opts.push({'opt' => "-header", 'value' => ((p['has_header'] and p['has_header'].to_i == 1) ? 'true' : 'false')}) if  p['has_header']
#      opts += [
#               {'opt' => "-ncells", 'value' => p["nber_cols"]},
#               {'opt' => "-ngenes", 'value' => p["nber_rows"]},
#               {'opt' => "-type", 'value' => p["file_type"]},
#               {'opt' => '-T', 'value' => "Parsing"},
#               {'opt' => "-organism", 'value' => @project.organism_id},
#               {'opt' => "-o", 'value' => "$PROJECT_DIR"},
#               {'opt' => "-f", 'value' => filepath},
#               {'opt' => '-h', 'value' => db_conn}
#              ]
#      
#      mem = p["nber_cols"].to_i * p["nber_rows"].to_i * 128 / (31053 * 1474560) # project sample = gi6qfz    
#      h_cmd_parse = {
#        'host_name' => "localhost",
#        'time_call' => h_env["time_call"].gsub(/\#output_dir/, "$PROJECT_DIR"),
#        'program' => "java -jar lib/ASAP.jar",  #(mem > 10) ? "java -Xms#{mem}g -Xmx#{mem}g -jar /srv/ASAP.jar" : 'java -jar /srv/ASAP.jar',                             
#        'opts' => opts,
#        'args' => []
#      }
      
#      output_file = "$PROJECT_DIR/output.loom"
#      output_json = "$PROJECT_DIR/output.json"
      
#      cmd_parse = Basic.build_cmd(h_cmd_parse)
#      @list_cmds.push(cmd_parse)

      list_dirs = []
      Step.where(:id => @project.runs.sort.map{|run| run.step_id}.uniq).all.each do |step|
        step_dir =  project_dir + step.name
        list_dirs.push "$PROJECT_DIR/" + step.name + "/"
        #        @list_cmds.push("docker run --network=asap2_asap_network --entrypoint '/bin/sh' --rm -v $ASAP_PROJECTS_DIR:$ASAP_PROJECTS_DIR   fabdavid/asap_run:v2 -c \"mkdir #{local_step_dir}\"")
      end
      mkdir_cmd = list_dirs.map{|d| "mkdir -p #{d}"}.join(" && ") 
      @list_cmds.push("docker run --entrypoint '/bin/sh' --rm -v $ASAP_PROJECTS_DIR:$ASAP_PROJECTS_DIR  #{docker_name} -c \"#{mkdir_cmd}\"")

      @list_cmds.push("echo 'Loading parsed Loom file...'")
#      @list_cmds.push("docker run --network=asap2_asap_network --entrypoint '/bin/sh' --rm -v $ASAP_PROJECTS_DIR:$ASAP_PROJECTS_DIR #{docker_name} -c \"mkdir $PROJECT_DIR/parsing\"")
      if @project.public_id != nil
        @list_cmds.push("docker run --entrypoint '/bin/sh' --rm -v $ASAP_PROJECTS_DIR:$ASAP_PROJECTS_DIR #{docker_name} -c \"wget -qO $PROJECT_DIR/parsing/output.loom '#{APP_CONFIG[:server_url]}/projects/#{@project.key}/get_file?filename=parsing/output.loom'\"")
      else
         @list_cmds.push("docker run --entrypoint '/bin/sh' --rm -v $ASAP_PROJECTS_DIR:$ASAP_PROJECTS_DIR #{docker_name} -c \"ln -s #{@project.key}_parsing_output.loom parsing/output.loom\"")
      end

#      @h_std_methods = {}
#      StdMethod.where(:version_id => @project.version_id).all.map{|s| @h_std_methods[s.id] = s}
      get_std_methods()
      
      @project.runs.sort.select{|r| r.step_id != 1}.each do |run|
        step = run.step
        step_dir =  project_dir + step.name
        local_step_dir = "$PROJECT_DIR/" + step.name + "/"
        std_method = run.std_method
        h_res = Basic.get_std_method_attrs(std_method, step)
        h_attrs = h_res[:h_attrs]
        h_global_params = h_res[:h_global_params]
        
        output_dir = (step.multiple_runs == true) ? (step_dir + run.id.to_s) : step_dir
        local_output_dir = ((step.multiple_runs == true) ? (local_step_dir + run.id.to_s) : local_step_dir) + "/"
        @list_cmds.push("docker run --entrypoint '/bin/sh' --rm -v $ASAP_PROJECTS_DIR:$ASAP_PROJECTS_DIR #{docker_name} -c \"mkdir -p #{local_output_dir}\"")
        
        h_cmd = Basic.safe_parse_json(run.command_json, {})
        if h_cmd['docker_call']
          h_cmd['docker_call'].gsub!("-v /srv/asap_run/srv:/srv", "")
          h_cmd['docker_call'].gsub!("/data/asap2:/data/asap2", "$ASAP_PROJECTS_DIR:$ASAP_PROJECTS_DIR")
          h_cmd['docker_call'].gsub!("--network=asap2_asap_network", "--net=host")
        end
        h_cmd['time_call'] = nil
        ['opts', 'args'].each do |e|
          if h_cmd[e]
            h_cmd[e].each_index do |i|
              h_cmd[e][i]['value'] = h_cmd[e][i]['value'].to_s.gsub(project_dir.to_s, "$PROJECT_DIR")
            end
          end
        end
        
        h_attrs.each_key do |k|
          if filename = h_attrs[k]['write_in_file']                                                                                                                         
            filepath = output_dir + filename
            local_filepath = local_output_dir + filename
            operation = "writing file #{local_filepath}"
            @list_cmds.push("## " + operation)
            @list_cmds.push("echo '-> #{operation}'")
            @list_cmds.push("docker run --network=asap2_asap_network --entrypoint '/bin/sh' --rm -v $ASAP_PROJECTS_DIR:$ASAP_PROJECTS_DIR #{docker_name} -c \"echo '#{File.read(filepath)}' > #{local_filepath}\"")
          end                    
        end
        
        h_run_attrs = (run.attrs_json) ? Basic.safe_parse_json(run.attrs_json, {}) : {}
       ## get std_method details                                     
        h_std_method_attrs = get_std_method_details([run])
        operation = "Running #{@h_steps[run.step_id].label} [#{run.id}] [#{display_run_short_txt(run)}] (#{display_run_attrs_txt(run, h_run_attrs, h_std_method_attrs)})"
        @list_cmds.push("## " + operation)
        @list_cmds.push("echo '-> #{operation}'")
        @list_cmds.push(Basic.build_cmd(h_cmd).gsub(project_dir.to_s, "$PROJECT_DIR").gsub(/postgres\:\d+\/asap2_data_v\d+/, ('$ASAP_DATA_DB_HOST:$ASAP_DATA_DB_PORT/' + asap_data_db)))
        @list_cmds.push("")
          
      end
      
      send_data @list_cmds.join("\n"), :filename => "ASAP_analysis_#{@project.key}.sh"
    end
  end
  
  def get_base_data
    @h_steps = {}
    @h_step_id_by_name = {}
    @h_steps_by_name = {}
#    Step.where(:version_id => @project.version_id).all.map{|s| @h_steps[s.id]=s; @h_steps_by_name[s.name]=s; @h_step_id_by_name[s.name]=s.id}
     Step.where(:docker_image_id => @asap_docker_image).all.map{|s| @h_steps[s.id]=s; @h_steps_by_name[s.name]=s; @h_step_id_by_name[s.name]=s.id}
    @h_statuses={}
    @h_statuses_by_name = {}
    Status.all.map{|s| @h_statuses[s.id]=s; @h_statuses_by_name[s.name]=s}
#    @h_std_methods = {}
#    StdMethod.all.map{|s| @h_std_methods[s.id] = s}
  end

  def set_lineage_run_ids
    redirect_to :action => 'get_step'
    
  end
  
  def parse
    ### delete all other subsequent analysis    
    Basic.kill_all_runs(@project)
    
    h_data = {}

    ## parse files
    @project.parse_files h_data
 
    render :nothing => true, :body => nil
  end
  
  def parse_form
    @fu_input = Fu.where(:project_key => @project.key).first
    
    ## get the attributes
    @h_attrs = Basic.safe_parse_json(@project.parsing_attrs_json, {})

    render :partial => "form_parsing"
  end
  
  #  def summary
  #    render :partial => 'summary'
  #  end
  
  def get_attr step, std_method
    
    @attrs = []
    
    #  @step = @h_steps[params[:step_id].to_i] #Step.where(:id => h_step[params[:obj_name]]).first                                                                                            
    @ps = ProjectStep.where(:project_id => @project.id, :step_id => step.id).first
    @div_class=nil
    if ['diff_expr', 'clustering'].include? step.name #params[:step_name]                                                                                        
     # @div_class='attr_table'
    elsif ['gene_filtering', 'normalization'].include? step.name #params[:step_name]                                                                    
      @div_class='form-inline'
    end

    #    @obj_inst = StdMethod.find(params[:obj_id])                                                                                                                                             
    h_global_params = Basic.safe_parse_json(step.method_attrs_json, {})
    h_sm_attrs = Basic.safe_parse_json(std_method.attrs_json, {})
  #  @log5 += "METHOD: " + std_method.name
  #  @log5 += h_sm_attrs.to_json
    attrs = h_global_params
    ## complement attributes with global parameters - defined at the level of the step  => DO THE CONTRARY!!                                                                                                     
    #    @log = "bla : #{@attrs.to_json}"
    # if attrs.class != Hash
    #   @log += "bla : #{attrs.to_json}"
    # end
    h_sm_attrs.each_key do |k|
   #   @log5 += "K : #{k}"
      attrs[k]||={}
      h_sm_attrs[k].each_key do |k2|
   #     @log5 +="K2 : #{k2} #{h_sm_attrs[k][k2]}"
        attrs[k][k2] = h_sm_attrs[k][k2]
      end
    end
#    @log5 += "par: " + attrs.to_json
    #    @log += "blou : #{@attrs.to_json}"                                                                                                                                                  
    attr_layout =  Basic.safe_parse_json(std_method.attr_layout_json, {})
    return {:attrs => attrs, :attr_layout => attr_layout}
  end

  def form_cell_filtering

    get_dashboards()

    #    depth.json                   detected_genes.json          mitochondrial_content.json   protein_coding_content.json  ribosomal_content.json 
    project_dir =  Pathname.new(APP_CONFIG[:user_data_dir]) + @project.user_id.to_s + @project.key 
    json_file = project_dir + 'parsing' + 'output.json'
    loom_file = project_dir + 'parsing' + 'output.loom'
  #  browser = (request.user_agent.match(/Chrome/)) ? 'chrome' : 'other'
    #  browser = 'chrome'
    annot_json_file =  project_dir + 'parsing' + "annot.json"
    compressed_annot_json_file =  project_dir + 'parsing' + "compressed_annot.json"
    compressed_zip_annot_json_file = project_dir + 'parsing' + "compressed_zip_annot.json"
#    compressed_data_file = project_dir + 'parsing' + 'compressed_data.json'

    @h_float = {"mito" => 1, "ribo" => 1, "protein_coding" => 1}
    @h_data = {}
    @h_data_json = nil
    #  @h_cmd = {"bla" => compressed_zip_annot_json_file}

    if File.exist? compressed_zip_annot_json_file

      if  @project.nber_cols > 20000
        @h_data_json = File.read(compressed_zip_annot_json_file)
      else
        @h_data = Basic.safe_parse_json(File.read(compressed_zip_annot_json_file), {})
      end
    end
    
    if @h_data.keys.size != 5 or !File.exist?(compressed_zip_annot_json_file) or File.size(compressed_zip_annot_json_file) <= 2 #(browser != 'chrome') ? compressed_annot_json_file : compressed_zip_annot_json_file)
      @h_cmd = {
        "depth" => "java -jar #{APP_CONFIG[:local_asap_run_dir]}/ASAP.jar -T ExtractMetadata -loom #{loom_file} -meta /col_attrs/_Depth", 
        "ribo" => "java -jar #{APP_CONFIG[:local_asap_run_dir]}/ASAP.jar -T ExtractMetadata -prec 1 -loom #{loom_file} -meta /col_attrs/_Ribosomal_Content",
        "mito" => "java -jar #{APP_CONFIG[:local_asap_run_dir]}/ASAP.jar -T ExtractMetadata -prec 1 -loom #{loom_file} -meta /col_attrs/_Mitochondrial_Content",
        "detected_genes" => "java -jar #{APP_CONFIG[:local_asap_run_dir]}/ASAP.jar -T ExtractMetadata -loom #{loom_file} -meta /col_attrs/_Detected_Genes",
        "protein_coding" => "java -jar #{APP_CONFIG[:local_asap_run_dir]}/ASAP.jar -T ExtractMetadata -prec 1 -loom #{loom_file} -meta /col_attrs/_Protein_Coding_Content"
      }
      
      #      @h_json_data = {}      
      # NO COMPRESSION version
      #      File.open(annot_json_file, "w", encoding: 'ascii-8bit') do |fw|
      #        h_data = {}
      #        @h_cmd.each_key do |k|
      #          tmp_json = `#{@h_cmd[k]}`.gsub(/\n/, '')          
      #          if !tmp_json.empty?
      #            h_data[k] = {'values' => JSON.parse(tmp_json)['values'].map{|e| (@h_float[k]) ? (e*10).to_i : e.to_i}}
      #          end
      #        end
      #        fw.write(h_data.to_json)
      #      end
      #### SIMPLE PACKING version  
      #  if browser == 'firefox'
      #    File.open(compressed_annot_json_file, "w", encoding: 'ascii-8bit') do |fw| 
      #      
      #      @h_cmd.each_key do |k|
      #        tmp_json = `#{@h_cmd[k]}`.gsub(/\n/, '')
      #        if !tmp_json.empty?
      #          @h_data[k] = {'values' => Base64.encode64(JSON.parse(tmp_json)['values'].map{|e| (@h_float[k]) ? (e*10).to_i : e.to_i}.pack("S*")).gsub("\n", "") } 
      #        end
      #      end    
      #      fw.write(@h_data.to_json)
      #    end
      #  else
      File.open(compressed_zip_annot_json_file, "w", encoding: 'ascii-8bit') do |fw|
        @h_cmd.each_key do |k|
          tmp_json = `#{@h_cmd[k]}`.gsub(/\n/, '').encode('ASCII', :replace => '0')
          if !tmp_json.empty?
            #            @h_data[k] = {'list_meta' => [{'values' => Base64.encode64( Zlib::Deflate.deflate(Basic.safe_parse_json(tmp_json, {})['values'].map{|e| (@h_float[k]) ? (e*10).to_i : e.to_i}.pack("S*"))).gsub("\n", "")}]}
              @h_data[k] = {'values' => Base64.encode64( Zlib::Deflate.deflate(Basic.safe_parse_json(tmp_json, {})['values'].map{|e| (@h_float[k]) ? (e*10).to_i : e.to_i}.pack("S*"))).gsub("\n", "")}
          end
        end
        fw.write(@h_data.to_json)
      end
      #   end

#      File.open(compressed_annot_json, "w", encoding: 'ascii-8bit') do |fw|
#        fw.write(@h_data.to_json)
        #      fw.write("const FastIntegerCompression = require('/srv/FastIntegerCompression.js/node_modules/fastintcompression')\n")
        #     fw.write("const JSONC = require('/srv/asap2/app/JSONC.js')\n")
        #     fw.write("const Base64 = require('/srv/asap2/app/base64.min.js').Base64\n")
        #     fw.write("const gzip = require('/srv/asap2/app/gzip.js')\n")
        #      fw.write("function ab2str(buf) { return String.fromCharCode.apply(null, new Uint8Array(buf));}\n")
        #      fw.write("var h_data = {}\n")
        #      fw.write(@h_json_data.keys.select{|k| @h_json_data[k]}.map{|k| "h_data.#{k} = ab2str(FastIntegerCompression.compress(#{@h_json_data[k]['values'].map{|e| (h_float[k]) ? (e*10).to_i : e}.to_json}));"}.join("\n"))      
        #      fw.write(@h_json_data.keys.select{|k| @h_json_data[k]}.map{|k| "h_data.#{k} = JSONC.pack(#{@h_json_data[k]['values'].to_json}, true)"}.join("\n")) + "\n"
        #      fw.write(@h_json_data.keys.select{|k| @h_json_data[k]}.map{|k| v = Base64.encode64(@h_json_data[k]['values'].map{|e| (h_float[k]) ? (e*10).to_i : e.to_i}.pack('S*')); "h_data.#{k} = \"#{v}\""}.join("\n") + "\n")
        #       fw.write(@h_json_data.keys.select{|k| @h_json_data[k]}.map{|k| "h_data.#{k} = #{@h_json_data[k]['values'].to_json}"}.join("\n") + "\n")
        #    fw.write("console.log(JSONC.pack(h_data, true))")
        #  fw.write("console.log(h_data)")
#      end
#    else
#      # commented to test
#      #      @h_data = (browser != 'chrome') ? JSON.parse(File.read(compressed_annot_json_file)) : JSON.parse(File.read(compressed_zip_annot_json_file))
#      # @h_data = JSON.parse(File.read(annot_json_file))
#      if  @project.nber_cols > 20000
#        @h_data_json = File.read(compressed_zip_annot_json_file)
#      else
#        @h_data = Basic.safe_parse_json(File.read(compressed_zip_annot_json_file), {})
#      end
      #      @h_data_json = File.read(compressed_annot_json)
    end

   # @step = Step.where(:version_id => @project.version_id, :name => "cell_filtering").first #@h_steps[params[:step_id].to_i]
    @step = Step.where(:docker_image_id => @asap_docker_image.id, :name => "cell_filtering").first #@h_steps[params[:step_id].to_i]
   # @std_method = StdMethod.where(:version_id => @project.version_id, :step_id => @step.id, :obsolete => false).first
    @std_method = StdMethod.where(:docker_image_id => @asap_docker_image.id, :step_id => @step.id, :obsolete => false).first
    @h_method_details = get_attr(@step, @std_method)
   # parsing_step = Step.where(:version_id => @project.version_id, :name => "parsing").first
    @parsing_step = Step.where(:docker_image_id => @asap_docker_image.id, :name => "parsing").first
   # cell_filtering_step = Step.where(:version_id => @project.version_id, :name => "cell_filtering").first
    cell_filtering_step = Step.where(:docker_image_id => @asap_docker_image.id, :name => "cell_filtering").first
   # gene_filtering_step = Step.where(:version_id => @project.version_id, :name => "gene_filtering").first
    gene_filtering_step = Step.where(:docker_image_id => @asap_docker_image.id, :name => "gene_filtering").first
    session[:cell_filtering_store_run_id] = params[:store_run_id]
    @parsing_run = Run.where(:project_id => @project.id, :step_id => @parsing_step.id).first
    session[:cell_filtering_store_run_id]||=@parsing_run.id
    
    @cell_filtering_runs = Run.where(:project_id => @project.id, :step_id => cell_filtering_step.id).all.to_a
    @gene_filtering_runs = Run.where(:project_id => @project.id, :step_id => gene_filtering_step.id).all.to_a
    @annots = Annot.where(:project_id => @project.id, :store_run_id => session[:cell_filtering_store_run_id] || @parsing_run.id, :data_type_id => 3, :dim => 1).all
    @h_annots = {}
    @h_annot_runs = {} 
    @annots.map{|a| @h_annots[a.id] = {:name => a.name}}
    Run.where(:id => @annots.map{|a| a.run_id}).all.map{|r| @h_annot_runs[r.id] = r}
   
    #    @h_labels = {
    #      :protein_coding => "% protein coding genes",
    #      :ribo => "% ribosomal genes",
    #      :mito => "% mitochondrial genes",
    #      :detected_genes => "detected genes",
    #      :depth => "UMI/reads"
    #    }
    
    @list_p = [
               {:name => "depth", :attr_name => 'depth',  :type => :lower, :threshold => 1000, :label => "UMI/reads"},
               {:name => "detected_genes", :attr_name => 'detected_genes', :type => :lower, :threshold => 1000, :label => "detected genes"},
               {:name => "protein_coding", :attr_name => 'protein_coding_content', :type => :lower, :threshold => 80, :label => "% protein coding genes"},
               {:name => "mito", :attr_name => 'mito_content', :type => :greater, :threshold => 20, :label => "% mitochondrial genes"},
               {:name => "ribo", :attr_name => 'ribo_content', :type => :greater, :threshold => 40, :mito => 20, :label => "% ribosomal genes"}
              ]

    @h_p = {}
    @list_p.each do |e|
      @h_p[e[:type]] ||= {}
      @h_p[e[:type]][e[:name]]={:threshold => e[:threshold]}
    end

    #    @h_p = {
    #      :greater => {
    #        :protein_coding => {:threshold => 80},
    #      },
    #      :lower => {
    #        :depth => {:threshold => 1000},
    #        :detected_genes => {:threshold => 1000},
    #        :ribo => {:threshold => 40},
    #        :mito => {:threshold => 20}
    #      }
    #   }

    # @annots.map{|a| @h_steps[a.step_id]}.uniq.each do |step|
    #   @h_dashboard_card[step.id] = JSON.parse(step.dashboard_card_json)
    # end

  end
  
  def form_new_metadata
    render :partial => 'form_new_metadata'
  end

  def form_new_analysis
    @log = ''
    get_base_data()

    @step_id = params[:step_id].to_i
    @step = @h_steps[@step_id]    
    @h_step_attrs = (@step.attrs_json and !@step.attrs_json.empty?) ? Basic.safe_parse_json(@step.attrs_json, {}) : {}

    @h_data_classes={}
    DataClass.all.map{|dc| @h_data_classes[dc.id] = dc}
    
    ## check applicable methods
    runs = Run.where(:project_id => @project.id, :status_id => @h_statuses_by_name['success'].id)
    #    @std_methods = StdMethod.where(:version_id => @project.version_id, :step_id => @step.id, :obsolete => false).all.sort{|a, b| a.name <=> b.name}
    @h_std_methods = {}
#    all_std_methods = StdMethod.where(:version_id => @project.version_id, :obsolete => false).all
    all_std_methods = StdMethod.where(:docker_image_id => @asap_docker_image.id, :obsolete => false).all
    all_std_methods.map{|s| @h_std_methods[s.id]=s}
    
    @std_methods = all_std_methods.select{|e| e.step_id == @step.id}.sort{|a, b| a.name <=> b.name}

    @h_obj_attrs_by_std_method = {}
    @std_methods.map{|s| @h_obj_attrs_by_std_method[s.id] = Basic.safe_parse_json(s.obj_attrs_json, {})}
    
    @h_std_methods_by_name = {}
    @std_methods.map{|s| @h_std_methods_by_name[s.name]=s}
    @log5 = ''
    @h_unavailable_methods = {}
    @std_methods.each do |std_method|
      #   @log5+= "<br/>METHOD:#{std_method.name}<br/>"
      h_res = get_attr(@step, std_method)
      (h_res[:attrs].keys & ['input_matrix', 'input_de']).each do |attr_name|
        #    h_res[:attrs].each_key do |attr_name|
        if h_res[:attrs][attr_name]['valid_types']
          valid_types = h_res[:attrs][attr_name]['valid_types']
          source_steps = h_res[:attrs][attr_name]['source_steps']
          h_constraints = h_res[:attrs][attr_name]['constraints']
          source_step_ids = source_steps.map{|ssn| @h_steps_by_name[ssn].id}
          tmp_runs = runs.select{|run| source_step_ids.include? run.step_id}
          tmp_annots = Annot.where(:ori_run_id => runs.map{|r| r.id}, :ori_step_id => source_step_ids).all
          h_res2 = check_valid_types(@step, tmp_runs, h_res[:attrs][attr_name], tmp_annots) # valid_types, source_steps, h_constraints)
          #  @log += "attr_name: #{attr_name} => " + h_res2[:h_runs].to_json
          #  @log5+="method:#{std_method.name} #{h_res[:attrs][attr_name]['source_steps']}"

          if h_res2[:h_runs].keys.size == 0
            #            @h_unavailable_methods[std_method.id] ||= {}
            @h_unavailable_methods[std_method.id] = h_res2 #[attr_name] = h_res2
            #   @log5+= attr_name + " => " + std_method.id.to_s
          end
        end
      end
    end

    if !@step.has_std_form
    #  begin
      eval("form_#{@step.name}()")
   #   rescue Exception => e
   #     @error = e.message
   #   end
    end
#    @h_runs_by_step = {}

#    @h_res = check_valid_types(runs, @valid_types, @source_steps)
    @req = Req.new

    render :partial => "std_form"

  end

  def check_valid_types step, runs, input_attr, annots #all_valid_types, input_attr #source_steps, h_constraints
    source_steps = input_attr['source_steps']
    h_constraints = input_attr['constraints']
 #   @log = "CHECK_VALID_TYPES: " + h_constraints.to_json
    h_res = {
      :h_attr_outputs => {},
      :valid_step_ids => [],
      :valid_types => input_attr['valid_types'],
      :h_runs => {},
      :h_store_run_ids => {},
      :h_annots => {},
      :h_annots_by_step_id => {}
    }
    #  source_step_ids = @attrs[params[:attr_name]]['source_steps'].map{|ssn| @h_steps_by_name[ssn].id}.select{|sid| @h_runs_by_step[sid]}.sort{|a,b| @h_steps[a].rank <=> @h_steps[b].rank}                  
#    @log += "valid_types: #{valid_types.to_json}<br/>"
#    @log += "source_steps: #{source_steps.to_json}<br/>"
    #   @source_step_id = params[:source_step_id] || source_step_ids.first                                                                                                                       
 #   @log = ""
    # source_step_ids.each do |sid|                                                                                                                                                            
    nber_criteria = input_attr['valid_types'].size #all_valid_types.size 

        @log5="ANNOTS:#{annots.map{|e| e.name}}<br/>"

    ### filter runs with constraints
    if h_constraints
#      @log5= ''
      if h_constraints['in_lineage']
        constraint_params = h_constraints['in_lineage']
        constraint_datasets = constraint_params.select{|attr_name| s =session[:input_data_attrs][@project.id][step.id.to_s] and s[attr_name]}.map{|attr_name| session[:input_data_attrs][@project.id][step.id.to_s][attr_name]}.flatten.uniq
        #    @log = "CONSTRAINT_DATASETS_bla: " + constraint_datasets.to_json
        #    @log += "CONSTRAINT_DATASETS: " +  constraint_datasets.map{|e| e[:run_id]}.to_json
        #  @log += session[:input_data_attrs].to_json
        #  @log += constraint_params.to_json
        constraint_runs = Run.where(:id => constraint_datasets.map{|e| e[:run_id]}).all
        #   @log += "CONSTRAINT_RUNS: " + constraint_runs.to_json 
        lineage_constraint_run_ids = constraint_runs.map{|e2| [e2.id] + e2.lineage_run_ids.split(",").map{|e| e.to_i}}.flatten.uniq
        
        runs = runs.select{|e|
          intersect = e.lineage_run_ids.split(",").map{|e| e.to_i} & lineage_constraint_run_ids
          #      @log +="111 #{e.lineage_run_ids.split(",").to_json} <==> #{lineage_constraint_run_ids.to_json}"                                                                                              
          #     @log +="INTERSECT:#{intersect.size} == #{lineage_constraint_run_ids.size}"
          intersect.size == lineage_constraint_run_ids.size
        }

        #       @log += runs.to_json
      end
       #     @log5=runs.map{|r| r.id}
    
      if h_constraints['in_loom']
        constraint_params = h_constraints['in_loom']
        constraint_datasets = constraint_params.select{|attr_name| s =session[:input_data_attrs][@project.id][step.id.to_s] and s[attr_name]}.map{|attr_name| session[:input_data_attrs][@project.id][step.id.to_s][attr_name]}.flatten.uniq
        constraint_runs = Run.where(:id => constraint_datasets.map{|e| e[:run_id]}).all
         @log5 = " --- " + constraint_runs.to_json + " --- "
        constraint_annots = Annot.where(:run_id => constraint_runs.map{|r| r.id}).all        
        # @log5=annots.map{|a| a.id}
        all_annots =  Annot.where(:store_run_id => constraint_annots.map{|a| a.store_run_id}.uniq).all
        # @log5=all_annots.map{|a| a.id}
        # @log +=  runs.map{|r| [r.id, r.step_id, r.std_method_id]}.to_json + " => " 
        annots = annots.select{|a| all_annots.map{|a2| a2.id}.include? a.id}
      #  runs = runs.select{|r| all_annots.map{|a| a.ori_run_id}.include? r.id}
        # @log5= runs.to_json
        # @log += runs.map{|r| r.id}.to_json
      end
    end
    
    @log5+="ANNOTS2: #{annots.map{|e| e.name}}</br>"

    ## get annots
    #    h_annots = {}
   
#    annots = Annot.where(:run_id => runs.map{|r| r.id}).all
    annots.each do |a|
      
      ### CHECK types
      if a.data_class_ids
        data_classes = a.data_class_ids.split(",").map{|dc_id| @h_data_classes[dc_id.to_i]}
        nber_valid_criteria = 0
        input_attr['valid_types'].each do |valid_types|
          if data_classes.size > 0 and valid_types and
              (intersect = valid_types & data_classes.select{|dc| dc}.map{|dc| dc.name}) and intersect.size > 0
            nber_valid_criteria += 1
          end
        end
        #        @log5+= "#{nber_criteria} == #{nber_valid_criteria}"
        if nber_criteria == nber_valid_criteria
          step_id = (a.sim_step_id) ? a.sim_step_id : a.ori_step_id 
          h_res[:h_annots][step_id] ||= {}
          h_res[:h_annots][step_id][a.ori_run_id] ||= {}
          h_res[:h_annots][step_id][a.ori_run_id][a.store_run_id] ||= {}
          h_res[:h_annots][step_id][a.ori_run_id][a.store_run_id][a.name] = a        
          h_res[:h_annots_by_step_id][step_id]||=[]
          h_res[:h_annots_by_step_id][step_id].push([a.id, a.ori_run_id])
          h_res[:h_store_run_ids][a.store_run_id] = 1
          #      h_res[:h_runs][a.run_id] ||= run
        end
      end
    end
    
    runs = Run.where(:id => annots.map{|a| a.ori_run_id} | h_res[:h_store_run_ids].keys)
    runs.map{|r| h_res[:h_runs][r.id] = r}


    # @log5= all_annots.map{|e| e.id}.to_json
    # @log5 = ''#@h_std_methods.to_json
    
    # @h_std_method_attrs = get_std_method_details(runs)
    
#    runs.each do |run|
#      sid = run.step_id
#      ### add run only if the run has a compatible output
#      h_outputs = Basic.safe_parse_json(run.output_json, {})
#      h_outputs.each_key do |k|
#        files = h_outputs[k].keys.select{|k2|
#          nber_valid_criteria = 0          
#          input_attr['valid_types'].each do |valid_types|
#            nber_valid_criteria += 1 if h_outputs[k][k2]['types'] and valid_types and
#              (intersect = valid_types & h_outputs[k][k2]['types']) and intersect.size > 0
#          end
#          nber_valid_criteria == nber_criteria
#        }
#        dataset_name = k.split(":").last
#        if files.size > 0 or (h_res[:h_annots][run.step_id] and h_res[:h_annots][run.step_id][run.id])
#          h_res[:h_attr_outputs][sid]||={}
#          h_res[:h_attr_outputs][sid][run.id]||=[]
#          h_res[:h_attr_outputs][sid][run.id] += files.map{|f| [k, f]}          
#          h_res[:h_runs][run.id] ||= run
#          #   h_res[:h_annots][run.id] ||= []
#          #   h_res[:h_annots][run.id] += files.map{|f| } 
#        elsif  h_res[:h_store_run_ids][run.id]
#          h_res[:h_runs][run.id] ||= run
#        end
#      end
#    end
 #   runs.each do |run|
 #     h_res[:h_runs][run.id] ||= run
 #   end
    
    h_res[:valid_step_ids] = source_steps.map{|ssn| @h_steps_by_name[ssn].id}.select{|sid| h_res[:h_attr_outputs][sid] or (h_res[:h_annots] and h_res[:h_annots][sid])}.sort{|a,b| @h_steps[a].rank <=> @h_steps[b].rank}
    #   @log += "bla: #{h_res[:valid_step_ids]}"
   # @log5+= "RES: " + source_steps.to_json + "<br/>"
    h_res[:source_step_id] = (params[:source_step_id]) ? params[:source_step_id].to_i : h_res[:valid_step_ids].first
    
    return h_res
  end
  
  def form_select_input_data
    @project_dir = Pathname.new(APP_CONFIG[:user_data_dir]) + @project.user_id.to_s + @project.key
   # @step = Step.where(:name => params[:step_name]).first

#    source_step_id = (params[:source_step_id]) ? params[:source_step_id].to_i : h_res[:valid_step_ids].first 
    @log = ''
    get_base_data()
    @step = @h_steps[params[:step_id].to_i]
    @obj_inst = StdMethod.find(params[:obj_id])
    h_res = get_attr(@step, @obj_inst)
    @attrs = h_res[:attrs]
    @attr_layout = h_res[:attr_layout]
    @h_constraints =  @attrs[params[:attr_name]]['constraints']     
    @valid_types = @attrs[params[:attr_name]]['valid_types']
    @source_steps = @attrs[params[:attr_name]]['source_steps']
    source_step_ids = @source_steps.map{|ssn| @h_steps_by_name[ssn].id}

    lineage_filter()

    ## TODO integrate filter 
    #available_run_ids = ActiveRun.select("run_id").where(:project_id => @project.id, :step_id => source_step_ids, :status_id => @h_statuses_by_name['success']).all.map{|e| e.run_id}

    #    @log += "AVAILABLE: #{available_run_ids.to_json} <BR/> current_filtered: #{@current_filtered_run_ids.to_json}"
    #    @log += "BAD runs: " + Run.where(:id => @current_filtered_run_ids).to_json 
    #runs = (@current_filtered_run_ids & available_run_ids).map{|run_id| @h_all_runs[run_id]}
    #runs = available_run_ids.map{|run_id| @h_all_runs[run_id]}
    runs = Run.where(:project_id => @project.id, :step_id => source_step_ids, :status_id => @h_statuses_by_name['success']).all
    annots = Annot.where(:project_id => @project.id, :ori_step_id => source_step_ids).all | Annot.where(:project_id => @project.id, :sim_step_id => source_step_ids).all
#    ## filter runs based on constraints
#
#    if @h_constraints and @h_constraints['in_lineage']
#      constraint_params = @h_constraints['in_lineage']
#      constraint_datasets = constraint_params.select{|attr_name| session[:input_data_attrs][attr_name]}.map{|attr_name| session[:input_data_attrs][attr_name]}.flatten.uniq
#      constraint_runs = Run.where(:id => constraint_datasets.map{|e| e["run_id"]}).all
#      lineage_constraint_run_ids = constraint_runs.map{|e2| [e2.id] + e2.lineage_run_ids.split(",").map{|e| e.to_i}}.flatten.uniq
#      runs = runs.select{|e| 
#        intersect = e.lineage_run_ids.split(",").map{|e| e.to_i} & lineage_constraint_run_ids
#      #  @log +="111 #{e.lineage_run_ids.split(",").to_json} <==> #{lineage_constraint_run_ids.to_json}"
#        @log +="#{intersect.size} == #{lineage_constraint_run_ids.size}"
#        intersect.size == lineage_constraint_run_ids.size
#      }
#    end
    @log4 = annots
    @h_data_classes={}
    DataClass.all.map{|dc| @h_data_classes[dc.id] = dc}

    std_methods = StdMethod.where(:id => runs.map{|r| r.std_method_id}).all
    @h_std_methods = {}
    std_methods.map{|std_method| @h_std_methods[std_method.id] = std_method} 
    @h_runs_by_step = {}

#    @log = runs.to_json
    @h_res = check_valid_types(@step, runs, @attrs[params[:attr_name]], annots) # @valid_types, @source_steps,  @h_constraints)

    @h_children_run_ids = {}
    @h_lineage_run_ids = {}

    @h_run_res = {}

    tmp_h_children = {}
    @h_res[:h_runs].each_key do |run_id|
 #     @h_run_ids_by_step_id
      run = @h_res[:h_runs][run_id]
      step_dir = @project_dir + @h_steps[run.step_id].name
      output_dir = (@h_steps[run.step_id].multiple_runs == true) ? (step_dir + run.id.to_s) : step_dir
      output_json_file = output_dir + "output.json"
      @h_run_res[run_id] = (File.exist? output_json_file) ? JSON.parse(File.read(output_json_file)) : {} #Basic.safe_parse_json(@h_res[:h_runs][run_id].attrs_json, {})
      lineage_run_ids = run.lineage_run_ids.split(",")      
      @h_lineage_run_ids[run_id] = lineage_run_ids
      lineage_run_ids.each do |parent_run_id|
        tmp_h_children[parent_run_id]||={}
        tmp_h_children[parent_run_id][run_id]=1
      end
    end
    tmp_h_children.each_key do |parent_run_id|
      @h_children_run_ids[parent_run_id] = tmp_h_children[parent_run_id].keys
    end

    ## get run_ids by step_id
    @h_run_ids_by_step_id = {}
    @h_res[:h_attr_outputs].each_key do |sid|
      @h_run_ids_by_step_id[sid] = @h_res[:h_attr_outputs][sid].keys
    end

    ## get std_method details              
    @h_std_method_attrs = get_std_method_details(@h_res[:h_runs].values)

    ## get dashboard cards info for each valid step
    @h_dashboard_card={}
    @h_res[:valid_step_ids].map{|sid| @h_steps[sid]}.each do |step|
      @h_dashboard_card[step.id] = Basic.safe_parse_json(step.dashboard_card_json, {})
    end

    render :partial => 'form_select_input_data'
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

  def clone_replace_attr attr, h_runs, h_annots
    attr.each_key do |k|
      if k == 'run_id'
        attr['run_id'] = (h_runs[attr['run_id'].to_i]) ? h_runs[attr['run_id'].to_i].id : nil
      elsif k == 'annot_id'
        attr['annot_id'] = (h_annots[attr['annot_id'].to_i]) ? h_annots[attr['annot_id'].to_i].id : nil
      else #k == 'output_filename'
        # t = attr['output_filename'].split("/")
        # t[1] = (h_runs[t[1].to_i]) ? h_runs[t[1].to_i].id : nil if t.size == 3
        # attr['output_filename'] = t.join("/")
        if m = attr[k].to_s.match(/\/(\d+)\/#{@project.key}\/\w+?\/(\d+)\/?/)
          user_id = m[1]
          run_id = m[2]
          if h_runs[run_id.to_i]
            attr[k].gsub!(/\/#{run_id}$/, "/#{h_runs[run_id.to_i].id}$")
            attr[k].gsub!(/\/#{run_id}\//, "/#{h_runs[run_id.to_i].id}\/")
            if attr[k].to_s.match(/\/#{@project.key}\//)
              attr[k].gsub!(/\/#{@project.key}\//, "/#{new_project.key}/")
              attr[k].gsub!(/\/#{user_id}\//, "/#{current_user.id}/")
            end
            
          end
        end
        
      end
    end
    return attr
  end

  def clone
 


    if exportable? @project #@project.sandbox == false or admin?                                                                                           
      new_project = @project.dup
      valid_case = 0
      if current_user
        new_project.key = create_key()
        new_project.sandbox = false
        valid_case = 1
      else
        #if ! Project.where(:key => session[:sandbox]).first 
        if p = Project.where(:key => session[:sandbox]).first and editable? p
          delete_project(p)
        end
        if Project.where(:key => session[:sandbox]).count == 0
          new_project.key = session[:sandbox]
          new_project.sandbox = true
          valid_case = 1
        end
      end
      
      if valid_case == 1
        
        @error = ''
        begin
          
          new_project.name += ' cloned'
          new_project.public = false
          new_project.user_id = (current_user) ? current_user.id : 1
          new_project.session_id = (s = Session.where(:session_id => session.id.to_s).first) ? s.id : nil
          new_project.cloned_project_id = @project.id
          new_project.nber_views = 0
          new_project.nber_cloned = 0
          new_project.last_day_session_ids = ''
          new_project.parsing_job_id = nil
          new_project.filtering_job_id = nil
          new_project.normalization_job_id = nil
          new_project.replaced_by_project_key = nil
          new_project.replaced_by_comment = nil
          now = Time.now
          new_project.viewed_at = now
          new_project.created_at = now
          new_project.updated_at = now
          new_project.modified_at = now
          new_project.frozen_at = nil
          new_project.public_at = nil
          new_project.public_id = nil
          new_project.landing_page_json = '{}'
          new_project.save
          
          ##create user dir if doesn't exist yet                                                                                                               
          new_project_dir = Pathname.new(APP_CONFIG[:user_data_dir]) + ((new_project.user_id == nil) ? '0' : new_project.user_id.to_s)
          Dir.mkdir new_project_dir if !File.exist? new_project_dir
          new_project_dir += new_project.key
          project_dir = Pathname.new(APP_CONFIG[:user_data_dir]) + @project.user_id.to_s + @project.key
          if @project.archive_status_id == 3
            Basic.unarchive(@project.key)
          end
          FileUtils.cp_r project_dir, new_project_dir if project_dir != new_project_dir
          
          ## copy runs 
          
          h_runs = {}
          @project.runs.sort{|a, b| a.id <=> b.id}.each do |run|
            new_run = run.dup
            new_run.project_id = new_project.id
            new_run.save
            h_runs[run.id] = new_run
            logger.debug("H_RUNS: #{run.id} => " + new_run.id.to_s)
          end
          
          ## copy files (do not use the fo_id but directly relative path)                                      
          #  h_fos = {}                                                                                                          
          @project.fos.each do |fo|
            new_fo = fo.dup
            new_fo.filepath = fo.filepath.gsub(/#{fo.run_id}/, h_runs[fo.run_id].id.to_s) 
            new_fo.run_id = h_runs[fo.run_id].id
            new_fo.project_id = new_project.id
            new_fo.save
            #    h_fos[fo.id] = new_fo.id                                  
          end
          
          
          ## copy annots
          h_annots = {}
          @project.annots.sort{|a, b| a.id <=> b.id}.each do |annot|
            new_annot = annot.dup
            new_annot.project_id = new_project.id
            new_annot.run_id = h_runs[annot.run_id].id          
            new_annot.filepath = annot.filepath.gsub(/#{annot.store_run_id}/, h_runs[annot.store_run_id].id.to_s)
            new_annot.store_run_id = h_runs[annot.store_run_id].id
            new_annot.ori_run_id = h_runs[annot.ori_run_id].id
            new_annot.save
            h_annots[annot.id] = new_annot
          end
          
          ## copy annot_cell_sets
          @project.annot_cell_sets.each do |ac|
            new_ac = ac.dup
            new_ac.project_id = new_project.id
            new_ac.annot_id = (h_annots[ac.annot_id]) ? h_annots[ac.annot_id].id : nil
            new_ac.save
          end

          
          h_steps = {}
          # Step.where(:version_id => @project.version_id).all.each do |s|
          Step.where(:docker_image_id => @asap_docker_image.id).all.each do |s|
            h_steps[s.id] = s
          end
          
          ## change ids and full_path in all runs 
          @project.runs.each do |run|
            step = h_steps[run.step_id]
            if step
              run_dir = project_dir + step.name
              new_run_dir = new_project_dir + step.name
              new_run = h_runs[run.id]
              logger.debug("NEW_RUN_DIR: " + h_runs[run.id].to_json)
              output_file = new_project_dir + step.name  + "output.log"
              if run.step.multiple_runs == true
                run_dir = project_dir + step.name + run.id.to_s
                new_run_dir = new_project_dir + step.name + h_runs[run.id].id.to_s
                output_file = new_project_dir + step.name + run.id.to_s + "output.log"
              end
              
              ## change directories in output.log => finally just delete the file because it contains too many debugs that cannot be modified
              if File.exist? output_file
                File.delete output_file
                #  content = File.read(output_file)
                #File.open(output_file, 'w') do |f|
                #    #                  f.write(content.gsub(/#{run_dir}/, "#{new_run_dir}"))
                #   if m = content.match(/\/#{@project.key}\/\w+?\/(\d+?)\//)
                #      run_id = m[1]
                #     if h_runs[run_id.to_i]
                ##        content.gsub!(/\/#{run_id}\//, "/#{h_runs[run_id.to_i].id}/")
                #        content.gsub!(/\/#{@project.key}\//, "/#{new_project.key}/")
                #      end
                #    end
                #    f.write(content)
                #  end
              end
              
            
            h_output = Basic.safe_parse_json(run.output_json, {})
            new_h_output = {}
            h_output.each_key do |k|
              # keys_to_delete = []
              new_h_output[k]={}
              h_output[k].each_key do |k2|
                l = k2.split(":")
                t = l[0].split("/")
                if t.size == 3 and run_id = t[1] and h_runs[run_id.to_i]
                  t[1] = h_runs[run_id.to_i].id
                  l[0] = t.join("/")
                  new_k2 = l.join(":")
                  new_h_output[k][new_k2]=h_output[k][k2].dup              
                elsif t.size == 2
                  new_h_output[k][k2]=h_output[k][k2].dup
                end
              end
              #          keys_to_delete.each do |k2|
              #            h_output[k].delete(k2)
              #          end
            end
            new_lineage_run_ids = run.lineage_run_ids.split(",").select{|run_id|  h_runs[run_id.to_i]}.map{|run_id| h_runs[run_id.to_i].id}
            new_parent_run = nil
            if run.run_parents_json
              if parent_run = Basic.safe_parse_json(run.run_parents_json, [])
                
                new_parent_run =[]
                parent_run.each do |p_run|
                  new_parent_run.push({:run_id => (h_runs[p_run["run_id"]]) ? h_runs[p_run["run_id"]].id : nil, :type => p_run["type"], :output_attr_name => p_run["output_attr_name"]})
                end
              end
            end
            new_children_run_ids = run.children_run_ids.split(",").map{|run_id| (tmp_run = h_runs[run_id.to_i]) ? tmp_run.id : nil}.compact
            new_command = Basic.safe_parse_json(run.command_json, {})
            if new_command['container_name']
              t =  new_command['container_name'].split("_").map{|e| (h_runs[e.to_i]) ? h_runs[e.to_i].id : e }          
              new_command['container_name']= t.join("_")
            end
            if new_command['program']
              new_command['program'].gsub!(/\[#{@project.key}\]/, "[#{new_project.key}]/")
            #  new_command['time_call'].gsub!(/#{run_dir.to_s}/, new_run_dir.to_s)
            end
            
              ['time_call', 'exec_stdout', 'exec_stderr'].each do |k|
                if new_command[k]
                  logger.debug("TIME_CALL_DEBUG")
                  logger.debug(run_dir.to_s)
                  logger.debug(new_run_dir.to_s)
                  if m = new_command[k].to_s.match(/\/(\d+)\/#{@project.key}\/\w+?\/(\d+)\/?/)
                    user_id = m[1]
                    run_id = m[2]
                    if h_runs[run_id.to_i]
                      new_command[k].gsub!(/\/#{run_id}$/, "/#{h_runs[run_id.to_i].id}")
                      new_command[k].gsub!(/\/#{run_id}\//, "/#{h_runs[run_id.to_i].id}\/")
                      new_command[k].gsub!(/\/#{@project.key}\//, "/#{new_project.key}/")
                      new_command[k].gsub!(/\/#{user_id}\//, "/#{current_user.id}/")
                    end
                  end             
                  #              new_command['time_call'].gsub!(/\/#{@project.key}\//, "/#{new_project.key}/")
                  #              new_command['time_call'].gsub!(/\/#{run_dir}\//, "/#{h_runs[run_id.to_i].id}/")
                end
              end
              ['args', 'opts'].each do |k|
                if new_command[k]
                  new_command[k].each_index do |i|
                    if m = new_command[k][i]['value'].to_s.match(/\/(\d+)\/#{@project.key}\/\w+?\/(\d+)\/?/)
                      user_id = m[1]
                      run_id = m[2]
                      if h_runs[run_id.to_i]
                        new_command[k][i]['value'].gsub!(/\/#{run_id}\//, "/#{h_runs[run_id.to_i].id}/")
                        new_command[k][i]['value'].gsub!(/\/#{run_id}$/, "/#{h_runs[run_id.to_i].id}")
                      end
                    end
                    if new_command[k][i]['value'].to_s.match(/\/data\/asap2\/users\/(\d+)\/#{@project.key}\//)
                      new_command[k][i]['value'].gsub!(/\/#{@project.key}\//, "/#{new_project.key}/")
                      new_command[k][i]['value'].gsub!(/\/#{user_id}\//, "/#{current_user.id}/")
                    end
                  end
                end
              end
            new_attrs = Basic.safe_parse_json(run.attrs_json, {})
            new_attrs.each_key do |k|
              if new_attrs[k].is_a? Hash
                new_attrs[k] = clone_replace_attr(new_attrs[k], h_runs, h_annots)
              elsif new_attrs[k].is_a? Array
                new_attrs[k].each_index do |i|
                  new_attrs[k][i] = clone_replace_attr(new_attrs[k][i], h_runs, h_annots)
                end
              else
                logger.debug("test_clone: " + new_attrs[k].to_s)
                #/data/asap2/users/1/87qp4i/cell_filtering/127122/output.loom
                if m = new_attrs[k].to_s.match(/\/(\d+)\/#{@project.key}\/\w+?\/(\d+)\/?/)
                  logger.debug("test_clone2") # + new_attrs[k].to_s)
                  user_id = m[1]                                                                                                   
                  run_id = m[2]                                                                                      
                  if h_runs[run_id.to_i]
                     logger.debug("test_clone3") 
                    new_attrs[k].gsub!(/\/#{run_id}\//, "/#{h_runs[run_id.to_i].id}/")  
                     new_attrs[k].gsub!(/\/#{run_id}$/, "/#{h_runs[run_id.to_i].id}")
                  else
                    puts "test_clone: run_id: #{run_id.to_i}" 
                  end
                end
                if new_attrs[k].to_s.match(/\/data\/asap2\/users\/(\d+)\/#{@project.key}\//)
                  new_attrs[k].gsub!(/\/#{@project.key}\//, "/#{new_project.key}/")
                  new_attrs[k].gsub!(/\/#{user_id}\//, "/#{current_user.id}/")
                end

              end
            end
            new_run.update_attributes({
                                        :attrs_json => new_attrs.to_json,
                                        :command_json => new_command.to_json,
                                        :output_json => new_h_output.to_json, 
                                        :lineage_run_ids => new_lineage_run_ids.join(","), 
                                        :run_parents_json => new_parent_run.to_json,
                                        :children_run_ids => new_children_run_ids.join(","),
                                        :cloned_run_id => run.id 
                                      })
          end
        end
        
        ## copy project_steps
        @project.project_steps.sort{|a, b| a.updated_at <=> b.updated_at}.map{|e|
          new_e = e.dup
          new_project.project_steps << new_e
        }
        
        ## copy fus
        @project.fus.map{|e| new_e = e.dup; new_e.update_attribute(:project_key, new_project.key); new_project.fus << new_e}

        ## copy exp_entries
        @project.exp_entries.each do |e|
         # new_e = e.dup
          new_project.exp_entries << e
        end
        
        ## copy provider_projects
        @project.provider_projects.each do |e|
          new_project.provider_projects << e
        end
        
        @log = ''
        ## rename run folders
#        Step.where(:version_id => @project.version_id, :multiple_runs => true).all.each do |s|
        Step.where(:docker_image_id => @asap_docker_image.id, :multiple_runs => true).all.each do |s|
          Run.where(:project_id => @project.id, :step_id => s.id).all.each do |r|
            run_dir = new_project_dir + s.name + r.id.to_s
            new_run_dir = new_project_dir + s.name + h_runs[r.id].id.to_s
            @log += "#{run_dir.to_s} -> #{new_run_dir.to_s}"
            File.rename(run_dir, new_run_dir) if File.exist? run_dir and !File.exist? new_run_dir
          end
        end

        # 2020/02/16 => input file is already a link to fus => keep this link + fu_is in Project object 
        #  ## replace input.[extension] by a link (because cannot be changed)                                                                   
        #  if project_dir != new_project_dir
        #    File.delete new_project_dir + ('input.' + @project.extension)
        #    File.symlink project_dir + ('input.' + @project.extension), new_project_dir + ('input.' + @project.extension)
        #  end
        
        ## update project nber_cloned
        @project.update_attribute(:nber_cloned, @project.nber_cloned + 1) if !admin?

        rescue Exception => e
        @error = (admin?) ? (e.message + "\n" + e.backtrace.to_json) : "Cloning the project failed, please contact us to investigate the issue"
        #new_pp = Project.where(:key => new_project.key)
        #delete_project(new_p)
      end


        if @error != ''
          new_p = Project.where(:key => new_project.key).first
          delete_project(new_p)
          render :partial => 'cloning_error'
        else          
          redirect_to :action => 'show', :key => new_project.key
        end
      else
        
        redirect_to :action => 'show', :key => @project.key
      end
    else
      render :nothing => true, :body => nil
    end

  end
  
  def clone_old

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
      new_project.session_id = (s = Session.where(:session_id => session.id.to_s).first) ? s.id : nil
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
   #   h_genesets = {}
   #    @project.gene_sets.map{|e| 
   #     new_e = clone_obj(new_project, e, new_tmp_dir + 'gene_sets', ".txt")
   #     h_genesets[e.id]=new_e.id
   #     new_e.update_attribute(:ref_id, h_diff_exprs[e.ref_id])
   #     #  new_project.gene_sets << e.dup
   #   }

      @project.project_dim_reductions.map{|e|
        new_e = e.dup
        h_attrs_json = Basic.safe_parse_json(new_e.attrs_json, {})
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
      render :nothing => true, :body => nil
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
      h_attrs = Basic.safe_parse_json(pdr.attrs_json, {})
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
    @attrs = Basic.safe_parse_json(@h_dim_reductions[dr_id].attrs_json, {})
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
    jobs = Run.where(:project_id => @project.id, :step_id => session[:active_step], :status_id => [1, 2, 3, 4]).all.to_a
    jobs.sort!{|a, b| (a.created_at.to_s || '0') <=> (b.created_at.to_s || '0')} if jobs.size > 0
    last_job = jobs.last
    last_update = @project.status_id.to_s + ","
    last_update += [jobs.size, last_job.status_id, last_job.id, last_job.created_at].join(",") if last_job
    return last_update
  end

  def live_upd
    render :partial => 'live_upd'
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
    @h_ori_data = Basic.safe_parse_json(@data_json, {})
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
    @pdr_params = (pdr.attrs_json) ? Basic.safe_parse_json(pdr.attrs_json, {}) : {}
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

    @pdr_params = Basic.safe_parse_json(pdr.attrs_json, {}) #: {}
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

    @pdr_params =  Basic.safe_parse_json(pdr.attrs_json, {})

    ['geneset_type', 'custom_geneset', 'global_geneset'].each do |e|
      session[:viz_params][e] = @pdr_params[e]
    end

    @geneset_names=[]

    ### get data                  
    if File.exist?(tmp_dir + 'output.json')
      @data_json = File.read(tmp_dir + 'output.json')
      @h_ori_data = Basic.safe_parse_json(@data_json, {})
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
      list_genes = Basic.safe_parse_json(File.read(project_dir + 'parsing' + 'gene_names.json'), []) 
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
      h_results = Basic.safe_parse_json(File.read(filename), {}) if File.exist?(filename)
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
#    step_id = params[:step_id].to_i || session[:active_step].to_i
  #  (1 .. @step.id).each do |i|
    t.each do |step_name|
      #      step_name = t[i-1]
      #      step = Step.where(:version_id => @projext.version_id, :name => step_name).first
      tmp_dir = Pathname.new(APP_CONFIG[:user_data_dir]) + @project.user_id.to_s + @project.key + step_name.to_s              
      filename = tmp_dir + "output.json"       
      if File.exist?(filename)
        results_json = File.open(filename, 'r').read #lines.join("\n")                                                                                       
        @all_results[step_name] = Basic.safe_parse_json(results_json, {})
      end
    end
    @results = @all_results[@step.name.to_sym]
 
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

  def get_dashboards 
    ## get dashboard cards info for each valid step                                                                                                                                                             
    @h_dashboard_card={}
   # Step.where(:version_id => @project.version_id).all.each do |step|
    Step.where(:docker_image_id => @asap_docker_image.id).all.each do |step| 
      @h_dashboard_card[step.id] = Basic.safe_parse_json(step.dashboard_card_json, {})
    end

  end

  def get_lineage
    
    @h_std_methods = {}
#    StdMethod.where(:version_id => @project.version_id).all.map{|s| @h_std_methods[s.id] = s}
    StdMethod.where(:docker_image_id => @asap_docker_image.id).all.map{|s| @h_std_methods[s.id] = s}

    get_base_data()
    
    list_cards = []
    run_ids = []
    if params[:run_id]
       run_ids.push params[:run_id].to_i
      run = Run.where(:project_id => @project.id, :id => params[:run_id]).first
      if run and run.lineage_run_ids
        run_ids += run.lineage_run_ids.split(",").map{|e| e.to_i} #Run.where(:project_id => @project.id, :id => run.lineage_run_ids.split(",")).all 
      end
    end
    @bla = run_ids
    @list_runs =  Run.where(:project_id => @project.id, :id => run_ids).all.order(:id)
    @list_runs.push run if params[:include_query_run] and params[:include_query_run] == "1"
    h_runs = {}
    @list_runs.each do |run|
      h_runs[run.id]=run
    end
    if h_runs[params[:run_id].to_i]
      @step = @h_steps[h_runs[params[:run_id].to_i].step_id]
      @h_attrs = (@step.attrs_json and !@step.attrs_json.empty?) ? Basic.safe_parse_json(@step.attrs_json, {}) : {}
    end
    get_dashboards()
    list_cards = create_run_cards(@list_runs, nil)[:run_cards]
    
    render :partial => 'display_card_deck', :locals => {:cards => list_cards, :card_type => 'run'}
    
  end

  def autocomplete_gene_set_items
    @to_render = []
    limit = 100
    @gene_set_items = Basic.sql_query2(:asap_data, @h_env['asap_data_db_version'], 'gene_set_items', '', '*', "gene_set_id = #{params[:gene_set_id]} and lower(name) ~ '#{params[:q].downcase}'")
    all_gene_ids = []
    @gene_set_items.first(limit).sort{|a, b| a.name <=> b.name}.each do |gsi|
      gene_ids = gsi.content.split(",")
      all_gene_ids |= gene_ids
      @to_render.push({:label => gsi.name + " (#{gene_ids.size})", :id => gsi.id, :gene_ids => gene_ids})
    end
    genes = Basic.sql_query2(:asap_data, @h_env['asap_data_db_version'], 'genes', '', '*', "id in (#{all_gene_ids.join(",")})")
    h_genes = {}
    genes.map{|g| h_genes[g.id] = g}
    @to_render.each_index do |i|
      @to_render[i][:gene_names] = @to_render[i][:gene_ids].map{|gid| h_genes[gid].name}
    end
    respond_to do |format|
      format.json {
        render :plain => @to_render.to_json
      }
    end
    
  end

  def autocomplete_genes
    project_dir =  Pathname.new(APP_CONFIG[:user_data_dir]) + @project.user_id.to_s + @project.key
    @to_render = []
    limit = 100
    if params[:annot_id]
      @annot = Annot.where(:id => params[:annot_id]).first
      if @annot
        #        @h_annots[key]
        ##["/row_attrs/Gene", "/row_attrs/Accession"].each do |annot_name|
        #genes_annot = Annot.where(:store_run_id => @annot.store_run_id, :name => annot_name).first
        
        ### ensembl_ids present in the dataset
        #        annot_name = "/row_attrs/Accession"
        #        key = annot_name.split("/")[2].downcase
        #        loom_path =  project_dir + @annot.filepath
        #        @cmd = "java -jar lib/ASAP.jar -T ExtractMetadata -f #{project_dir + 'parsing/output.loom'} -meta #{annot_name}"
        #        logger.debug("CMD: " + @cmd)
        #        @cmd2 = "java -jar lib/ASAP.jar -T ExtractMetadata -f #{loom_path} -meta /row_attrs/_StableID"
        
        h_present_ensembl_ids = {}

        #        h_meta = JSON.parse(`#{@cmd}`)
        #        h_meta_stable_ids = JSON.parse(`#{@cmd2}`)
        #        h_meta_stable_ids['values'].each_index do |i|
        #          h_present_ensembl_ids[h_meta['values'][h_meta_stable_ids['values'][i]]]||= []
        #          h_present_ensembl_ids[h_meta['values'][h_meta_stable_ids['values'][i]]].push(h_meta_stable_ids['values'][i])
        #        end
        
        ## do the queries
        #Thread.new do
        @genes = Basic.sql_query2(:asap_data, @h_env['asap_data_db_version'], 'genes', '', 'ensembl_id, name, alt_names', "organism_id = #{@project.organism_id} and (lower(name) ~ '^#{params[:q].downcase}' or lower(ensembl_id) ~ '^#{params[:q].downcase}'")
        @genes |= Basic.sql_query2(:asap_data, @h_env['asap_data_db_version'], 'genes', '', 'ensembl_id, name, alt_names', "organism_id = #{@project.organism_id} and (lower(alt_names) ~ '^#{params[:q].downcase}'").select{|g|  
          t = g.alt_names.split(",")
          t.map{|e| (e.match(/^#{params[:q]}/)) ? 1 : nil}.compact.size > 0
        }
        
        #        res.each do |gs|
        #          @h_gene_sets[gs.id] = gs
        #        end
        
        #          ConnectionSwitch.with_db(:data_with_version, @h_env['asap_data_db_version']) do
        #            @genes = Gene.select("ensembl_id, name, alt_names").where(["organism_id = ? and (lower(name) ~ ? or lower(ensembl_id) ~ ?)", @project.organism_id, "^#{params[:q].downcase}", "^#{params[:q].downcase}"]).all
        #            @genes |= Gene.select("ensembl_id, name, alt_names").where(["organism_id = ? and lower(alt_names) ~ ?", @project.organism_id, params[:q].downcase]).all.select{|g| 
        #              t = g.alt_names.split(",")
        #              t.map{|e| (e.match(/^#{params[:q]}/)) ? 1 : nil}.compact.size > 0
        #            }
        #          end
        #end

        @genes.first(limit).sort{|a, b| a.name <=> b.name}.each do |g|
          if h_present_ensembl_ids[g.ensembl_id]
            h_present_ensembl_ids[g.ensembl_id].each do |pos|         
              @to_render.push({:label => g.name + ((!g.alt_names.empty?) ? " (#{g.alt_names})" : "") + " [#{g.ensembl_id}] {#{pos}}", :idx => pos})
            end
          end
        end

      else
        @to_render.push({:lable => "Error"})
      end
    else
      @to_render.push({:lable => "Error"})
    end
    respond_to do |format|
      format.json {
      render :text => @to_render.first(limit).to_json
      }
    end
  end

  def extract_metadata

    params[:header]||="1"
    params[:first_col]||="1"
    
    if readable?(@project) and params[:annot_id]
      @annot = Annot.where(:id => params[:annot_id]).first
      project_dir =  Pathname.new(APP_CONFIG[:user_data_dir]) + @project.user_id.to_s + @project.key
      loom_file = project_dir + @annot.filepath
      cmd = ''
      json_data = ''
      content = ''
      ext = "csv"
      if @annot.dim == 3
        cmd = "java -jar #{APP_CONFIG[:local_asap_run_dir]}/ASAP.jar -T ExtractDataset -t PLAIN_TEXT --row-names --col-names --loom #{loom_file} --iAnnot \"#{@annot.name}\""
        logger.debug("CMD:" + cmd)
        #    send_data IO.popen(cmd).read,  type: params[:content_type] || 'text', stream: 'true', buffer_size: '4096', disposition: (!params[:display]) ? ("attachment; filename=" + @project.key  + "_" + @annot.filepath.gsub("/", "_")  + @annot.name.gsub("/", "_") + "." + ext) : ''
        send_data `#{cmd}`,  type: params[:content_type] || 'text', disposition: (!params[:display]) ? ("attachment; filename=" + @project.key  + "_" + @annot.filepath.gsub("/", "_")  + @annot.name.gsub("/", "_") + "." + ext) : ''   
      else
        cmd = "java -jar #{APP_CONFIG[:local_asap_run_dir]}/ASAP.jar -T ExtractMetadata " + ((dt = @annot.data_type and dt.name) ? "-type #{dt.name}" : "") + " -loom #{loom_file} -meta \"#{@annot.name}\" -names"
        json_data = `#{cmd}`
        ext = "tsv"
        
        
        if params[:format] == 'json'
          send_data json_data,  type: params[:content_type] || 'text', disposition: (!params[:display]) ? ("attachment; filename=" + @project.key  + "_" + @annot.filepath.gsub("/", "_")  + @annot.name.gsub("/", "_") + ".json") : ''
        else
          data = Basic.safe_parse_json(json_data, {})
          if @annot.dim == 4
            json_data.gsub!(/\\\\/, "\\")
          end
          data = Basic.safe_parse_json(json_data, {})
          if @annot.dim == 4
            content = data['values'][0]
          elsif @annot.dim != 3
            #  if all_data['list_meta'] and data = all_data['list_meta'].first
            
            final = (params[:header] == '1') ? [["Index", ((@annot.dim == 1) ? "Cell name" : "Gene name")] + Basic.safe_parse_json(@annot.headers_json, {})] : []
            
            if  data['values'][0].is_a?(Array)
              data['values'][0].each_index do |i|
                tmp = [i]
                data['values'].each_index do |j|
                  tmp.push(data['values'][j][i])
                end
                final.push tmp
              end
            else
              #          start_i = (params[:header] == '1') ? 0 : 1
              #          (0 .. data['values'].size-1).each do |i|
              data['values'].each_index do |i|
                if params[:first_col] == '1'
                  final.push [i, ((data['cells']) ? data['cells'][i] : ((data['genes']) ? data['genes'][i] : '')), data['values'][i]]
                else
                  final.push [((data['cells']) ? data['cells'][i] : ((data['genes']) ? data['genes'][i] : '')), data['values'][i]]
                end
              end
            end
            content =  final.map{|e| e.join("\t")}.join("\n")
            # elsif @annot.dim ==3
            #   
          end
          send_data content,  type: params[:content_type] || 'text', disposition: (!params[:display]) ? ("attachment; filename=" + @project.key  + "_" + @annot.filepath.gsub("/", "_")  + @annot.name.gsub("/", "_") + "." + ext) : ''
        end
      end
    end
  end


  def extract_row(occ)
    row = nil 
    
    if readable? @project  and annot_id = session[:dr_params][@project.id][:annot_id] 
      @annot = Annot.where(:id => annot_id).first
      project_dir = Pathname.new(APP_CONFIG[:user_data_dir]) + @project.user_id.to_s + @project.key
      loom_path = project_dir + @annot.filepath
      logger.debug("TEST_EXTRACT")
      if occ 
        occ_k = ("occ_" + occ).to_sym
        s = session[:dr_params][@project.id][occ_k]
        
        if s[:data_type] == "1" and s[:dataset_annot_id] and s[:row_i]
          logger.debug("TEST_EXTRACT4")
          @dataset_annot = Annot.where(:id => s[:dataset_annot_id]).first
          loom_path = project_dir + @dataset_annot.filepath
          # run = Run.where(:project_id => @project.id, :id => params[:annot_id])
          #  h_outputs = JSON.parse(run.output_json)
          #  output_matrix = nil
          #  h_outputs.each_key do |k|
          #    h_outputs[k].each do |e|       
          #    end
          #  end
          
          @cmd = "java -jar #{APP_CONFIG[:local_asap_run_dir]}/ASAP.jar -T ExtractRow -prec 2 -stable_ids #{s[:row_i]} -loom #{loom_path} -iAnnot \"#{@dataset_annot.name}\" -loom_cells #{@dr_loom_file}"
          row_txt = `#{@cmd}`
#          row = (row_txt.match(/^\{/)) ? JSON.parse(row_txt)['row'] : nil
       #   @log4 += @cmd
          logger.debug("CMD_extract:" + @cmd)
          tmp = Basic.safe_parse_json(row_txt, {})
          row = (tmp and tmp['values']) ? tmp['values'][0] : []
          @log4 = tmp
        elsif s[:data_type] == "2" and s[:num_annot_id] and s[:header_i]
          @num_annot = Annot.where(:id => s[:num_annot_id]).first
           row = [] #(0 .. @dataset_annot.nber_cols).to_a.map{|e| 0}
          if @num_annot and @num_annot.dim == 1 
            # col =>  ExtractCol
            if @num_annot.nber_rows == 1
              logger.debug("TEST_EXTRACT3")
              @cmd = "java -jar #{APP_CONFIG[:local_asap_run_dir]}/ASAP.jar -T ExtractMetadata " + ((dt = @num_annot.data_type and dt.name) ? "-type #{dt.name}" : "") + " -prec 2 -loom #{loom_path} -meta \"#{@num_annot.name}\""
              row_txt = `#{@cmd}`
             # row = (row_txt.match(/^\{/)) ? JSON.parse(row_txt)['values'].map{|e| e.to_f} : nil
              tmp_h = Basic.safe_parse_json(row_txt, {})              
              #      row = (tmp_h['list_meta'] and meta = tmp_h['list_meta'][0]) ? meta['values'] : []
              row = (tmp_h['values']) ? tmp_h['values'] : [] 
            else
              logger.debug("TEST_EXTRACT2")
              @cmd = "java -jar #{APP_CONFIG[:local_asap_run_dir]}/ASAP.jar -T ExtractCol -prec 2 -indexes #{s[:header_i]} -loom #{loom_path} -iAnnot #{@num_annot.name}"
              t = Time.now
              row_txt = `#{@cmd}`
              t2 = Time.now
              logger.debug("ExtractCol timing: " + t2-t1)
              #              row = (row_txt.match(/^\{/)) ? JSON.parse(row_txt)['col'] : nil
              row = (parsed_row_txt = Basic.safe_parse_json(row_txt, {}) and parsed_row_txt['values']) ? parsed_row_txt['values'][0] : nil
            end
            #          row= [@cmd]
            # else
            # row => 
            #  @cmd = "java -jar #{APP_CONFIG[:local_asap_run_dir]}/ASAP.jar -T ExtractRow -i #{params[:row_i]} -f #{loom_path} -iAnnot #{@dataset_annot.name}"
          end
          #      elsif s[:coloring_type] == '3'
        elsif s[:data_type] == '3' and s[:geneset_annot_id] and s[:geneset_annot_cat]
         # @cmd = "bla"
          res = compute_module_score(s[:geneset_annot_id], s[:geneset_annot_cat])
          row = res['scores']
        elsif s[:data_type] == '4' and s[:geneset_id] and s[:geneset_item_id]
          res = compute_module_score_geneset(loom_path, s[:geneset_id], s[:geneset_item_id])
          @log4 = res.to_json
          row = res['scores']
        else
          @cmd = [s[:data_type], s[:geneset_annot_id], s[:geneset_annot_cat], s.to_json].join(",")
        end
        #      row = ['blou']
     # end
     #  row = ['blu']
      elsif session[:dr_params][@project.id][:coloring_type] == '3' and cat_annot_id = session[:dr_params][@project.id][:cat_annot_id] ## cat
      
        @cat_annot = Annot.where(:id => cat_annot_id).first
        row = []
        # row = (0 .. @dataset_annot.nber_cols).to_a.map{|e| 0}
        #  if @cat_annot.dim == 1
        # col =>  ExtractCol                                                                                                                                                                                          
        ## initialize sel_cats to all categories
#        session[:dr_params][@project.id][:sel_cats] = Basic.safe_parse_json(@cat_annot.categories_json, {}).keys
        if @cat_annot and @cat_annot.nber_rows == 1
          @cmd = "java -jar #{APP_CONFIG[:local_asap_run_dir]}/ASAP.jar -T ExtractMetadata " + ((dt = @cat_annot.data_type and dt.name) ? "-type #{dt.name}" : "") + " -loom #{loom_path} -meta \"#{@cat_annot.name}\""
          row_txt = `#{@cmd}`
#          row = (row_txt.match(/^\{/)) ? JSON.parse(row_txt)['values'].map{|e| e.to_f} : nil
          
          tmp_h = Basic.safe_parse_json(row_txt, {}) #['values']
          #          row = (tmp_h['list_meta'] and meta = tmp_h['list_meta'][0]) ? meta['values'] : []
          row = (tmp_h['values']) ? tmp_h['values'] : []
          
        else
          #        @cmd = "java -jar #{APP_CONFIG[:local_asap_run_dir]}/ASAP.jar -T ExtractCol -i #{s[:header_i]} -f #{loom_path} -iAnnot #{@cat_annot.name}"
          #        row_txt = `#{@cmd}`
          #        row = (row_txt.match(/^\{/)) ? JSON.parse(row_txt)['col'] : nil
        end
        #  end
        #        row = [@cmd]
      else
        # row = ['blo']
      end
      #   respond_to do |format|
      #     format.json {
      #       render :text => @row.to_json
      #     }
    #   end
      # row = ['bla']
    end
    return row
  end

  def del_gene
    if params[:occ]
      occ_k = ("occ_" + params[:occ]).to_sym
      [:gene_selected, :row_i].each do |k|
        session[:dr_params][@project.id][occ_k].delete(k)
      end
    end
  end

  def get_rows
#    expires_in 30.minutes, public: true
    @log4 = ''
    @rows = []

    @h_steps = {}
#    Step.where(:version_id => @project.version_id).all.map{|s| @h_steps[s.id] = s}
    Step.where(:docker_image_id => @asap_docker_image.id).all.map{|s| @h_steps[s.id] = s} 

    project_dir =  Pathname.new(APP_CONFIG[:user_data_dir]) + @project.user_id.to_s + @project.key
#    dr_annot = (session[:csp_params][@project.id][:annot_id]) ? Annot.where(:id => session[:csp_params][@project.id][:annot_id], :dim => 1, :project_id => @project.id).first :  Annot.where(:run_id => session[:csp_params][@project.id][:run_id], :dim => 1, :project_id => @project.id).first
     dr_annot = (params[:annot_id]) ? Annot.where(:id => params[:annot_id], :dim => 1, :project_id => @project.id).first :  Annot.where(:run_id => params[:run_id], :dim => 1, :project_id => @project.id).first
   # dr_annot = Annot.where(:run_id => session[:dr_params][@project.id][:run_id], :dim => 1, :project_id => @project.id).first
    @dr_loom_file = project_dir + ((dr_annot) ? dr_annot.filepath : '')

#    @annot = Annot.where(:id => session[:dr_params][@project.id][:annot_id]).first
    h_res = {}

    ### detect there is a change of cat_annnot_id to init selected clusters
    if session[:dr_params][@project.id][:cat_annot_id] != params[:cat_annot_id]
      cat_annot = Annot.where(:id => params[:cat_annot_id]).first
      if cat_annot
        session[:dr_params][@project.id][:sel_cats] = Basic.safe_parse_json(cat_annot.categories_json, {}).keys
      end
    end
    
    if session[:dr_params][@project.id][:cat_annot_id] != params[:cat_annot_id2]
      cat_annot2 = Annot.where(:id => params[:cat_annot_id2]).first
      if cat_annot2
        session[:dr_params][@project.id][:sel_cats2] = Basic.safe_parse_json(cat_annot2.categories_json, {}).keys
      end
    end
    
    [:annot_id, :coloring_type, :cat_annot_id, :cat_annot_id2].each do |k|
      if params[k]
        session[:dr_params][@project.id][k] = params[k]
      end
    end
    if params[:occ]
#      @rows = ['bla']
      occ_k = ("occ_" + params[:occ]).to_sym
      [:gene_selected, :dataset_annot_id, :row_i, :data_type, :header_i, :num_annot_id, :geneset_annot_id, :geneset_annot_cat, :geneset_id, :geneset_item_id, :autocomplete_geneset_item].each do |k|
        if params[k]
          session[:dr_params][@project.id][occ_k]||={}
          session[:dr_params][@project.id][occ_k][k] = params[k]
        end
      end
    
      if session[:dr_params][@project.id][:coloring_type] == "1"
        if row = extract_row("1")
          #          @log4 = row
          @rows.push row.map{|e| (e.is_a? Numeric) ? e : ""}
          #          @rows.push session[:dr_params][@project.id][:coloring_type]
        end
      elsif session[:dr_params][@project.id][:coloring_type] == "2"
        ["2", "3", "4"].each do |i|
          if  row = extract_row(i)
            @rows.push row.map{|e| (e == '') ? '_EMPTY_' : e}
          end
        end
      end
    elsif params[:coloring_type] == '3' ## categorical
 #      @rows = ['bla']
      if row = extract_row(nil)
        @rows = [row]
      end
      if @cat_annot
        h_res[:cat_aliases] = Basic.safe_parse_json(@cat_annot.cat_aliases_json, {})
        #      h_res[:test] = @cat_annot.to_json
      end
    end

    if session[:dr_params][@project.id][:cat_annot_id2]
      
    end

    h_res[:rows] = (@rows == [[]]) ? [] : @rows
    
    if [1,2].include?  session[:dr_params][@project.id][:coloring_type].to_i 
      if params[:occ].to_i == 1 and @rows[0] and session[:dr_params][@project.id][:occ_1][:data_type].to_i > 2 or (@num_annot and @h_steps[@num_annot.step_id].name == 'module_score' )
        h_res[:ordered_idx] = (0 .. @rows[0].size-1).to_a.map{|i| [i, ((@rows[0][i]) ? @rows[0][i] : 0)] }.sort{|a, b| a[1].abs <=> b[1].abs}.map{|e| e[0]}
      else
        row_i = (@rows[0] and @rows[0].size > 0) ? 0 : ((@rows[1] and @rows[1].size > 0) ? 1 : 2)
        if @rows[row_i]
          h_res[:ordered_idx] = (0 .. @rows[row_i].size-1).to_a.map{|i| [i, ((m = Basic.mean(@rows.map{|e| e[i]}.reject{|e2| e2==''})) ? m : -100000)] }.sort{|a, b| a[1] <=> b[1]}.map{|e| e[0]}
        end
      end
    elsif session[:dr_params][@project.id][:coloring_type].to_i == 3 and @rows[0] and @cat_annot
      h_cats = Basic.safe_parse_json(@cat_annot.categories_json, {})
      h_res[:ordered_idx] = (0 .. @rows[0].size-1).to_a.map{|i| [i, (h_cats[@rows[0][i]] || -10000)]}.sort{|a, b| b[1] <=> a[1]}.map{|e| e[0]}
    end
    h_res[:ordered_idx] ||= (@rows.size > 0) ? (0 .. @rows[0].size-1).to_a.map{|i| i} : []
    h_res[:cmd] = @cmd
    h_res[:log] = @log4
    h_res[:test] = @genes_annot
    h_res[:sel_cats] = session[:dr_params][@project.id][:sel_cats]
    h_res[:warnings] = (@rows.size == 0 or @rows.map{|e| e.select{|e2| e2 == ''}.size}.sum > 0) ? 'missing gene expression values for this gene and data source (cross markers)' : nil
    respond_to do |format|          
      format.json {                                      
        render :plain => h_res.to_json                                                
      }                                                                                                                                                                                                      
    end        
  end


  def save_plot_settings
    [:dot_opacity, :dot_size, :cell_names_on_hover, :coloring_type, :main_menu].each do |k|
      session[:dr_params][@project.id][k] = params[k] if params[k]
    end
  end

  def get_autocomplete_genes
    expires_in 30.minutes, public: true
    #    get_base_data()
    project_dir =  Pathname.new(APP_CONFIG[:user_data_dir]) + @project.user_id.to_s + @project.key
    
    @autocomplete_json = '[]'
    autocomplete_file = project_dir + 'parsing' + 'autocomplete_genes.json'
    if !File.exists? autocomplete_file
      #  @log4 += 'bla'                                                                                                                                   
      ### retrieve data from loom                                                                                                                         
      parsing_run = Run.joins(:step).where(:project_id => @project.id, :steps => {:name => 'parsing'}).first
      h_annots = {}
      # store_run_id= @annot.store_run_id    
      #if s[:dataset_annot_id]
      #  store_run_id = Annot.where(:id => s[:dataset_annot_id]).first.store_run_id
      #end
      annot_names = ["/row_attrs/Gene", "/row_attrs/Accession", "/row_attrs/_StableID"]
      annot_names.each_index do |i|
        annot_name = annot_names[i]
        key = annot_name.split("/")[2].downcase
        
        genes_annot = Annot.where(:store_run_id => parsing_run.id, :name => annot_name).first
        
        loom_path = project_dir + genes_annot.filepath
        @cmd = "java -jar #{APP_CONFIG[:local_asap_run_dir]}/ASAP.jar -T ExtractMetadata -loom #{loom_path} -meta \"#{annot_name}\""
        logger.debug("CMD_extract_metadata:" + @cmd)
        #  @log4 += "java -jar #{APP_CONFIG[:local_asap_run_dir]}/ASAP.jar -T ExtractMetadata -f #{loom_path} -meta #{annot_name}"                        
        val = `#{@cmd}`
        h_res = Basic.safe_parse_json(val, {})
        h_annots[key] = (h_res['values']) ? h_res['values'] : []
      end
      
      ### get alt names from database                                                                                                                     
      h_alt_names = {}
      accessions = h_annots['accession'].uniq
      h_search = {:organism_id => @project.organism_id}
      if accessions.size < 65000
        h_search[:ensembl_id] = accessions
      end
    #  Thread.new do

      cond = ''
      h_search.keys.map{|k|
        "#{k}='#{h_search[k]}'"
      }.join(" and ")

      res = Basic.sql_query2(:asap_data, @h_env['asap_data_db_version'], 'genes', '', 'ensembl_id, alt_names', cond)
      res.each do |g|
        h_alt_names[g.ensembl_id] = g.alt_names
      end

#        ConnectionSwitch.with_db(:data_with_version, @h_env['asap_data_db_version']) do
#          Gene.select("ensembl_id, alt_names").where(h_search).all.each do |g|
#            h_alt_names[g.ensembl_id] = g.alt_names
#          end
#        end
    #  end
      
      autocomplete_list = []
      h_indexes = {}
      if h_annots["accession"]
        h_annots["accession"].each_index do |i|
          h_indexes[h_annots["_stableid"][i]] = i
          alt_names = h_alt_names[h_annots["accession"][i]]
          tmp = [
                 h_annots["gene"][i], 
                 ((h_annots["accession"][i] != '') ? h_annots["accession"][i] : nil), 
                 ((alt_names and alt_names != '') ? "[#{alt_names}]" : nil), 
                 "{#{h_annots["_stableid"][i]}}"
                ].compact.join(" ")
          autocomplete_list.push tmp #@h_annots["_stableid"][i]                                                                                           
        end
      end
      @autocomplete_json = {"search" => autocomplete_list.sort, "h_indexes" => h_indexes}.to_json
      
      if autocomplete_list.size > 0 and h_indexes.keys.size > 0
        File.open(autocomplete_file, 'w') do |f|
          f.write(@autocomplete_json)
        end
      end
    else
      @autocomplete_json = File.read(autocomplete_file)
    end
    render :plain => @autocomplete_json
    #    render :partial => 'get_autocomplete_genes'
  end
  
  def get_dr_options

    @h_users = (current_user) ? {current_user.id => 'me'} : {}
    
    @project.shares.map{|s| @h_users[s.user_id] = s.email}

    @h_std_methods = {}
#    StdMethod.where(:version_id => @project.version_id).all.map{|s| @h_std_methods[s.id] = s}
     StdMethod.where(:docker_image_id => @asap_docker_image.id).all.map{|s| @h_std_methods[s.id] = s}
    @h_steps = {}
#    Step.where(:version_id => @project.version_id).all.map{|s| @h_steps[s.id] = s} #; @h_steps[s.label] = s}
    Step.where(:docker_image_id => @asap_docker_image.id).all.map{|s| @h_steps[s.id] = s} #; @h_steps[s.label] = s}
    
    get_base_data()
    
    project_dir =  Pathname.new(APP_CONFIG[:user_data_dir]) + @project.user_id.to_s + @project.key
    @annot = nil
    @run = nil
    @datasets = []
    #    @autocomplete_json = '[]'
    @log4 = ''
    @num_annots = []
    @cat_annots = []
    @geneset_annots = []
#    if session[:dr_params][@project.id][:cat_annot_id] != params[:cat_annot_id]
   # cat_annot = Annot.where(:id => session[:dr_params][@project.id][:cat_annot_id]).first
   # if cat_annot
   #   session[:dr_params][@project.id][:sel_cats] = Basic.safe_parse_json(cat_annot.categories_json, {}).keys
   # end
    #    end


    if readable?(@project) 
      if params[:annot_id]
        @annot = Annot.where(:id => params[:annot_id]).first
        @run = @annot.run
      elsif params[:run_id]
        @run = Run.where(:id => params[:run_id]).first
        @annot = Annot.where(:project_id => @project.id, :run_id => params[:run_id]).first
      end
      @h_attrs = Basic.safe_parse_json(@run.attrs_json, {})
      @h_annots = {}
      
      all_runs = []
      store_run = Run.where(:id => @annot.store_run_id).first
      #      source_run = Run.where(:id => @h_attrs['input_matrix']['run_id']).first
      occ_k = :occ_1 #("occ_" + params[:occ]
      if s = session[:dr_params][@project.id][occ_k]
        
        if s[:dataset_annot_id] and tmp_annot = Annot.where(:id => s[:dataset_annot_id]).first 
          store_run = Run.where(:id => tmp_annot.store_run_id).first
        end
        
        #   s[:dataset_annot_id] = store_run.id
####### this is what we want at the end
        # if admin?
        @datasets = Annot.where(:project_id => @project.id, :dim => 3, :store_run_id => @annot.store_run_id).all.to_a
        #   else
        
       #@datasets = Annot.where(:project_id => @project.id, :store_run_id => [store_run.id] + store_run.lineage_run_ids.split(","), :dim => 3).all.to_a 
       #   @datasets = Annot.where(:project_id => @project.id, :store_run_id => store_run.id, :dim => 3).all.to_a 
       # end
        #   @datasets = Annot.where(:project_id => @project.id, :dim => 3).all.to_a
        #   @datasets.push @annot if !@datasets.include? @annot
        #   h_datasets = {}
        #   @datasets.map{|d| h_datasets[d.run_id]=d}
        #   @log4+= source_run.id.to_s + ' => titi' + @datasets.to_json
        #   if  h_datasets[store_run.id]
        #     s[:dataset_annot_id] =  h_datasets[store_run.id].id
        @log4 += 'toto'
        @num_annots = Annot.where(:project_id => @project.id, :data_type_id => 1, :dim => 1, :store_run_id => @annot.store_run_id).all.select{|a| a.nber_rows and a.nber_rows < 200}
        @cat_annots = Annot.where(:project_id => @project.id, :data_type_id => 3, :dim => 1, :store_run_id => @annot.store_run_id).all
        @all_geneset_annots =  Annot.where(:project_id => @project.id, :data_type_id => 3, :dim => 2, :store_run_id => @annot.store_run_id).all.to_a
        @geneset_categories =  Basic.safe_parse_json("[" + @all_geneset_annots.map{|ga| ga.categories_json || 'null'}.join(",") + "]", [])
        @geneset_annots = []
        if @all_geneset_annots
          @all_geneset_annots.each_index do |i|
            if h_categories = @geneset_categories[i] and 
                nber_cats = h_categories.keys.size and (nber_cats > 1 or (nber_cats == 1 and !h_categories[""])) 
              @geneset_annots.push @all_geneset_annots[i]
            end
          end
        end
        # @geneset_annots.select!{|ga| ga.}
        @num_annot = nil
        if annot_id = params[:annot_id]
          @num_annot = Annot.where(:project_id => @project.id, :id => annot_id).first
        end

        ### get all users who inputed annotations
        list_cat_aliases_json = []
        @cat_annots.each do |cat_annot|
          list_cat_aliases_json.push cat_annot.cat_aliases_json if cat_annot.cat_aliases_json
        end
        user_ids = []
        list_cat_aliases = Basic.safe_parse_json("[" + list_cat_aliases_json.join(",") + "]", {})
        list_cat_aliases.each do |cat_aliases|
          user_ids |= cat_aliases["user_ids"].values.uniq
        end
        
        User.where(:id => user_ids).each do |user|
          @h_users[user.id] = ((user.id == 1) ? 'Admin' : user.email) if user != current_user
        end
        
        @genesets = [] #GeneSet.where(:user_id => 1, :project_id => nil, :organism_id => @project.organism_id).order("label").all
        @genesets = Basic.sql_query2(:asap_data, @h_env['asap_data_db_version'], 'gene_sets', '', '*', "organism_id = #{@project.organism_id}")
        
        @geneset_items = []
        if s[:geneset_id]
          @geneset_items = Basic.sql_query2(:asap_data, @h_env['asap_data_db_version'], 'gene_set_items', '', '*', "geneset_id = #{s[:geneset_id]}")
        end

        #   res.each do |gs|
        # @h_gene_sets[gs.id.to_i] = gs
        #end

        ### prepare JSON file for searching genes
#        store_run_step = store_run.step
#     #   autocomplete_file = project_dir + store_run_step.name
#     #   autocomplete_file += store_run.id.to_s if store_run_step.multiple_runs == true
#        autocomplete_file = project_dir + 'parsing'
#        autocomplete_file += 'autocomplete_genes.json'
#
##        if s[:dataset_annot_id] != params[:dataset_annot_id]
##          File.delete autocomplete_file
##        end
#
#        @log4+=autocomplete_file.to_s
#        if !File.exists? autocomplete_file
#          #  @log4 += 'bla'
#          ### retrieve data from loom
#          
#          store_run_id= @annot.store_run_id
#          if s[:dataset_annot_id]
#            store_run_id = Annot.where(:id => s[:dataset_annot_id]).first.store_run_id
#          end
#          annot_names = ["/row_attrs/Gene", "/row_attrs/Accession", "/row_attrs/_StableID"]
#          annot_names.each_index do |i|
#            annot_name = annot_names[i]
#            key = annot_name.split("/")[2].downcase  
#            
#            @genes_annot = Annot.where(:store_run_id => store_run_id, :name => annot_name).first
#            
#            loom_path = project_dir + @genes_annot.filepath
#            @cmd = "java -jar #{APP_CONFIG[:local_asap_run_dir]}/ASAP.jar -T ExtractMetadata -loom #{loom_path} -meta #{annot_name}"
#            #  @log4 += "java -jar #{APP_CONFIG[:local_asap_run_dir]}/ASAP.jar -T ExtractMetadata -f #{loom_path} -meta #{annot_name}" 
#            val = `#{@cmd}`
#            @log4 += @cmd
#            @log4 += " : " + val
#            #              h_res = (val.match(/^\{/)) ? JSON.parse(val) : {} 
#            h_res = Basic.safe_parse_json(val, {})
#            #             @h_annots[key] = (h_res['list_meta'] and meta = h_res['list_meta'].first) ? meta['values'] : [] 
#            @h_annots[key] = (h_res['values']) ? h_res['values'] : []
#          end
#          
#          ### get alt names from database
#          h_alt_names = {}
#          accessions = @h_annots['accession'].uniq
#          h_search = {:organism_id => @project.organism_id}
#          if accessions.size < 65000
#            h_search[:ensembl_id] = accessions
#          end
#          ConnectionSwitch.with_db(:data_with_version, @h_env['asap_data_db_version']) do
#            Gene.select("ensembl_id, alt_names").where(h_search).all.each do |g|
#              h_alt_names[g.ensembl_id] = g.alt_names 
#            end
#          end
#          
#          autocomplete_list = []
#          h_indexes = {}
#          if @h_annots["accession"]
#            @h_annots["accession"].each_index do |i|
#              h_indexes[@h_annots["_stableid"][i]] = i
#              alt_names = h_alt_names[@h_annots["accession"][i]]
#              str = [@h_annots["gene"][i], ((@h_annots["accession"][i] != '') ? @h_annots["accession"][i] : nil), ((alt_names and alt_names != '') ? "[#{alt_names}]" : nil), "{#{@h_annots["_stableid"][i]}}"].compact.join(" ")
#              autocomplete_list.push str #@h_annots["_stableid"][i]
#            end
#          end
#          @autocomplete_json = {"search" => autocomplete_list.sort, "h_indexes" => h_indexes}.to_json
#         
#          if autocomplete_list.size > 0 and h_indexes.keys.size > 0
#            File.open(autocomplete_file, 'w') do |f|
#              f.write(@autocomplete_json)
#            end
#          end
#        else
#          @autocomplete_json = File.read(autocomplete_file)
#        end
        #  end
      end
    end
    render :partial => 'dim_reduction_options'
  end
  
  def upd_cat_alias
 
    if params[:annot_id] and params[:cat_name] and params[:cat_alias]
      annot = Annot.where(:id => params[:annot_id]).first
      h_cat_aliases = Basic.safe_parse_json(annot.cat_aliases_json, {})
      h_cat_aliases['names']||={}
      h_cat_aliases['user_ids']||={}
      h_cat_aliases['names'][params[:cat_name]] = params[:cat_alias]
      h_cat_aliases['user_ids'][params[:cat_name]] = current_user.id
      annot.update_attribute(:cat_aliases_json, h_cat_aliases.to_json)
      render :partial => "upd_cat_alias"

    else
      render :nothing => true, :body => nil
    end
    

  end

  def prepare_metadata
    fus_dir = Pathname.new(APP_CONFIG[:data_dir]) + 'fus'
    #     id   | project_id | upload_type | name | status | upload_file_name | upload_content_type | upload_file_size | upload_updated_at | visible |         created_at         |         updated_at         | project_key | user_id |  url 
    # 24671 |       8042 |           2 |      | uploaded   | gene_annotation.txt                           | text/plain          |               75 | 2020-07-06 12:53:41.648498 |         | 2020-07-10 12:11:27.303385 | 2020-07-10 12:11:27.304957 | prgtm1      |       1 |
    filename = 'clipboard.txt'

    h_fu = {
      :project_id => @project.id,
      :project_key => @project.key,
      :status => 'new',
      :upload_type => 2,
      :upload_file_name => filename,
      :upload_content_type => 'text/plain',
      :user_id => (current_user) ? current_user.id : 1
    }
    
    @fu = Fu.new(h_fu)
    @fu.save
#    
#      {name : 'delimiter', value : $("#opt_delimiter").val()},
#  {name : 'input_type_id', value : $("#op_input_type_id").val()},
#  {name : 'name', value : $("#opt_name").val()},
#  {name : 'content', value : $("#opt_content").val()}
    if @fu
      
      delimiters = ["\n", "\t", " ", ";", ","]
      fu_dir = fus_dir + @fu.id.to_s
      Dir.mkdir fu_dir
      filepath = fu_dir + filename

      ## remove potential duplicate and report them
      list_identifiers = []
      h_identifiers = {}
      @duplicates = []
      final_content = []
      if params[:input_type_id] == '2'
        params[:content].split(/\n/).each do |l| 
          l.split(/\t/).each do |e|
            if !h_identifiers[e[0]]
              h_identifiers[e[0]] = 1
              final_content.push e.join("\t")
            else
              @duplicates.push e[0]
            end
          end
        end
      elsif params[:input_type_id] == '1'
        final_content = ["genes\t#{params[:name]}"]
        params[:content].split(/#{delimiters[params[:delimiter].to_i]}+/).each do |e|
          if !h_identifiers[e]
            h_identifiers[e] = 1
            final_content.push "#{e}\t1"
          else
            @duplicates.push e
          end
        end
      end


      File.open(filepath, 'w') do |f|
        f.write(final_content.join("\n"))
     #   if params[:input_type_id] == '2'
     #     f.write(params[:content])
     #   elsif params[:input_type_id] == '1'
     #     f.write("genes\t#{params[:name]}\n")
     #     params[:content].split(/#{delimiters[params[:delimiter].to_i]}+/).each do |e|
     #       f.write("#{e}\t1\n")
     #     end
     #   end
      end
      if File.exist? filepath and File.size(filepath) > 0      
        h_upd = {
          :status => 'written',
          :upload_file_size => File.size(filepath),
          :upload_updated_at => Time.now
        }
        
        @fu.update_attributes(h_upd)
    #    fu.broadcast
      end
    end
    render :partial => "prepare_metadata"
  end

  def do_import_metadata
 
#    lineage_run_ids = @run.lineage_run_ids.split(",")
#    lineage_run_ids.push @run.id
    
    project_dir = Pathname.new(APP_CONFIG[:user_data_dir]) + @project.user_id.to_s + @project.key
    fu_dir = Pathname.new(APP_CONFIG[:data_dir]) + 'fus'
    # total_nber_operations = Run.joins("join steps on (step_id = steps.id)").where(:steps => {:name => 'import_metadata'}, :project_id => @project.id).all.size
    last_run =  Run.joins("join steps on (step_id = steps.id)").where(:steps => {:name => 'import_metadata'}, :project_id => @project.id).order("num asc").last

  #  @import_metadata_step = Step.where(:version_id => @project.version_id, :name => 'import_metadata').first
    @import_metadata_step = Step.where(:docker_image_id => @asap_docker_image.id, :name => 'import_metadata').first
   # std_method = StdMethod.where(:version_id => @project.version_id, :name => 'add_meta').first
    std_method = StdMethod.where(:docker_image_id => @asap_docker_image.id, :name => 'add_meta').first 

    h_run = {
      :project_id => @project.id,
      :step_id => @import_metadata_step.id,
      :std_method_id => std_method.id,
      :status_id => 6, #status_id, # set as running                                                                                                         
      :num => (last_run) ? last_run.num + 1 : 1,
      :user_id => (current_user) ? current_user.id : 1,
      :command_json => "{}", #h_cmd.to_json,                                                                                                                
      :attrs_json => "{}", #self.parsing_attrs_json,                                                                                                        
      :output_json => "{}", #h_outputs.to_json,
      :lineage_run_ids => '', #lineage_run_ids.join(","),
      :submitted_at => Time.now
    }
    
    if params[:fu_id]
      
      new_run = Run.new(h_run)
      new_run.save
      #input_filename = "tmp/import_metadata_#{new_run.id}"
      #input_filepath = project_dir + input_filename
      
      fu = Fu.where(:id =>params[:fu_id]).first
      input_filename = fu.upload_file_name
     # upload_filename = fu_dir + params[:fu_id] + fu.upload_file_name
     # File.symlink upload_filename, input_filepath
      
#      h_res = Basic.safe_parse_json( File.read(fu_dir + params[:fu_id] + 'output.json'), {})
      metadata_types = params[:metadata_types]
      h_attrs = {
        :input_run_ids => Run.joins(:step).where(:project_id => @project.id, :steps => {:name => ['parsing', 'cell_filtering', 'gene_filtering']}).all.map{|r| r.id}.join(","), # to be defined when the job is executed or then prevent creating new filtering if an import metadata is pending or running       
        #:file_type => h_res['detected_format'],
        :ori_filename => fu.upload_file_name,
        :input_filename => input_filename, #Basic.relative_path(@project, input_filename),      
        :metadata_type_id => params[:metadata_type_id],
        :fu_id => params[:fu_id],
        :metadata_types => metadata_types.join(","),
        :assign_metadata => params[:assign_metadata]
      }
      
      h_command = {
        :program => "rake parse_metadata[#{new_run.id}]",
        :host_name => "localhost",
        :opts => [],
        :args => []
      }
      
      new_run.update_attributes({:status_id => 1, :command_json => h_command.to_json, :attrs_json => h_attrs.to_json})
      
      #run_dir = metadata_dir + new_run.id.to_s
      #Dir.mkdir(run_dir) if !File.exist? run_dir    
    end

    render :partial => 'do_import_metadata'
    
  end

  def save_metadata_from_selection
    
    @run = nil

    if params[:annot_id]
      annot = Annot.where(:id => params[:annot_id]).first
      @run = annot.run
    end
    
    @run = Run.where(:id => params[:run_id]).first if !@run ### dimension reduction run
    
    if @run
      
      project_dir =  Pathname.new(APP_CONFIG[:user_data_dir]) + @project.user_id.to_s + @project.key
      metadata_dir = project_dir + 'metadata'
      Dir.mkdir(metadata_dir) if !File.exist? metadata_dir
      
      version = @project.version
      h_env = JSON.parse(version.env_json)
      if !annot
        annot = @run.annots.select{|a| a.dim == 1}.first ## suppose there is only one annotation produced           
      end
      loom_file = @run.annots.first.filepath
      total_nber_operations = Run.joins("join steps on (step_id = steps.id)").where(:steps => {:name => 'cell_selection'}, :project_id => @project.id).all.size
      total_nber_selections = Run.joins("join std_methods on (std_method_id = std_methods.id)").where(:std_methods => {:name => 'cell_sel'}, :project_id => @project.id).all.size
      nber_selections = Annot.where(:store_run_id => @run.id, :project_id => @project.id).all.select{|a| a.name.match(/#{annot.name}_sel_/)}.size
      annot_name = annot.name + ".sel_" + (total_nber_operations+1).to_s
      
      h_outputs = {}
      
      lineage_run_ids = @run.lineage_run_ids.split(",")
      lineage_run_ids.push @run.id
      
#      step = Step.where(:version_id => @project.version_id, :name => 'cell_selection').first
      step = Step.where(:docker_image_id => @asap_docker_image.id, :name => 'cell_selection').first    
#      std_method = StdMethod.where(:version_id => @project.version_id, :name => 'cell_sel').first
      std_method = StdMethod.where(:docker_image_id => @asap_docker_image.id, :name => 'cell_sel').first

      h_run = {
        :project_id => @project.id,
        :step_id => step.id,
        :std_method_id => std_method.id, 
        :status_id => 2, #status_id, # set as running  
        :num => total_nber_operations + 1,
        :user_id => (current_user) ? current_user.id : 1,
        :command_json => "{}", #h_cmd.to_json,
        :attrs_json => "{}", #self.parsing_attrs_json,
        :output_json => h_outputs.to_json,
        :lineage_run_ids => lineage_run_ids.join(","),
        :submitted_at => Time.now,
        :return_stdout => true
      }
      
      new_run = Run.new(h_run)
      new_run.save
      run_dir = metadata_dir + new_run.id.to_s
      Dir.mkdir(run_dir) if !File.exist? run_dir

      ### define stableIDs
      @cmd = "java -jar #{APP_CONFIG[:local_asap_run_dir]}/ASAP.jar -T ExtractMetadata -loom #{project_dir + loom_file} -meta /col_attrs/_StableID"
      @h_res = Basic.safe_parse_json(`#{@cmd}`, {})
      
      cell_indexes_filename = run_dir + 'list_cols.json'
      @list_cols = Basic.safe_parse_json(params[:list_cols], [])
      File.open(cell_indexes_filename, 'w') do |f|
        f.write("{\"selected_cells\" : " + @list_cols.map{|i| @h_res['values'][i]}.to_json + "}")
      end
      
      h_cmd = {
        # :host_name => "localhost",
        # :time_call => h_env["time_call"].gsub(/\#output_dir/, run_dir.to_s),
        :program => "java -jar lib/ASAP.jar", # "rails parse[#{self.key}]",  #(mem > 10) ? "java -Xms#{mem}g -Xmx#{mem}g -jar /srv/ASAP.jar" : 'java -jar /srv/ASAP.jar',  
        :opts => [
                  {"opt" => "-T", "value" => "CreateCellSelection"},
                  {"opt" => "-loom", "param_key" => "loom_filename", "value" => project_dir + loom_file},
#                  {"opt" => "-o", "value" => run_dir},
                  {"opt" => "-meta", "param_key" => 'annot_name', "value" => annot_name},
                  {"opt" => '-f', "value" => cell_indexes_filename}
                 ],
        :args => []
      }
      
      new_run.update_attribute(:command_json, h_cmd.to_json)
      
      #      @cmd = "java -jar #{APP_CONFIG[:local_asap_run_dir]}/ASAP.jar -T CreateCellSelection -loom #{loom_file} -meta #{annot_name} -f #{sel_content}"
      #      @res = `#{@cmd}`
      
      @results_json = Basic.exec_run logger, new_run

      meta = Basic.safe_parse_json(@results_json, {}) 
      meta['data_class_names']=['dataset', 'mdata', 'col_mdata', 'discrete_mdata']
      h_data_types = {}
      DataType.all.map{|dt| h_data_types[dt.name] = dt}

      h_data_classes = {}
      DataClass.all.map{|dc| h_data_classes[dc.name] = dc}


      Basic.load_annot new_run, meta, loom_file, h_data_types, h_data_classes, logger
      @new_annot = Annot.where(:run_id => new_run.id).first ##Basic.load_annot new_run, meta, loom_file, h_data_types
      if @new_annot
        h_cat_aliases = {
          :user_ids => {
            "0" => current_user.id,
            "1" => current_user.id
          },
          :names => {
            "0" => (v = params[:unselected_name] and !v.empty?) ? params[:unselected_name] : "Not selected", 
            "1" => (v = params[:selected_name] and !v.empty?) ? params[:selected_name] : "Selected"
          }          
        } 
        
        @new_annot.update_attribute(:cat_aliases_json, h_cat_aliases.to_json)
      end

        
      [["0", "Not selected", params[:unselected_name]], ["1", "Selected", params[:selected_name]]].each do |cat|
        h_cla = {:project_id => @project.id, :annot_id => @new_annot.id, :name => (v = cat[2] and !v.empty?) ? cat[2] : cat[1] , :cat => cat[0], :user_id => current_user.id}
        @cla = Cla.where(h_cla).first
        if !@cla
          @cla = Cla.new(h_cla)
          @cla.save
        end
      end
      

      #      h_output = {
      #        :output_annot => {
      #          [loom_file, annot_name].join(":") => {
      #            :onum  => 1,
      #            :filename => "output.loom"
      #            :dataset => annot_name,
      #            :types => ["dataset","annot","col_annot","discrete_annot"],
      #            :size => File.size(project_dir + loom_file),"nber_rows":2,"nber_cols":384,"dataset_size":6144}}
      #      }
      #
      #      new_run.update_attribute(:output_json, h_output.json)
      
      render :partial => 'save_metadata_from_selection'
    else
      render :nothing => true, :body => nil
    end
  end

  def new_selection
    render :partial => 'new_selection'
  end

  def cell_scatter_plot
    expires_in 30.minutes, public: true
    @h_data = {}
    @run = nil
    @row = nil
    @nber_cols = 0
    @valid_plot = 0
    
    @browser_name = ( params[:browser_name].match(/Chrome/)) ? 'Chrome' : 'Other'
    
    @h_thresholds = {
      'Chrome' => {'2d' => 1500000, '3d' => 500000},
      'Other' => {'2d' => 1500000, '3d' => 200000}
    }
    @cmd = 'bl'
    
    @new_annot = false

    if annot_id = params[:plot][:annot_id]
      if annot_id != session[:csp_params][@project.id][:annot_id]
        @new_annot = true  
      end
      session[:csp_params][@project.id][:annot_id] = annot_id
      @annot = Annot.where(:id => annot_id).first
      @run = @annot.run #Run.where(:id => run_id).first
      h_outputs = Basic.safe_parse_json(@run.output_json, {})

      project_dir =  Pathname.new(APP_CONFIG[:user_data_dir]) + @project.user_id.to_s + @project.key
      @nber_cols = @annot.nber_cols
      loom_file = @annot.filepath
      dataset = @annot.name
      #      dataset = nil
      #      loom_file = ''
      #      h_outputs['output_mdata'].keys.each do |output_key|
      #        t = output_key.split(":")
      #        if t.size > 1
      #          loom_file = t[0]
      #          dataset = t[1]
      #          @nber_cols = h_outputs['output_mdata'][output_key]["nber_cols"]
      #        end
      #      end

      #  @plot_type = '2d'
      #   if (dataset.match(/_3D/) or params[:plot][:dim3]) and session[:csp_params][@project.id][:displayed_nber_dims] == 3
      #  if params[:displayed_nber_dims] == "3"
      @plot_type = (params[:displayed_nber_dims] == '3') ? '3d' : '2d'
      #   end
      if dataset and @nber_cols and ((@nber_cols <= @h_thresholds[@browser_name]['3d'] and @plot_type == '3d') or (@nber_cols <= @h_thresholds[@browser_name]['2d'] and @plot_type == '2d'))
        @valid_plot = 1
        (1 .. session[:csp_params][@project.id][:displayed_nber_dims]).each do |dim|
          session[:csp_params][@project.id]["dim#{dim}"] = params[:plot]["dim#{dim}"]
        end
        if @new_annot == true
          session[:csp_params][@project.id]["dim3"] = 3 #params[:plot]["dim#{dim}"]
        end
        #t2 = dataset.split("/")                                                                                                                                                                                   
        loom_path = project_dir + loom_file
        #        @cmd = "java -jar #{APP_CONFIG[:local_asap_run_dir]}/ASAP.jar -T ExtractMetadata -loom #{loom_path} -meta #{dataset} -names"  
        #        @h_data = {}     
        # @h_cmd.each_key do |k|                                                                                                                                                                               
        @cmd = nil
        dims = []
        if params[:plot]["dim1"]
          dims = [ params[:plot]["dim1"].to_i-1, params[:plot]["dim2"].to_i-1]
          dims.push params[:plot]["dim3"].to_i-1 if params[:plot]["dim3"]
          #          @cmd = "java -jar #{APP_CONFIG[:local_asap_run_dir]}/ASAP.jar -T ExtractCol -prec 2 -indexes #{dims.join(",")} -loom #{loom_path} -iAnnot #{dataset} -display-names"  
          #          h_data = Basic.safe_parse_json(`#{@cmd}`, {})   
          #          h_data['values'] = dims.map{|d| h_data['values'][d.to_i-1]}
          #          @h_json_data= h_data.to_json   
        else
          dims = [0,1]
          dims.push(2) if @plot_type == '3d'
          #          @cmd = "java -jar #{APP_CONFIG[:local_asap_run_dir]}/ASAP.jar -T ExtractMetadata -loom #{loom_path} -meta #{dataset}"                
          #          @cmd = "java -jar #{APP_CONFIG[:local_asap_run_dir]}/ASAP.jar -T ExtractCol -prec 2 -indexes #{dims.join(",")} -loom #{loom_path} -iAnnot #{dataset} -display-names"  
          #    @h_json_data= `#{@cmd}` #.split("\n")[2] #gsub(/^.+?\{/, '{')                       
        end
        @cmd = "java -jar #{APP_CONFIG[:local_asap_run_dir]}/ASAP.jar -T ExtractCol -prec 2 -indexes #{dims.join(",")} -loom #{loom_path} -iAnnot #{dataset}" # -display-names"
        @cmd += " -display-names" if params[:cell_names_on_hover] == '1'
        @h_json_data= `#{@cmd}` if @cmd
      end
    end

    if params[:partial]
      render :partial => params[:partial]
    else
      render :partial => "cell_scatter_plot"
    end
  end


  def dr_plot
    expires_in 30.minutes, public: true
    @h_data = {}
    @run = nil
    @row = nil
    @nber_cols = 0
    @valid_plot = 0

    @browser_name = (params[:browser_name].match(/Chrome/)) ? 'Chrome' : 'Other'

    @h_thresholds = {
      'Chrome' => {'2d' => 1500000, '3d' => 500000},
      'Other' => {'2d' => 1500000, '3d' => 200000}
    }

    if run_id = params[:plot][:run_id]
       session[:dr_params][@project.id][:run_id] = run_id
      @run = Run.where(:id => run_id).first
      h_outputs = Basic.safe_parse_json(@run.output_json, {})
      
      project_dir =  Pathname.new(APP_CONFIG[:user_data_dir]) + @project.user_id.to_s + @project.key      

      dataset = nil
      loom_file = ''
      h_outputs['output_mdata'].keys.each do |output_key|
        t = output_key.split(":")
        if t.size > 1
          loom_file = t[0]
          dataset = t[1]
          @nber_cols = h_outputs['output_mdata'][output_key]["nber_cols"] 
        end
      end

#      @plot_type = '2d'
#      if dataset.match(/_3D/) or params[:plot][:dim3]
#        @plot_type = '3d'
#      end
      @plot_type = (params[:displayed_nber_dims] == '3') ? '3d' : '2d'

      if dataset and @nber_cols and ((@nber_cols <= @h_thresholds[@browser_name]['3d'] and @plot_type == '3d') or (@nber_cols <= @h_thresholds[@browser_name]['2d'] and @plot_type == '2d'))
        @valid_plot = 1
        (1 .. session[:dr_params][@project.id][:displayed_nber_dims]).each do |dim|
          session[:dr_params][@project.id]["dim#{dim}"] = params[:plot]["dim#{dim}"]
        end
        #t2 = dataset.split("/")
        
        loom_path = project_dir + loom_file
#        @cmd = "java -jar #{APP_CONFIG[:local_asap_run_dir]}/ASAP.jar -T ExtractMetadata -loom #{loom_path} -meta #{dataset} -names"
        
        #        @h_data = {}
        # @h_cmd.each_key do |k|
        @cmd = nil
        dims = []
        if params[:plot]["dim1"]
          dims = [ params[:plot]["dim1"].to_i-1, params[:plot]["dim2"].to_i-1]
          dims.push params[:plot]["dim3"].to_i-1 if params[:plot]["dim3"]
#          @cmd = "java -jar #{APP_CONFIG[:local_asap_run_dir]}/ASAP.jar -T ExtractCol -prec 2 -indexes #{dims.join(",")} -loom #{loom_path} -iAnnot #{dataset} -display-names"
#          h_data = Basic.safe_parse_json(`#{@cmd}`, {})
#          h_data['values'] = dims.map{|d| h_data['values'][d.to_i-1]}
#          @h_json_data= h_data.to_json
        else
          dims = [0,1]
          dims.push(2) if @plot_type == '3d'
#          @cmd = "java -jar #{APP_CONFIG[:local_asap_run_dir]}/ASAP.jar -T ExtractMetadata -loom #{loom_path} -meta #{dataset}"
#          @cmd = "java -jar #{APP_CONFIG[:local_asap_run_dir]}/ASAP.jar -T ExtractCol -prec 2 -indexes #{dims.join(",")} -loom #{loom_path} -iAnnot #{dataset} -display-names"
          #    @h_json_data= `#{@cmd}` #.split("\n")[2] #gsub(/^.+?\{/, '{')     
        end
        @cmd = "java -jar #{APP_CONFIG[:local_asap_run_dir]}/ASAP.jar -T ExtractCol -prec 2 -indexes #{dims.join(",")} -loom #{loom_path} -iAnnot #{dataset} -display-names"
        @h_json_data= `#{@cmd}` if @cmd
        
      end
    end

    #    @h_json_data='[]' if  @h_json_data==''
#    if session[:global_dr_params][@project.id][:coloring_type] == "1" and 
#      params[:occ] = '1'
#    extract_row("1")
#    end

    if params[:partial] 
      render :partial => params[:partial]
    else
      render :partial => "dim_reduction_plot"
    end
  end

  def get_run_dim_reduction
    
  end

  def upd_sel_cats
    session[:dr_params][@project.id][:sel_cats] = Basic.safe_parse_json(params[:sel_cats], [])
    render :partial => "upd_sel_cats"
  end

  def get_dim_reduction_form
    render :partial => "dim_reduction_form"
  end

  def get_cell_scatter_form
    render :partial => "cell_scatter_form"
  end

  def get_run_clustering
 
    annot = (@h_annots_by_dim[1]) ?  @h_annots_by_dim[1].first : nil
    if annot
      h_clusters = Basic.safe_parse_json(annot.categories_json, {})
      @h_el["card-clusters"] = {
        :card_header => 'Clusters',
        :card_body => h_clusters.keys.sort{|a, b| a.to_i <=> b.to_i}.map{|k| 
          cell_label = "cell"
          cell_label = cell_label.pluralize if h_clusters[k] > 1
          "<button type='button' id='cat-details_#{annot.id}_#{k}' class='cat-details btn btn-sm btn-outline-secondary'>Cluster #{k} <span class='badge badge-light'>#{h_clusters[k]} #{cell_label}</span></button>"
        }.join(" ")
      }
    end
    #    @h_el["card-resultss"][:card_header] +='bla'
  end

  def get_run_de
    if  @h_annots_by_dim and @h_annots_by_dim[2]
      annot = @h_annots_by_dim[2].first
      loom_file = @project_dir + annot.filepath
      
      @h_stats = {}
      filter_stats_file = @project_dir + 'tmp' + "#{(current_user) ? current_user.id : 1}_de_filtered_stats.json" #+ 'de' + 'filtered_stats.json'
      if File.exist? filter_stats_file
        @h_stats = Basic.safe_parse_json(File.read(filter_stats_file), {})
      end

      ## check if lacking filtered DE results                                                                                                                 
      if !@h_stats[annot.run_id.to_s]
      #  @annots_to_filter = annots.select{|annot| !@h_stats[annot.run_id.to_s]}
        @h_stats = filter_de([annot], "de_results")
      end
      
      #    @cmd = "java -jar #{APP_CONFIG[:local_asap_run_dir]}/ASAP.jar -T ExtractMetadata -f #{loom_file} -prec 2 -light -meta #{annot.name}"
    #    @h_results = JSON.parse(`#{@cmd}`)
      
      ## get cell names                                                                                                                                                          
      #    @cmd2 = "java -jar #{APP_CONFIG[:local_asap_run_dir]}/ASAP.jar -T ExtractMetadata -light -f #{loom_file} -meta /row_attrs/Gene"
      #    @h_res = JSON.parse(`#{@cmd2}`)
      #    @h_results["list_gene_names"]=[]
      #    @h_results["values"][0].each_index do |i|
      #      @h_results["list_gene_names"].push @h_res["values"][i]
      #    end
      
      #    fields = ['p1', 'p2', 'p3', 'p4', 'p5']
      @h_el["card-de_table"] = {
        :card_header => #"<div class='float-right'><button id='download_de_table_btn' class='btn btn-sm btn-primary' type='button'>Download</button></div>" + 
        "Filtered DE tables",
        :card_body => "<span id='up_#{@run.id}' class='badge-nber_genes pointer badge badge-" + ((@h_stats[@run.id.to_s]["up"] > 0) ? "success" : "secondary") + "'>" + @h_stats[@run.id.to_s]["up"].to_s + " up-regulated gene" + ((@h_stats[@run.id.to_s]["up"] > 1) ? "s" : "") + "</span> " +
        "<span id='down_#{@run.id}' class='badge-nber_genes pointer badge badge-" + ((@h_stats[@run.id.to_s]["down"] > 0) ? "danger" : "secondary") + "'>" + @h_stats[@run.id.to_s]["down"].to_s + " down-regulated gene" + ((@h_stats[@run.id.to_s]["down"] > 1) ? "s" : "") + "</span> " +
      "<button id='btn-to_de_table' type='button' class='btn btn-primary btn-sm'>Change threshold</button>"
        #<table id='de_results'>" 
        #"<thead><th>Gene name</th>" + fields.map{|e| "<th>#{e}</th>"}.join("") + "</thead>" + 
        #"<tbody>" + 
        # (0 .. @h_results["values"][0].size-1).map{|vi| "<tr><td>" + @h_results["list_gene_names"][vi] + 
        #        "</td>" + (0 .. (fields.size-1)).map{|i| "<td>" + @h_results["values"][i][vi].to_s + "</td>"}.join("") + "</tr>" }.join("\n") +
        #"</tbody>" +       
        #"</table>"# + @cmd + @h_res["values"].size.to_s  #@h_results["values"].size.to_s + 
        #  @h_res["values"].to_json 
      }
    
    end
  end

  def get_run_ge
#    annot = @h_annots_by_dim[2].first
#    loom_file = @project_dir + annot.filepath

    @h_stats = {}
    filter_stats_file = @project_dir + 'tmp' + "#{(current_user) ? current_user.id : 1}_ge_filtered_stats.json" #+ 'ge' + 'filtered_stats.json'
    if File.exist? filter_stats_file
      @h_stats = Basic.safe_parse_json(File.read(filter_stats_file), {})
    end

    ## check if lacking filtered DE results                                                                                                                                                                                         
    if !@h_stats[@run.id.to_s]
      #  @annots_to_filter = annots.select{|annot| !@h_stats[annot.run_id.to_s]}                                                                                                              ##commented because we should generate the filter from the list page.
#      @h_stats = filter_ge([@run], 'ge_results')
    end

    #   fields = ['p1', 'p2', 'p3', 'p4', 'p5']
    @h_el["card-ge_table"] = {
      :card_header => #"<div class='float-right'><button id='download_de_table_btn' class='btn btn-sm btn-primary' type='button'>Download</button></div>" +                                   
      "Filtered GE tables",
      :card_body => "<span id='up_#{@run.id}' class='badge-nber_genesets pointer badge badge-" + 
      ((@h_stats and @h_stats[@run.id.to_s] and @h_stats[@run.id.to_s]["up"] > 0) ? "success" : "secondary") + "'>" + 
      ((@h_stats[@run.id.to_s]) ? @h_stats[@run.id.to_s]["up"].to_s : '') + 
      " up-regulated gene set" + ((@h_stats[@run.id.to_s] and @h_stats[@run.id.to_s]["up"] > 1) ? "s" : "") + "</span> " +
      "<span id='down_#{@run.id}' class='badge-nber_genesets pointer badge badge-" + 
      ((@h_stats and @h_stats[@run.id.to_s] and @h_stats[@run.id.to_s]["down"] > 0) ? "danger" : "secondary") + "'>" + 
      ((@h_stats[@run.id.to_s]) ? @h_stats[@run.id.to_s]["down"].to_s : '') + 
      " down-regulated gene set" + ((@h_stats[@run.id.to_s] and @h_stats[@run.id.to_s]["down"] > 1) ? "s" : "") + "</span> " +
      "<button id='btn-to_ge_table' type='button' class='btn btn-primary btn-sm'>Change threshold</button>"
    }

  end


  def get_run

    #@h_steps={}
    #Step.all.map{|s| @h_steps[s.id]=s}
    #@h_statuses={}
    #Status.all.map{|s| @h_statuses[s.id]=s}
    get_base_data()

    @h_std_methods = {}
    #    StdMethod.where(:version_id => @project.version_id).all.map{|s| @h_std_methods[s.id] = s}
    StdMethod.where(:docker_image_id => @asap_docker_image.id).all.map{|s| @h_std_methods[s.id] = s}

        ## get dashboard cards info for each valid step                                                                                                                                   
    @h_dashboard_card={}

    ## define output_dir                                                                                                                                                                                          
    @project_dir = Pathname.new(APP_CONFIG[:user_data_dir]) + @project.user_id.to_s + @project.key
    output_json_file =
    @run = Run.where(:id => params[:run_id]).first
    h_attrs = (@run.attrs_json) ? Basic.safe_parse_json(@run.attrs_json, {}) : {}
    #   @h_res = {}
    ## get std_method details    
    h_std_method_attrs = get_std_method_details([@run])
    @step = nil
    @ps = nil
    @output_dir = nil
    h_res = {}
    if @run
      @step = @run.step
      @h_dashboard_card[@step.id] = Basic.safe_parse_json(@step.dashboard_card_json, {}) 
      @h_attrs = (@step.attrs_json and !@step.attrs_json.empty?) ? Basic.safe_parse_json(@step.attrs_json, {}) : {}
      @ps = ProjectStep.where(:project_id => @project.id, :step_id => @step.id).first
      @h_nber_runs = Basic.safe_parse_json(@ps.nber_runs_json, {})
      step_dir = @project_dir + @step.name
      @output_dir = (@step.multiple_runs == true) ? (step_dir + @run.id.to_s) : step_dir
      output_json_file = @output_dir + 'output.json'
#      @h_res = (File.exist? output_json_file) ? JSON.parse(File.read(output_json_file)) : {}
      h_res = (File.exist? output_json_file) ? JSON.parse(File.read(output_json_file)) : {}
    end

    @layout = Basic.safe_parse_json(@step.show_view_json, {})
    @h_outputs = Basic.safe_parse_json(@run.output_json, {})
    
    h_files = {}
    
    nber_plots = 0
    if @h_dashboard_card[@run.step_id]["output_files"]
      @h_dashboard_card[@run.step_id]["output_files"].select{|e| @h_outputs[e["key"]] and ((admin? or e["admin"] == true ) or !e["admin"])}.each do |e|
        k = e["key"]
        @h_outputs[k].keys.each do |output_key|
          t = output_key.split(":")
          h_files[t[0]] ||= {
            :h_output => @h_outputs[k][output_key],
            :datasets => []
          }
          h_files[t[0]][:datasets].push({:name => t[1], :dataset_size => @h_outputs[k][output_key]['dataset_size']}) if t.size > 1
        end
      end
    end
    
    @h_annots_by_dim = {}
    @h_el = {}
    if @step.has_std_view == true or @run.status_id !=3
      
      ## initialize
      #@layout.each do |e|
      #  e["horiz_elements"].each do |e2|
      #    @h_el[e2.id]={}
      #  end
      #end
      annots = Annot.where(:run_id => @run.id).all
      annots.map{|a| @h_annots_by_dim[a.dim] ||= []; @h_annots_by_dim[a.dim].push a}
      dataset_results = []
      h_dim = {1 => 'Cell metadata', 2 => 'Gene metadata', 3 => 'Expression matrix', 4 => "Other"}
      @h_annots_by_dim.each_key do |dim|
        subtitle = h_dim[dim]
        subtitle = subtitle.pluralize if subtitle and @h_annots_by_dim[dim].size > 1
        dataset_results.push "<h4>#{subtitle}</h4><p style='line-height:2.5em'>" +  
          @h_annots_by_dim[dim].map{|annot| 
          col_name = ([1, 3].include? dim) ? 'cell' : 'column'
          row_name = ([2, 3].include? dim) ? 'gene' : 'row'
          col_name = col_name.pluralize if annot.nber_cols and annot.nber_cols > 1
          row_name = row_name.pluralize if annot.nber_rows and annot.nber_rows > 1
          "<button id='annot_#{annot.id}_btn' class='btn btn-outline-secondary btn-sm annot_btn'>#{annot.name} <span class='badge badge-light'>#{annot.nber_cols} #{col_name}</span> <span class='badge badge-light'>#{annot.nber_rows} #{row_name}</span></button>"}.join(" ") + "</p>"
      end

      
      ## set values for standard cards
      @h_el = {
        #        "card-status" => {
        #          :card_header => 'Status',
        #          :card_body => ""
        #        },
        "card-params" => {
          :card_header => 'Parameters',
          :card_body => display_run_attrs(@run, h_attrs, h_std_method_attrs, {})
        },
        "card-downloads" => {
          :card_header => 'Downloads',
          :card_body => ((h_files.keys.size > 0) ? ("<p class='card-text'>" + h_files.keys.map{|k| display_download_btn(@run, h_files[k])}.join(" ") + "</p>") : "")
        },
        "card-results" => {
          :card_header => 'Results',
          :card_body => ((@run.status_id == 3 and h_res['warnings']) ? h_res['warnings'].map{|e|
                           if e.is_a? Hash
                             "<p class='text-warning text-truncate' title=\"#{e['name']}. #{e['description']}\">#{e['name']}</p>"
                           else
                             "<p class='text-warning text-truncate' title='#{e}'>#{e}</p>"
                           end
                         }.join(" ") : '') +
          
          dataset_results.join("<br/>\n")
        }
        
      }
#    else
    end

#    specific_function = "get_run_#{@step.name}()"  
#    begin
#      eval(specific_function)
    all_methods = ProjectsController.action_methods
    if all_methods.include? "get_run_#{@step.name}"
      function = method(("get_run_#{@step.name}").to_sym)
      function.call()      
    end
      #    rescue Exception => e
      ## do nothing for the moment - later we could check if this is normal regarding to the parameters - but for the moment this is not mandatory to create a specific method for a step   
#            @error = e.backtrace
#    end
    #    end
    
    render :partial => (@step.has_std_view == true or @run.status_id != 3) ? 'get_run' : (@step.name + "_view")

  end

  #  def get_step_markers
  #   # @log = "test"
  #  end

  def get_step_metadata_expr
   
    [:metadata_type].each do |k|
      session[k][@project.id] = params[k].to_i if params[k]
    end
    
    @h_annot = {
      :project_id => @project.id, 
      :dim => session[:metadata_type][@project.id]
    }
    @h_annot[:store_run_id] = session[:store_run_id][@project.id] if session[:store_run_id][@project.id] != 0
    @annots = Annot.where(@h_annot).all
    @log5 = @annots
    @h_data_types = {}
    DataType.all.map{|dt| @h_data_types[dt.id]=dt}

    ## get dashboard cards info for each valid step                                  
    #@h_dashboard_card={}
    #Step.all.each do |step|    
    #  @h_dashboard_card[step.id] = JSON.parse(step.dashboard_card_json)
    #end

    @annot_runs = Run.where(:id => @annots.map{|a| a.run_id}.uniq).all

    # get outputs                                                                                                                                                                              
    @h_outputs = {}    
    #  @h_parents = {}
    @annot_runs.each do |r|                                                                                                                                                                  
      @h_outputs[r.id] = Basic.safe_parse_json(r.output_json, {})  
      #    @h_run_parents[r.id] = JSON.parse(r.run_parents_json)
    end 
    
    ### look for runs corresponding to the file where is stored each metadata
    @h_store_runs={}
    Run.where(:id => @annots.map{|a| a.store_run_id}.uniq).all.each do |run|
      @h_store_runs[run.id] =run
    end
    
    ### add new metadata button
    @header_btns = "<button class='btn btn-sm btn-primary add_metadata_btn mr-1'><i class='fa fa-plus'></i> Add metadata</button>" if admin? 

  end

  def form_import_metadata
    h = {:status => 'new', :upload_type => 2, :project_key => @project.key, :project_id => @project.id, :user_id => (current_user) ? current_user.id : 1}
  #  @fu_inputs = Fu.where(h).all    
  #  if @fu_inputs.count > 0
  #    @fu_inputs.to_a.each do |fu_input|
  #      if fu_input.upload_file_name
  #        file_path = Pathname.new(APP_CONFIG[:upload_data_dir]) + fu_input.id.to_s + fu_input.upload_file_name
  #        File.delete file_path if File.exist?(file_path)
  #      end
  #      fu_input.destroy
  #    end
  #  end
    
#    h[:status] = 'new'
    @fu_input = Fu.new(h)
    @fu_input.save!

    project_dir = Pathname.new(APP_CONFIG[:user_data_dir]) + @project.user_id.to_s + @project.key
    parsing_dir = project_dir + "parsing"
    loom_file = parsing_dir + 'output.loom'
#    upload_dir = Pathname.new(APP_CONFIG[:data_dir]) +  'fus' + @fu.id.to_s
#    filepath = upload_dir + @fu.upload_file_name

    @h_json = {}

    cmd = "java -jar #{APP_CONFIG[:local_asap_run_dir]}/ASAP.jar -T ExtractMetadata -loom #{loom_file} -meta /col_attrs/CellID"
    tmp_json = `#{cmd}`.gsub(/\n/, '')
    if tmp_json
      vals = Basic.safe_parse_json(tmp_json, {})['values']
      @h_json[:cells] = (vals) ? vals.first(10) : []
    end

    cmd = "java -jar #{APP_CONFIG[:local_asap_run_dir]}/ASAP.jar -T ExtractMetadata -loom #{loom_file} -meta /row_attrs/Gene"
    tmp_json = `#{cmd}`.gsub(/\n/, '')
    if tmp_json
      vals = Basic.safe_parse_json(tmp_json, {})['values']
      @h_json[:genes] = (vals) ? vals.first(10) : []
    end

#    render :partial => 'import_metadata'

  end


  def get_step_import_metadata

    @h_statuses = {}
    Status.all.map{|s| @h_statuses[s.id] = s}
    #    @import_metadata_step = Step.where(:name => 'import_metadata', :version_id => @project.version_id).first
    @import_metadata_step = Step.where(:name => 'import_metadata', :docker_image_id => @asap_docker_image.id).first 
    @runs = Run.where(:project_id => @project.id, :step_id => @import_metadata_step.id).all
    @h_annots = {}
    @runs.map{|r| @h_annots[r.id] = []}
    
  #  parsing_step = Step.where(:version_id => @project.version_id, :name => 'parsing').first
    parsing_step = Step.where(:docker_image_id => @asap_docker_image.id, :name => 'parsing').first 
    parsing_run = Run.where(:project_id => @project.id, :step => parsing_step.id).first
    annots = Annot.where(:run_id => @runs.map{|r| r.id}, :store_run_id => parsing_run.id).all
    annots.map{|a| @h_annots[a.run_id].push a}
    
  end

  def get_step_summary
    @project_dir = Pathname.new(APP_CONFIG[:user_data_dir]) + @project.user_id.to_s + @project.key
    
    @h_project_steps = {}
    ProjectStep.where(:project_id => @project.id).all.select{|ps| ps.status_id}.each do |ps|
      @h_project_steps[ps.step_id]=ps
    end
    @list_steps =  @h_project_steps.keys.map{|step_id| @h_steps[step_id]}.select{|s| s.hidden == false}.sort{|a, b| a.rank <=> b.rank}
    @list_cards = []
   
    if @project.cloned_project_id
      @cloned_project = Project.where(:id => @project.cloned_project_id).first
    end

    @h_identifier_types = {}
    IdentifierType.all.map{|e| @h_identifier_types[e.id] = e}
    @h_exp_entries = {}
    @project.exp_entries.map{|e| @h_exp_entries[e.identifier_type_id] ||= []; @h_exp_entries[e.identifier_type_id].push e}

    @time_to_destroy = nil
    if @project.sandbox == true
      now = Time.now
#      d = Time.new(now.year, now.month, now.day, 0, 0, 0) + 1.day - now
      u = (s = @project.session) ? s.updated_at : @project.updated_at
      c = Time.new(u.year, u.month, u.day, 0, 0, 0) #+ 1.day - now
      @time_to_destroy = (c + 3.days + 1.hour) - Time.now# + d //one day after the max 2 days 
    end
    @h_articles = {}
    if @project.pmid
      Article.where(:pmid => @project.exp_entries.map{|ge| ge.pmid}).all.map{|a| @h_articles[a.pmid] = a}
    end
    if @project.doi
      Article.where(:doi => ([@project.doi.split(/\s*,\s*/)] | @project.exp_entries.map{|ge| ge.doi}).compact).all.map{|a| @h_articles[a.doi] = a}
    end
    @klay_data = []
    @log = ""
    h_runs = {}
    @runs = []
#    session[:store_run_id][@project.id] = params[:store_run_id].to_i if params[:store_run_id]
    tmp_runs = []
    if session[:store_run_id][@project.id] != 0
      tmp_runs = Run.select("runs.id, runs.lineage_run_ids").joins("join annots on (annots.ori_run_id = runs.id or annots.run_id = runs.id)").where(:project_id => @project.id, :annots => {:store_run_id => session[:store_run_id][@project.id]}).all# |
      #       Run.select("runs.id").joins("join annots on (annots.run_id = runs.id)").where(:project_id => @project.id, :annots => {:store_run_id => session[:filter_store_run_id]}).all
    else
      tmp_runs = Run.select("runs.id, runs.lineage_run_ids").where(:project_id => @project.id).all#.map{|r| [r.id] + r.lineage_run}
    end
    
    h_run_ids = {}
    h_run_ids_by_step_id = {}
    tmp_runs.each do |r|
      h_run_ids[r.id] = 1
      r.lineage_run_ids.split(",").each do |e|
        h_run_ids[e] =1
      end
    end
    @runs = Run.where(:id => h_run_ids.keys).all
    
    #    @runs = Run.where(:project_id => @project.id, :status_id => 3).all
    @runs.each do |run|
      h_runs[run.id] = run
      h_run_ids_by_step_id[run.step_id]||={}
      h_run_ids_by_step_id[run.step_id][run.status_id]||=[]
      h_run_ids_by_step_id[run.step_id][run.status_id].push run.id
    end
    if 1 == 0
      lineage_filter() ############### bypass lineage_filter
      h_filtered_run_ids = {}
      if session[:activated_filter][@project.id] == true
        list_filtered_run_ids = [] #@runs.map{|r| r.id}
        session[:filter_lineage_run_ids][@project.id].each do |run_id|
          h_filtered_run_ids[run_id] = 1
        end
        @runs.each do |run|
          if !h_filtered_run_ids[run.id] and (run.lineage_run_ids.split(",").map{|e| e.to_i} & session[:filter_lineage_run_ids][@project.id]).size > 0
            h_filtered_run_ids[run.id]=1 
            run.lineage_run_ids.split(",").map{|e| h_filtered_run_ids[e.to_i]=1}
          end
        end
        @list_filter_run_ids = session[:filter_lineage_run_ids][@project.id]
      end
    end
      
    #runs = @current_filtered_run_ids.map{|run_id| h_runs[run_id]}
   # parsing_step = Step.where(:version_id => @project.version_id, :name => 'parsing').first
    parsing_step = Step.where(:docker_image_id => @asap_docker_image.id, :name => 'parsing').first
    parsing_run = Run.where(:project_id => @project.id, :step => parsing_step.id).first

    @klay_data = [{:data => {:id => parsing_run.id, :rank => 1, :label => 'Parsing', :color => (@h_steps[parsing_step.id]) ? @h_steps[parsing_step.id].color : 'grey' }}]
    rank_diff = @h_steps[parsing_step.id].rank-1
    current_runs = [parsing_run]
  
    while(!current_runs.map{|r| r.children_run_ids}.join("").empty?) do
    #  @log+='bla'
      tmp_next_runs = []
      current_runs.each do |parent_run|
      #  @log+= parent_run.to_json
    #   next_runs = Run.where(:id => current_runs.children_run_ids}.split(",")).all
#        next_runs = parent_run.children_run_ids.split(",").select{|rid| h_filtered_run_ids[rid.to_i] or session[:activated_filter][@project.id] == false}.map{|rid| h_runs[rid.to_i]}.compact
        next_runs = parent_run.children_run_ids.split(",").map{|rid| h_runs[rid.to_i]}.compact.select{|run| run.status_id < 4}
    #   @log += next_runs.to_json
        next_runs.each do |run|
          if step = @h_steps[run.step_id]
            @klay_data.push({:data => {:id => run.id, :rank => step.rank-rank_diff, :node_text => step.rank-rank_diff, 
                                :label => #((step_id = run.step_id) ? @h_steps[step_id].label : "") + 
                                ("##{run.num} " + ((run.std_method_id) ? @h_std_methods[run.std_method_id].name : "")), :color => step.color}})
            @klay_data.push({:data => {:id => parent_run.id.to_s + "-" + run.id.to_s, :source => parent_run.id, :target => run.id}})
          end
        end
        tmp_next_runs += next_runs
      end
     #  @log+=tmp_next_runs.to_json
      current_runs = tmp_next_runs.uniq
    end

    h_vals = {
      '0' => '&epsilon;'
    }


    @h_runs = {}
    @runs2 = []
    
    @list_steps.select{|step| h_run_ids_by_step_id[step.id]}.each do |step|
      ps = @h_project_steps[step.id]
      card_text = []
      if step.multiple_runs == false
        run = Run.where(:project_id => @project.id, :step_id => step.id).first
        @runs2.push run
        @h_runs[run.id] = run
        if run and admin?
          card_text.push "##{run.id} "
        end
#        h_get_loom_output = {}
#        if step.name =='parsing'
#          output_file = @project_dir + 'parsing' + 'get_loom_from_hca.json'
#          h_get_loom_output = Basic.safe_parse_json(File.read(output_file), {}) if File.exist? output_file
#        end

        card_text.push display_status(@h_statuses[ps.status_id])
        card_text.push '<small>'
        card_text.push "<span id='created_time_#{run.id}' class='hidden'>#{run.submitted_at.strftime "%Y-%m-%d %H:%M:%S"}</span><span id='start_time_#{run.id}' class='hidden'>#{(run.start_time) ? run.start_time.strftime("%Y-%m-%d %H:%M:%S") : ""}</span>"
        waiting_class = (run.status_id == 1) ? '' : 'hidden'
        card_text.push "<span id='ongoing_wait_#{run.id}' class='nowrap #{waiting_class}'>Wait #{duration((Time.now-run.submitted_at).to_i)}</span><br/>"
        #  card_text.push h_get_loom_output['get_loom_time']
#        card_text.push (h_get_loom_output['get_loom_time']) ? "Getting Loom #{duration(h_get_loom_output['get_loom_time'].to_i)}" : ''
        card_text.push (run.pred_process_duration) ? "<br/>Estimated time #{(h_vals[run.pred_process_duration.to_s]) ? h_vals[run.pred_process_duration.to_s] : duration(run.pred_process_duration)}" : ''
        running_class = (run.status_id > 1) ? '' : 'hidden'        
        card_text.push ((run.duration) ? "<span class='nowrap #{running_class}'>Run #{duration(run.duration.to_i)}</span>" : ((run.status_id == 2) ? "<span id='ongoing_run_#{run.id}' class='nowrap'>Run #{duration((run.start_time) ? (Time.now-run.start_time).to_i : 0)}</span>" : nil))
        
        if run.max_ram
          #   card_text += ((h_res['time_idle']) ? "<span class='nowrap'>Idle #{duration(h_res['time_idle'].to_i)}</span>" : nil)
          card_text.push "<span class='nowrap'>Max. RAM #{display_mem(run.max_ram*1000)}</span>"
        end
        card_text.push '</small>'
        
      else
        if session[:store_run_id] == 0 
          h_nber_runs = Basic.safe_parse_json(ps.nber_runs_json, {})
          card_text = h_nber_runs.keys.select{|sid| @h_statuses[sid.to_i]}.map{|sid| display_status_runs(@h_statuses[sid.to_i], h_nber_runs[sid])}
        else
          card_text = h_run_ids_by_step_id[step.id].keys.select{|sid| @h_statuses[sid.to_i]}.map{|sid| display_status_runs(@h_statuses[sid.to_i], h_run_ids_by_step_id[step.id][sid.to_i].size)}
        end
      end

      h_card = {
        :card_id => "summary_step_card-#{step.id}",
        :card_class => "summary_step_card pointer",
        :body => "<h5 class='card-title'><i style='color:#{step.color}' class='fa fa-circle'></i> #{step.label}" + ((step.multiple_runs == false) ? "<small><span class='badge badge-light'>#{@h_std_methods[run.std_method_id].label}</span></small>" : '') + "</h5><p class='card-text'>#{card_text.join(" ")}</p>",
        :footer => "<small class='text-muted'>Last updated #{display_elapsed_time(ps.updated_at)}</small>"
      }
      @list_cards.push(h_card)
    end



  end

  def get_std_method_details(runs)
  #  @log5 ='' 
    h_std_method_attrs = {}
   # @log5+=">blbl"  + " "
    std_method_ids = runs.map{|run| run.std_method_id}.uniq
  #   @log5 =std_method_ids.to_json
  #  @log5+=@h_std_methods.keys.to_json
    std_method_ids.each do |std_method_id|
      std_method = @h_std_methods[std_method_id]
      if std_method
   #      @log5+=" " + std_method_id.to_s + " "

      #  @log5+=std_method_id.to_s
        h_res = Basic.get_std_method_attrs(std_method, @h_steps[std_method.step_id])
        h_std_method_attrs[std_method_id] = h_res[:h_attrs]
      end
    end

    return h_std_method_attrs
  end

  def get_h_files h_outputs, list_keys
    h_files = {}
    list_keys.select{|k| h_outputs[k] and ((admin? or e["admin"] == true ) or !e["admin"])}.each do |k|
      h_outputs[k].keys.each do |output_key|
        t = output_key.split(":")
        h_files[t[0]] ||= {
          :h_output => h_outputs[k][output_key],
          :datasets => []
        }
        dataset_name =  h_outputs[k][output_key]['dataset']
        h_annots[k] = {:annot_id => h_all_annots[dataset_name], :name => dataset_name} if h_outputs[k][output_key]['types'].include? 'annot' and  h_all_annots
        h_files[t[0]][:datasets].push({:name => t[1], :annot_id => (h_annots[k] && h_annots[k][:annot_id]), :dataset_size => h_outputs[k][output_key]['dataset_size']}) if t.size > 1
      end
    end
    return h_files
  end

  def get_h_links h_outputs, list_els
    h_links = {}
    list_els.select{|e| h_outputs[e["key"]] and ((admin? or e["admin"] == true ) or !e["admin"])}.each do |e|
      k = e["key"]
      h_outputs[k].keys.each do |output_key|
        t = output_key.split(":")
        h_links[k] ||= {
          :h_output => h_outputs[k][output_key]
        }
        #        dataset_name = h_outputs[k][output_key]['dataset']
        #        h_files[k][:datasets].push({:name => t[1], :annot_id => (h_annots[k] && h_annots[k][:annot_id]), :dataset_size => h_outputs[k][output_key]['dataset_size']}) if t.size > 1
      end
    end
    return h_links
  end

  def create_req_cards h_std_method_attrs, editable_project

    req_cards = []

    if @h_run_ids_by_req_id
      @h_run_ids_by_req_id.keys.sort{|a, b| @h_reqs[b].created_at <=>  @h_reqs[a].created_at}.each do |req_id|
        first_run =  @h_run_ids_by_req_id[req_id].first
        h_attrs = Basic.safe_parse_json(@h_reqs[req_id].attrs_json, {})
        if h_attrs['gene_set_id']
          h_attrs['gene_set'] = (@h_gene_sets and @h_gene_sets[h_attrs['gene_set_id'].to_i]) ? @h_gene_sets[h_attrs['gene_set_id'].to_i].label : 'NA'
        end
        
        if @h_run_ids_by_req_id[req_id].size > 1
          req = @h_reqs[req_id]
          top_right = ''
          
          max_run_time = 0
          if @project.public == true
            @h_run_ids_by_req_id[req_id].each do |run_id|
              max_run_time = (@h_all_runs[run_id].start_time and @h_all_runs[run_id].duration) ? (@h_all_runs[run_id].start_time + @h_all_runs[run_id].duration) : Time.now
              break if @project.frozen_at < max_run_time
            end
          end
          if action_name == 'get_step'
            top_right = [((editable_project and (@project.public == false or @project.frozen_at < max_run_time) and ((current_user and (admin? or [req.user_id, @project.user_id].include? current_user.id)) or @project.sandbox == true)) ? "<div id='destroy-req_#{req.id}' class='btn_destroy-req'><i class='fa fa-times-circle'></i></div>" : "") +
                         ((@project.public == true) ? ((@project.frozen_at > max_run_time) ? " <span class='' title='Secured analysis - cannot be modified by anyone' style='color:green' ><i class='fa fa-lock'></i></span>" : " <span class='' title='Unsecured analysis - can be modified by the owner' style='color:orange' ><i class='fa fa-unlock'></i></span>") : '')].join("")
          end
          
          h_card = {
            :card_id => "req_card_#{req_id}",
            :card_class => "req_card",
            :body => ["<div class='top-right-buttons'>#{top_right}</div>Batch #{std_method = @h_std_methods[@h_reqs[req_id].std_method_id]; std_method.label} <p class='card-title'>#{display_sum_status_short @h_statuses, @h_all_runs,  @h_run_ids_by_req_id[req_id]}" + "</p>",
                      #<span id='show_run_#{run.id}' class='show_link pointer'><b>##{run.num}</b> #{(step = @h_steps[run.step_id] and step.multiple_runs == false) ? step.label : ((std_method = @h_std_methods[run.std_method_id]) ? ((!params[:step_id]) ? (step.label + " ") : "") + std_method.label : 'NA')}</span></p>",                                                         #                  run.lineage_run_ids,                                                             
                      #            h_attrs.to_json +   
                      "<p class='sub-run_card'>Parameters</p>",
                      display_run_attrs(req, h_attrs, h_std_method_attrs, {})
                     ].join(""),
            :footer =>
            "<div class='float-left text-center' style='width:100%;margin-top:-35px;font-style:italic'><small>Click me for details</small></div>" +
            #        "<div class='float-right' style='margin-top:-50px'><button id='show_details_#{run.id}' class='btn btn-secondary btn-sm show_link'>" + ((@h_attrs["show_run_btn_label"]) ? @h_attrs["show_run_btn_label"]  : "Details") + "</button>" +                                                                                                
            #        ((@project.public == true) ? ((@project.frozen_at > run.start_time + run.duration) ? " <span class='' title='Secured analysis - cannot be modified by anyone' style='color:green' ><i class='fa fa-lock'/></span>" : " <span class='' title='Unsecured analysis - can be modified by the owner' style='color:orange' ><i class='fa fa-unlock'/></span>") : '') +                                                                                                                                            #        "</div>" +                                                                                                                                                     
            "<small class='text-muted'>" +
            ((admin?) ? "##{req_id}, "  : "") +
            ["<span class='nowrap'>#{display_date_short(req.created_at)}</span>",
             "created by #{(is_admin? @h_users[req.user_id]) ? 'Admin' : @h_users[req.user_id].email.split(/\@/).first}"].compact.join(", ") +
            "</small>"
          }
          req_cards.push(h_card)
        end
      end
    end
    return req_cards

  end

  def create_run_cards runs, sel_req_id

#    ## get dashboard_cards
#    @h_dashboard_card={}
#    step_ids = runs.map{|r| r.step_id}.uniq
#    step_ids.map{|sid| @h_steps[sid]}.each do |step|
#      @h_dashboard_card[step.id] = JSON.parse(step.dashboard_card_json)
#    end      

    

    ## get std_method details
    h_std_method_attrs = get_std_method_details(runs)
    
#    list_cards = []
    editable_project = editable?(@project)

    h_all_annots = {}
    if runs
      Annot.where(:project_id => @project.id, :run_id => runs.map{|r| r.id}).all.each do |a|
        h_all_annots[a.name] = a.id
      end
    end

    @h_users = {}
    User.where(:id => runs.map{|r| r.user_id}.uniq).all.map{|u| @h_users[u.id] = u}

    list_cards = []
    req_cards = (!sel_req_id) ? create_req_cards(h_std_method_attrs, editable_project) : [] #if !sel_req_id
    #     req_cards =  create_req_cards(h_std_method_attrs, editable_project)
    runs.select{|r| !@h_run_ids_by_req_id or (!sel_req_id and @h_run_ids_by_req_id[r.req_id].size == 1) or 
      r.req_id == sel_req_id}.sort{|a, b| b.created_at <=> a.created_at}.each do |run|
      #    if !step_dir
      step_dir = Pathname.new(APP_CONFIG[:user_data_dir]) + @project.user_id.to_s + @project.key + @h_steps[run.step_id].name
      output_dir = (@h_steps[run.step_id].multiple_runs == true) ? (step_dir + run.id.to_s) : step_dir
      #    end
      output_json_file = output_dir + "output.json"
      output_logfile = output_dir + "output.log"
      begin
        h_attrs = (run.attrs_json) ? JSON.parse(run.attrs_json) : {}
        h_res = (File.exist? output_json_file) ? JSON.parse(File.read(output_json_file)) : {}
        h_outputs = (run.output_json.match(/^\{/)) ? JSON.parse(run.output_json) : {}
      rescue
      end

      if h_attrs['gene_set_id']
        h_attrs['gene_set'] = (@h_gene_sets and @h_gene_sets[h_attrs['gene_set_id'].to_i]) ? @h_gene_sets[h_attrs['gene_set_id'].to_i].label : 'NA'
      end

      run_time = (run.start_time and  run.duration) ? (run.start_time + run.duration) : Time.now
      top_right = ''
      if action_name == 'get_step'
        top_right = [((editable_project and (@project.public == false or @project.frozen_at < run_time) and ((current_user and (admin? or [run.user_id, @project.user_id].include? current_user.id))) or @project.sandbox == true) ? "<div id='destroy-run_#{run.id}' class='btn_destroy-run'><i class='fa fa-times-circle'></i></div>" : "") + 
                     ((@project.public == true) ? ((@project.frozen_at > run_time) ? " <span class='' title='Secured analysis - cannot be modified by anyone' style='color:green' ><i class='fa fa-lock'></i></span>" : " <span class='' title='Unsecured analysis - can be modified by the owner' style='color:orange' ><i class='fa fa-unlock'></i></span>") : '')].join("")
      end
      
      h_files = {}
      h_links = {}
      h_annots = {}
#      if run.step_id != 16
      if @h_dashboard_card[run.step_id] and @h_dashboard_card[run.step_id]["output_links"]        
        h_links = get_h_links(h_outputs, @h_dashboard_card[run.step_id]["output_links"])
      end
      
      if @h_dashboard_card[run.step_id] and @h_dashboard_card[run.step_id]["output_files"]
        list_p = @h_dashboard_card[run.step_id]["output_files"]#.map{|e| e['key']} #|
          #    @h_dashboard_card[run.step_id]["output_links"].map{|e| e["key"]}
        
         list_p.select{|e| h_outputs and h_outputs[e["key"]] and ((admin? or e["admin"] == true ) or !e["admin"])}.each do |e|
          k = e["key"]
          h_outputs[k].keys.each do |output_key| 
            t = output_key.split(":")
            h_files[t[0]] ||= {
              :h_output => h_outputs[k][output_key],
              :datasets => []
            }  
            dataset_name =  h_outputs[k][output_key]['dataset'] 
            h_annots[k] = {:annot_id => h_all_annots[dataset_name], :name => dataset_name} if h_outputs[k][output_key]['types'].include? 'annot' and  h_all_annots
            h_files[t[0]][:datasets].push({:name => t[1], :annot_id => (h_annots[k] && h_annots[k][:annot_id]), :dataset_size => h_outputs[k][output_key]['dataset_size']}) if t.size > 1 
#            display_download_btn(run, h_outputs[k][output_key])}}.flatten.join(" ")
          end
        end
      end
      
#      t =[]
      graphical_outputs = []
#      annots = []
      h_files.each_key do |k|
        #        t.push h_files[k][:h_output]['types']
        if h_files[k][:h_output]['types'] 
          if (h_files[k][:h_output]['types'] & ["plotly_plot_json", "plotly_json"]).size > 0
            graphical_outputs.push k
 #         elsif h_files[k][:h_output]['types'].include? "annot"
 #           annots.push k #.download_text
          end
        end
      end

      h_vals = {
        '0' => '&epsilon;'
      }

      estimated_time_txt = (run.pred_process_duration) ? "Estimated #{(h_vals[run.pred_process_duration.to_s]) ? h_vals[run.pred_process_duration.to_s] : duration(run.pred_process_duration)} - " : ''

      h_card = {
        :card_id => "run_card_#{run.id}",
        :card_class => "run_card",
        :body => ["<div class='top-right-buttons'>#{top_right}</div><p class='card-title'>#{display_status_short @h_statuses[run.status_id]}" + display_run2(run, @h_steps[run.step_id], @h_std_methods[run.std_method_id]) + "</p>", 
#<span id='show_run_#{run.id}' class='show_link pointer'><b>##{run.num}</b> #{(step = @h_steps[run.step_id] and step.multiple_runs == false) ? step.label : ((std_method = @h_std_methods[run.std_method_id]) ? ((!params[:step_id]) ? (step.label + " ") : "") + std_method.label : 'NA')}</span></p>",
                  #                  run.lineage_run_ids, 
                  #            h_attrs.to_json +                                                                                                                                
                  "<p class='sub-run_card'>Parameters</p>",
                  display_run_attrs(run, h_attrs, h_std_method_attrs, {}),
                  ((run.status_id == 3 and @h_dashboard_card[run.step_id]["output_values"] and @h_dashboard_card[run.step_id]["output_values"].size > 0) ? ("<p class='sub-run_card'>Output summary</p><p class='card-text'>" + @h_dashboard_card[run.step_id]["output_values"].select{|e| h_res[e["key"]]}.map{|e| "<span class='badge badge-info'>#{e["label"]}:#{(h_res[e["key"]]) ? h_res[e["key"]] : 'NA'}</span>"}.join(" ") + "</p>") : ''),
                  (graphical_outputs.size > 0) ? "<i class='af-scatter_plot'></i> " +  
                  " graphical outputs available<br/><br/>" : '',
                  
                  # (h_files.keys.size > 0) ? ("<p class='card-text'>" +  + "</p>") : ""),
                  #   run.duration.to_json +                                                                                                                                                                 
                  #   run.output_json +                                                                                                                                                                      
                  #((@h_dashboard_card[run.step_id]["output_files"]) ? ("<p class='card-text'>" +  @h_dashboard_card[run.step_id]["output_files"].select{|e| h_outputs[e["key"]] and ((admin? or e["admin"] == true ) or !e["admin"])}.map{|e| k = e["key"]; h_outputs[k].keys.map{|k2| display_download_btn(run, h_outputs[k][k2])}}.flatten.join(" ") + "</p>") : ""),
                  ((h_files.keys.size > 0) ? ("<p class='sub-run_card'>Results</p><p class='card-text'>" + h_files.keys.map{|k| display_download_btn(run, h_files[k])}.join(" ") + "</p>") : ""),
                #  display_specific_output_download_btn(run, @h_steps),
                   (@h_dashboard_card[run.step_id]["output_links"]) ? @h_dashboard_card[run.step_id]["output_links"].map{|e| display_specific_download_btn(run, e, h_links)}.join("") : '',
   #                class='btn btn-sm btn-outline-secondary white-bg download_file_btn' #{title}><div class='float-right'><sub>#{display_mem(h_output["size"])}</sub></div><div class='download_btn_text'>
                  ((h_annots.keys.size > 0) ? h_annots.keys.map{|k| "<button id='download_text_#{h_annots[k][:annot_id]}' type='button' class='btn btn-sm btn-outline-secondary white-bg download_text' title='Download Tab-separated result file'>#{h_annots[k][:name].split("/")[2][1..-1]}.tsv</button>"}.join(" ") : ''),
                  #                 t.to_json,
                  #((run.status_id == 3 and h_res['warnings']) ? h_res['warnings'].map{|w| ("<p class='text-warning text-truncate' title='#{w['name'] || 'NA'} #{w['description'] || 'NA'}'>" + w['name'] + "</p>")}.join(" ") : ''),
                  #                  h_res['warnings'].to_json, run.status_id, 
                  ((run.status_id == 3 and h_res['warnings']) ? h_res['warnings'].map{|e| 
                     if e.is_a? Hash
                       "<p class='text-warning text-truncate' title=\"#{e['name']}. #{e['description']}\">#{e['name']}</p>"
                     else
                       "<p class='text-warning text-truncate' title='#{e}'>#{e}</p>"
                     end
                     }.join(" ") : ''),
                  (([4, 5].include?(run.status_id) and h_res['displayed_error'].is_a? Array) ? ("<p class='card-text'>" + ((h_res['displayed_error']) ? h_res['displayed_error'].map{|e| 
                                                                        help = (e and e.match(/Probably out of RAM/) or e.match(/Not enough memory/)) ? "<a href='#{tutorial_home_index_path({:t => 'out_of_ram'})}'>Help</a>" : ''
                                                                        "<p class='text-danger text-truncate' title=\"#{e}\">#{e} <small>#{help}</small></p>"
                                                                      }.join(" ") : '')) : "" ),
                  (([4, 5].include?(run.status_id) and admin?) ? "<div class='float-right'><button id='restart_#{run.id}' type='button' class='btn btn-primary restart-btn'>Restart</button></div>" : '')
                  #,
                 # ((h_res['displayed_error'] and h_res['displayed_error'].select{|e| e.match(/Probably out of RAM/)}.size > 0) ? "<a href='#{tutorial_home_index_path({:t => 'out_of_ram'})}'>Help</a>" : ""),
                  #,
                #  ((admin?) ? "<button id='run_#{run.id}_#{h_outputs[k][f]['onum']}' type='button' class='btn btn-sm btn-outline-secondary download_file_btn'>Log file</button>" : "")
                #  "<div class='float-right'><button id='show_details_#{run.id}' class='btn btn-primary btn-sm show_link'>Details</button></div>"
                 ].join(""),
        
        :footer =>
        "<div class='float-left text-center' style='width:100%;margin-top:-35px;font-style:italic'><small>Click me for details</small></div>" +
#        "<div class='float-right' style='margin-top:-50px'><button id='show_details_#{run.id}' class='btn btn-secondary btn-sm show_link'>" + ((@h_attrs["show_run_btn_label"]) ? @h_attrs["show_run_btn_label"]  : "Details") + "</button>" +
#        ((@project.public == true) ? ((@project.frozen_at > run.start_time + run.duration) ? " <span class='' title='Secured analysis - cannot be modified by anyone' style='color:green' ><i class='fa fa-lock'/></span>" : " <span class='' title='Unsecured analysis - can be modified by the owner' style='color:orange' ><i class='fa fa-unlock'/></span>") : '') + 
#        "</div>" + 
        "<small class='text-muted'>" +
        "##{run.id}, " + #((admin?) ? "##{run.id}, "  : "") +
        ["<span class='nowrap'>#{display_date_short(run.created_at)}</span><span id='created_time_#{run.id}' class='hidden'>#{run.submitted_at.strftime "%Y-%m-%d %H:%M:%S"}</span><span id='start_time_#{run.id}' class='hidden'>#{(run.start_time) ? run.start_time.strftime("%Y-%m-%d %H:%M:%S") : ""}</span>",
         ((run.waiting_duration) ? "<span class='nowrap'>Wait #{duration(run.waiting_duration.to_i)}</span>" : ((run.status_id == 1) ? "<span id='ongoing_wait_#{run.id}' class='nowrap'>Wait #{duration((Time.now-run.submitted_at).to_i)}</span>" : nil)), 
         ((run.duration and run.status_id !=2) ? "<span class='nowrap'>Run #{duration(run.duration.to_i)}</span>" : (([1, 2].include? run.status_id) ? "<br/>#{estimated_time_txt}<span id='ongoing_run_#{run.id}' class='nowrap'>Run #{duration((run.start_time) ? (Time.now-run.start_time).to_i : 0)}</span>" : nil)),
         ((h_res.is_a? Hash and h_res['time_idle']) ? "<span class='nowrap'>Idle #{duration(h_res['time_idle'].to_i)}</span>" : nil),  
         ((run.max_ram) ? "<span class='nowrap'>Max. RAM #{display_mem(run.max_ram*1000)}</span>" : nil),
         ((run.pred_max_ram) ? "<span class='nowrap'>Pred. max. RAM #{display_mem(run.pred_max_ram*1000)}</span>" : nil),
        "created by #{(is_admin? @h_users[run.user_id]) ? 'Admin' : @h_users[run.user_id].email.split(/\@/).first}"].compact.join(", ") +
        #.join(", ") 
         "</small>" #+
#        " lineage: #{run.lineage_run_ids}"
        #"<button type='button' class='btn btn-primary'>Details</button>"                                                                                                                           
      }
      list_cards.push(h_card)
    end
#    end
    return {:run_cards => list_cards, :req_cards => req_cards}
  end

  def lineage_filter

    if params[:store_run_id]
      session[:store_run_id][@project.id] = params[:store_run_id].to_i
    end

    @h_all_runs = {}
    @current_filtered_run_ids = []
    tmp_run_ids = []
    @all_run_ids = Run.select("runs.id, runs.lineage_run_ids").where(:project_id => @project.id, :step_id => @step.id).all
    if session[:store_run_id][@project.id] != 0 
      tmp_run_ids = Run.select("runs.id, runs.lineage_run_ids").joins("join annots on (annots.ori_run_id = runs.id or annots.run_id = runs.id)").where(:project_id => @project.id, :annots => {:store_run_id => session[:store_run_id][@project.id]}).all
    else
      tmp_run_ids = @all_run_ids
    end
    
    tmp_runs = Run.where(:id => tmp_run_ids.map{|e| [e.id] + e.lineage_run_ids.split(",")}.flatten.uniq, :step_id => @step.id).all
    @current_filtered_run_ids = tmp_runs.map{|r| 
      @h_all_runs[r.id]=r;
      #      lineage_run_ids = r.lineage_run_ids.split(",").map{|rid| rid.to_i}
      #      lineage_run_ids.map{|rid| }
      #      [r.id] + r.lineage_run_ids.split(",").map{|rid| rid.to_i}}.flatten.uniq
      r.id}

    if (1 == 0)
      
      @h_all_lineage_run_ids = {}
      @h_all_runs = {}
      @current_run_ids = []
      Run.joins("join steps on (runs.step_id = steps.id)").where(["project_id = ?", @project.id]).order("id desc").all.each do |run|
        @h_all_runs[run.id] = run
        # if active_run.status_id == 3
        @h_all_lineage_run_ids[run.id] = (run.lineage_run_ids) ? run.lineage_run_ids.split(",").map{|e| e.to_i} : []
        # end
        @current_run_ids.push(run.id) if action_name == 'form_select_input_data' or run.step_id == @step.id or @step.name == 'summary' #@h_attrs['force_run_filter']
      end
      
      #  @log = ''
      
      if params[:activated_filter]
        @log += 'bla'
        session[:activated_filter][@project.id] = (params[:activated_filter] == '1') ? true : false
      end
      
      if params[:add_lineage_run_ids]
        params[:add_lineage_run_ids].split(",").map{|e| e.to_i}.each do |run_id|
          session[:filter_lineage_run_ids][@project.id].push(run_id) if !session[:filter_lineage_run_ids][@project.id].include?(run_id)
        end
      elsif params[:del_lineage_run_ids]
        params[:del_lineage_run_ids].split(",").map{|e| e.to_i}.each do |run_id|
          #        session[:filter_lineage_run_ids].delete(run_id) if session[:filter_lineage_run_ids].include?(run_id)                           
          #       @log+= "TREAT_session #{session[:filter_lineage_run_ids].to_json}"                                                
          to_delete = {}
          session[:filter_lineage_run_ids][@project.id].each do |run_id2|
            if (@step.name == 'summary' and run_id == run_id2) or (@step.name != 'summary' and ((@h_all_lineage_run_ids[run_id2] and @h_all_lineage_run_ids[run_id2].include? run_id) or run_id == run_id2))
              to_delete[run_id2] = 1
            end
          end
          session[:filter_lineage_run_ids][@project.id].reject!{|e| to_delete[e]} ## delete run_ids
        end
      end
      
      ## define filters based on the session variable                                                                                                                                                            
      @filter_lineage_run_ids = session[:filter_lineage_run_ids][@project.id].dup
      
      ## compute implicit filters                                                                                                                                                                                
      @implicit_filter_lineage_run_ids = []
      @filter_lineage_run_ids.each do |run_id|
        #  @log +="HERE#{run_id} "
        tmp_lineage = @h_all_lineage_run_ids[run_id].dup
        if tmp_lineage
          tmp_lineage.shift
          @implicit_filter_lineage_run_ids |= tmp_lineage
        end
      end
      #   @log +="Implicit filters: " + @implicit_filter_lineage_run_ids.to_json
      
      
      ## add implicit filters to session                 
      #    @implicit_filter_lineage_run_ids.each do |run_id|                   
      #      session[:filter_lineage_run_ids].push(run_id) if !session[:filter_lineage_run_ids].include? run_id                            
      #    end                                                                                                                                                                                                      
      ##filter out from filters run_ids that do not exist anymore (in this step context)                                                                                                                                                                                                                                                                                                          
      @filter_lineage_run_ids.reject!{|run_id| tmp_run = @h_all_runs[run_id]; !tmp_run or @h_steps[tmp_run.step_id].rank >= @step.rank}
      
      ## filter out from implicit_filters run_ids that do not exist anymore                                                                                                                                      
      @implicit_filter_lineage_run_ids.reject!{|run_id| tmp_run = @h_all_runs[run_id]; !tmp_run or @h_steps[tmp_run.step_id].rank >= @step.rank}
      
      ## compute children of the latest nodes                                                                                                                                                                    
      @list_filter_run_ids = @implicit_filter_lineage_run_ids | @filter_lineage_run_ids
      
      ## deactivated the filter if no more filter applicatble (except if click on filter button)                                                                                                                 
      if session[:filter_lineage_run_ids][@project.id].size == 0 and params[:activated_filter] != '1'
        session[:activated_filter][@project.id] = false
      end
      
      ## define the list of runs after applying filters                                                                                                                                                          
      @current_filtered_run_ids = []
      # @log += "FIL: " + @list_filter_run_ids.to_json
      if session[:activated_filter][@project.id] == true and @list_filter_run_ids.size > 0
        @max = 0
        @current_run_ids.map{|run_id| tmp = @h_all_lineage_run_ids[run_id] & @list_filter_run_ids; @max = tmp.size if tmp and @max < tmp.size }
        #   @log+='CUR_ini: ' +  @current_run_ids.to_json
        if @max > 0
          @current_filtered_run_ids = @current_run_ids.select{|run_id| tmp = @h_all_lineage_run_ids[run_id] & @list_filter_run_ids; tmp and @log+="#{@max} #{tmp.size} >= [#{@h_all_lineage_run_ids[run_id].size}, #{@list_filter_run_ids.size}].min" and  tmp.size == @max} # [@h_all_lineage_run_ids[run_id].size, @list_filter_run_ids.size].min}
        else
          @current_filtered_run_ids = []
        end
        #      if params[:activated_filter] != '1' and @current_filtered_run_ids == @current_run_ids
        #        @log +='blo'
        #        session[:activated_filter] = false                        
        #        @filter_lineage_run_ids = [] 
        #        @implicit_filter_lineage_run_ids = []
        #      end
        
      else
        #      @log +='bliiiii'
        @current_filtered_run_ids = @current_run_ids
        #      @log += @current_filtered_run_ids.to_json
      end
      #@log += "CUR: " + @current_filtered_run_ids.to_json
      
      #    if @current_filtered_run_ids == @current_run_ids and @filter_lineage_run_ids.size ==0 and @implicit_filter_lineage_run_ids.size == 0    
      #      @log +='blo'                      
      #      session[:activated_filter] = false      
      #    end      
      
      #   else  
      #      @current_filtered_run_ids = @current_run_ids       
      #   end                   
      
      ## define the uniq list of runs in the lineage of filtered runs                                                                                                                                            
      @all_lineage_run_ids=[]
      #    @current_run_ids.select{|run_id| @h_all_lineage_run_ids[run_id]}.each do |run_id|                                                                                                                     
      @current_run_ids.each do |run_id|
        tmp_lineage =  @h_all_lineage_run_ids[run_id].dup
        if tmp_lineage
          tmp_lineage.shift ## remove parsing              
          # tmp_lineage_run_ids.each do |run_id|          
          #   @h_union_lineage_run_ids[run_id.to_i] = 1          
          # end                                 
          @all_lineage_run_ids |= tmp_lineage
        end
      end
      
      ## check run_ids that are not in session                                                                                                                                                                   
      @h_lineage_run_ids_by_step_id = {}
      
      #    if  @filter_lineage_run_ids.size != 0         
      @all_lineage_run_ids.each do |run_id|
        #  if !@local_filter_lineage_run_ids.include? run_id and !((@h_all_lineage_run_ids[run_id] & @local_filter_lineage_run_ids).size > 0)       
        #  @local_filter_lineage_run_ids.push(run_id)                 
        #  session[:filter_lineage_run_ids].push(run_id)                                                                                                                                                         
        if !@filter_lineage_run_ids.include? run_id and !@implicit_filter_lineage_run_ids.include? run_id and (@step.name != 'summary' or !session[:filter_lineage_run_ids][@project.id].include?(run_id))
          if @h_all_runs[run_id]
            @h_lineage_run_ids_by_step_id[@h_all_runs[run_id].step_id] ||= []
            @h_lineage_run_ids_by_step_id[@h_all_runs[run_id].step_id].push run_id
          end
        end
      end
      #    else                    
      #      @all_lineage_run_ids.each do |run_id|                
      #        @h_lineage_run_ids_by_step_id[@h_all_runs[run_id].step_id] ||= []    
      #        @h_lineage_run_ids_by_step_id[@h_all_runs[run_id].step_id].push run_id                     
      #      end                                  
      #    end         
      
      ## compute children of the latest nodes                                                                                                                                                                    
      @list_filter_run_ids = @implicit_filter_lineage_run_ids | @filter_lineage_run_ids
      
      ## sort filters
      @list_filter_run_ids.sort!{|a, b| a2 = @h_all_runs[a]; b2 = @h_all_runs[b]; as = a2.step_id; bs = b2.step_id;  [@h_steps[as].rank, a2.num] <=> [@h_steps[bs].rank, b2.num] }
      
      @h_children_run_ids={}
      @h_lineage_run_ids_by_step_id.each_key do |step_id|
        @h_lineage_run_ids_by_step_id[step_id].each do |run_id|
          if @list_filter_run_ids.include? @h_all_lineage_run_ids[run_id].last
            @h_children_run_ids[run_id]=1
          end
        end
      end
      
      ## check if the filter should be disabled                                                                                                                                         
      @disable_filter = true
      #  @h_lineage_run_ids_by_step_id.each_key do |step_id| 
      #   if @h_lineage_run_ids_by_step_id[step_id].size > 0             
      #     @disable_filter = false          
      #     break     
      #   end 
      #  end 
      
      @current_run_ids.each do |run_id|
        if @h_all_lineage_run_ids[run_id] and @h_all_lineage_run_ids[run_id].size > 1
          @disable_filter = false
        end
      end
      
      ### set flag to temporarily not display the filter selection box
      @flag_nothing_to_filter = (@current_filtered_run_ids == @current_run_ids and @filter_lineage_run_ids.size ==0 and @implicit_filter_lineage_run_ids.size == 0) or ( @list_filter_run_ids.size == 0 and params[:activated_filter] != '1')
      
      
    #    @lineage_runs = Run.where(:id =>session[:filter_lineage_run_ids]).all 
    #@lineage_runs = session[:filter_lineage_run_ids].     
    end
  end

  def check_session_params runs, h_attr
    ## evaluate if there are runs where all params
    @log3 = ''
    @filter_runs = runs.select{|r| r.status_id == 3 and h_attr[r.id]["nber_dims"] == session[:dr_params][@project.id][:nber_dims] and r.std_method_id == session[:dr_params][@project.id][:std_method_id]}
   
    if @filter_runs.size == 0
      new_ref = runs.first
      session[:dr_params][@project.id][:nber_dims] = @h_attrs_by_run_id[new_ref.id]["nber_dims"]
      session[:dr_params][@project.id][:std_method_id] = new_ref.std_method_id
    end
    
  end

#  def get_step_cell_filtering
#  end

  def get_step_cell_scatter
    
#    @log3= 'b ' + session[:csp_params][@project.id][:displayed_nber_dims].to_json  + "-" + session[:csp_params][@project.id][:std_method_id].to_json
    @error_message = ''
    ## set session for std_method_id and nber_dims                                                                                                                           
    @h_changed = {}
    session[:csp_params][@project.id][:nber_dims]||=2
    [:dim1, :dim2, :dim3, :displayed_nber_dims, :annot_id].select{|e| params[e]}.each do |e|
      if session[:csp_params][@project.id][e] != params[e].to_i and  params[e].to_i != 0
        @h_changed[e]=1
      end
      session[:csp_params][@project.id][e]= params[e].to_i if params[e].to_i != 0
    end


logger.debug("CSP_PARAMS: " + session[:csp_params][9728].to_json)    
    h_runs = {}
    @h_std_method_attrs={}
    ## define default annot_id                                                                                                                        
    h_query = {
      :project_id => @project.id, 
      :dim => 1, 
      :data_types => {:name => 'NUMERIC'}
    }
    h_query[:store_run_id] = session[:store_run_id][@project.id] if session[:store_run_id][@project.id] != 0 
     logger.debug("totq:" + h_query.to_json)
    
    @annots = Annot.joins(:data_type).where(h_query).all.select{|a| a.nber_rows and a.nber_rows > 1 and a.nber_cols > 1}
    logger.debug("totr: " + @annots.map{|a| a.id}.to_json)
    @annots.sort!{|a, b| [a.step_id, a.store_run_id, a.name] <=> [b.step_id, b.store_run_id, b.name] }
    h_annots = {}
    @annots.map{|a| h_annots[a.id] = a}
    if @h_changed[:annot_id] and default_annot = h_annots[session[:csp_params][@project.id][:annot_id]]
      @default_annot = default_annot
    end
    logger.debug("tota:" + @default_annot.to_json)
    if @annots.size > 0 and !params[:fixed_session]
      session[:csp_params][@project.id][:annot_id] ||= @annots.first
    end
    logger.debug("totz:" + session[:csp_params][@project.id][:annot_id].to_json) 
    @default_annot ||= h_annots[session[:csp_params][@project.id][:annot_id]]# @annots.first
    logger.debug("toti:" + @default_annot.to_json)

    @default_annot ||= @annots.first
    logger.debug("totu:" + @default_annot.to_json)
   @h_store_runs = {}                                                                                                                                              
    Run.where(:id => @annots.map{|a| a.store_run_id}.uniq).all.map{|r| @h_store_runs[r.id] = r}
    @all_cell_annots = Annot.where(:project_id => @project.id, :dim => 1).all
    #    params[:partial] = "cell_scatter"

    if (@h_changed[:annot_id] == 1 or @h_changed[:displayed_nber_dims] == 1) and session[:csp_params][@project.id][:displayed_nber_dims] == 3
      session[:csp_params][@project.id][:dim3] = 3
    end
    
    @header_btns = "<div class='btn-group ml-2' role='group'>
    <button id='simple_mode-btn' type='button' class='btn btn-" + ((session[:csp_params][@project.id][:mode] == '1') ? 'secondary' : 'primary') + " mode_btn'>Simple</button>
    <button id='advanced_mode-btn' type='button' class='btn btn-" + ((session[:csp_params][@project.id][:mode] == '2') ? 'primary' : 'secondary') + " mode_btn'>Advanced</button>
  </div>" if admin?

    params[:upd_plot] = 1
  end    
  
  def get_step_dim_reduction
    
    @log3= 'b ' + session[:dr_params][@project.id][:displayed_nber_dims].to_json  + "-" + session[:dr_params][@project.id][:std_method_id].to_json
    @error_message = ''
    ## set session for std_method_id and nber_dims
    h_changed = {}
    session[:dr_params][@project.id][:nber_dims]||=2
    [:dim1, :dim2, :dim3, :std_method_id, :displayed_nber_dims, :run_id].select{|e| params[e]}.each do |e|
      if session[:dr_params][@project.id][e] != params[e].to_i and  params[e].to_i != 0
        h_changed[e]=1
      end
#      @error_message = session[:dr_params][@project.id][:std_method_id]
      
      session[:dr_params][@project.id][e]= params[e].to_i if params[e].to_i != 0
    end
    
    #    @log = "bla"
    h_runs = {}
    @h_std_method_attrs={}
    
    if @runs and @runs.size > 0
      ## filter only successful runs
      @successful_runs = @runs.select{|r| r.status_id == 3}
      
      ## get attrs for all runs
      @h_attrs_by_run_id = {}
     # begin
      @runs.each do |r|
        h_runs[r.id] = r
        @h_attrs_by_run_id[r.id]=Basic.safe_parse_json(r.attrs_json, {})
      end
      # rescue
      # end
      
      #    @log4 = @runs.map{|r| [r.id, r.attrs_json]}.to_json
      
      ## check session parameters and change them if not valid anymore
      #      check_session_params(@runs, @h_attrs_by_run_id)
      
      ## filter runs by attr nber_dims
      
      # successful_runs_nber_dims = @successful_runs.select{|r| @h_attrs_by_run_id[r.id]['nber_dims'] == session[:dr_params][@project.id][:nber_dims]}
      #    @successful_runs = @successful_runs.select{|r| @h_attrs_by_run_id[r.id]['nber_dims'] == session[:dr_params][@project.id][:nber_dims]}
      #      @log = ":" + session[:dr_params][@project.id][:nber_dims].to_json + "-"
      #      @log = ''
      #      @finished_runs = 
      #@log = @successful_runs.to_json
      ## define default run_id
      
      if !params[:partial] and  run = h_runs[params[:run_id].to_i]
        @default_run_id = params[:run_id].to_i
        session[:dr_params][@project.id][:std_method_id]= run.std_method_id
        @log3+= "-->#{@default_run_id}<--"
        if ['tsne', 'umap'].include? @h_std_methods[run.std_method_id].name
          session[:dr_params][@project.id][:displayed_nber_dims] = @h_attrs_by_run_id[run.id]["nber_dims"].to_i
        end
      else

        
        if params[:run_id] and h_changed[:run_id]
          run = h_runs[params[:run_id].to_i]
          session[:dr_params][@project.id][:std_method_id]||= run.std_method_id
          @default_run_id = params[:run_id].to_i
          @log3+='c'
          #      else
        end
        
        s = session[:dr_params][@project.id]
        
        #      if !h_changed[:run_id] and !h_changed[:std_method_id] and !h_changed[:displayed_nber_dims]
        #        @default_run_id = session[:dr_params][@project.id][:run_id]
        #        successful_runs =  @successful_runs.select{|r| s[:std_method_id] == h_runs[@default_run_id].std_method_id and 
        #          (['pca', 'inc_pca'].include?(@h_std_methods[h_runs[@default_run_id].std_method_id].name) or s[:displayed_nber_dims] == @h_attrs_by_run_id[@default_run_id]["nber_dims"])}
        
        
        
        if @successful_runs.size > 0
          
          ## define default std_method_id in session                                             
          #          session[:dr_params][@project.id][:std_method_id]||=successful_runs_nber_dims.first.std_method_id if successful_runs_nber_dims.size > 0
          session[:dr_params][@project.id][:std_method_id]||=@successful_runs.first.std_method_id
          
          #          if ['tsne', 'umap'].include? @h_std_methods[session[:dr_params][@project.id][:std_method_id]].name
          #            
          #          end
          
          if !h_changed[:std_method_id]
            if @successful_runs.select{|r| session[:dr_params][@project.id][:std_method_id] == r.std_method_id}.size == 0
              @default_run_id = (@successful_runs.map{|r| r.id}.include? params[:run_id].to_i) ? params[:run_id].to_i : @successful_runs.first.id
              session[:dr_params][@project.id][:std_method_id]=@successful_runs.first.std_method_id
              #   @error_message = 'bla'
            end
          end
          
          ## filter runs by std_method_id            
          @successful_runs = @successful_runs.select{|r| session[:dr_params][@project.id][:std_method_id] == r.std_method_id}
          #          @log = @successful_runs.size
          
          if @successful_runs.size > 0 
            first_run = @successful_runs.first
            #    if !h_changed[:run_id]
            #              @log3='z'
            #          @default_run_id = @successful_runs.select{|r| session[:dr_params][@project.id][:displayed_nber_dims] == @h_attrs_by_run_id[r.id]["nber_dims"]}.first.id
            successful_runs = @successful_runs.select{|r| session[:dr_params][@project.id][:displayed_nber_dims] == @h_attrs_by_run_id[r.id]["nber_dims"]}
            if successful_runs.size == 0 and ['tsne', 'umap'].include? @h_std_methods[first_run.std_method_id].name
              session[:dr_params][@project.id][:displayed_nber_dims]= @h_attrs_by_run_id[first_run.id]["nber_dims"].to_i
              #   @default_run_id = @successful_runs.first.id
              #else
              #  @default_run_id = successful_runs.first.id
            end
            @default_run_id = (@successful_runs.map{|r| r.id}.include? params[:run_id].to_i) ? params[:run_id].to_i  : @successful_runs.first.id
            #    end
            #            elsif params[:run_id] 
            ##              run = Run.where(:id => params[:run_id]).first
            #              
            #              #       @log += run.attrs_json
            ##              if (run and m = run.attrs_json.match(/nber_dims\"\:(\d+)/))
            #              if h_attrs = @h_attrs_by_run_id[params[:run_id].to_i] #and nber_dims = h_attrs["nber_dims"]
            #                @log3 = "z"
            #                if h_attrs["nber_dims"] != params[:nber_dims] #and 
            #                  run2 = Run.where(:project_id => @project.id, :step_id => 4, :attrs_json => h_runs[params[:run_id].to_i].attrs_json.gsub(/nber_dims\"\:(\d+)/, "nber_dims\":#{session[:dr_params][@project.#id][:nber_dims]}")).first
            #                  @default_run_id = run2.id
            #                else
            #                  @default_run_id = params[:run_id].to_i
            #                end
            #              end
            #    end
          end
        end
        #end
        
        default_run = h_runs[@default_run_id]
        
        if default_run and ['tsne', 'umap'].include? @h_std_methods[default_run.std_method_id].name 
          if h_changed[:run_id] and params[:run_id] and !h_changed[:displayed_nber_dims] and !h_changed[:std_method_id]
            @default_run_id = params[:run_id].to_i
            @log3 += 'n'
          elsif h_attrs = @h_attrs_by_run_id[default_run.id] and h_attrs["nber_dims"] != session[:dr_params][@project.id][:displayed_nber_dims]
            if h_changed[:displayed_nber_dims] #@h_attrs_by_run_id[@default_run.id] and h_attrs["nber_dims"] != params[:displayed_nber_dims]
              @log3 = 'm'
              run2 = Run.where(:project_id => @project.id, :step_id => 4, :attrs_json => h_runs[params[:run_id].to_i].attrs_json.gsub(/nber_dims\"\:(\d+)/, "nber_dims\":#{session[:dr_params][@project.id][:displayed_nber_dims]}")).first
              if run2
                @default_run_id = run2.id 
              else
                @error_message = "Cannot find #{@h_std_methods[default_run.std_method_id].label} computed with #{session[:dr_params][@project.id][:displayed_nber_dims]} dimensions."
              end            
            else
              @log3 += 'o'
              # session[:dr_params][@project.id][:displayed_nber_dims] = h_attrs["nber_dims"]
              @log3+='d'
            end
          else
            if !h_attrs
              @error_message = "This run doens't exist anymore."  
            end
          end
        end 
      end
      #      end
      
      #      @log3 = @default_run_id
      ## get std_method details           
      @default_run = h_runs[@default_run_id]
      @h_std_method_attrs = get_std_method_details(@runs)
      @default_std_method_id = params[:std_method_id].to_i || @h_std_method_attrs.keys.first
    end
    ## borrow dashboard_card info
    #    @h_dashboard_card={}
    #    step_ids = @runs.map{|r| r.step_id}.uniq
    #    step_ids.map{|sid| @h_steps[sid]}.each do |step|
    #      @h_dashboard_card[step.id] = JSON.parse(step.dashboard_card_json)
    #    end
    
  end
  
  def get_step_de
    
    ## get DE filters
    @h_de_filter = Basic.safe_parse_json(@project.de_filter_json, {})
 #   begin
 #     @h_de_filter = JSON.parse(@project.de_filter_json)
 #   rescue
 #   end
    
    @h_stats = {}
    filter_stats_file = @project_dir + 'tmp' + "#{(current_user) ? current_user.id : 1}_de_filtered_stats.json" #+ 'de' + 'filtered_stats.json'
    if File.exist? filter_stats_file
     # begin
      @h_stats = Basic.safe_parse_json(File.read(filter_stats_file), {})
     # rescue
     # end
    end
    @log4 = ''
    ## check if lacking filtered DE results
    if @runs
      annots = Annot.where(:run_id => @runs.map{|r| r.id}).all
      @annots_to_filter = annots.select{|annot| !@h_stats[annot.run_id.to_s]}
      @log4 = @annots_to_filter.to_json
      @h_stats = filter_de(@annots_to_filter, "de_results") if @annots_to_filter.size > 0
    end
    #    annots_to_filter.each do |annot|
    #annot = @h_annots_by_dim[2].first
    #      loom_file = @project_dir + annot.filepath
    #     @cmd = "java -jar #{APP_CONFIG[:local_asap_run_dir]}/ASAP.jar -T ExtractMetadata -f #{loom_file} -prec 2 -light -meta #{annot.name}"
    #     @h_results[annot.run_id] = JSON.parse(`#{@cmd}`)
    
    #    end
    
    ## get dashboards
    # @h_dashboard_card = {}
    # @h_dashboard_card[@step.id] = JSON.parse(@step.dashboard_card_json)
    current_dashboard = session[:current_dashboard][@project.id][@step.id]
    @h_std_method_attrs = {}

    if current_dashboard == 'de_table'

      @h_std_method_attrs = get_std_method_details(@runs)
    end
#    @log2 = 'bla'
  end
  
  
  def get_step_ge_prelude
    ## get all gene sets                                                                                                                                                             
    @h_gene_sets = {}
    puts "DATABASE_VERSION:" + @h_env['asap_data_db_version'].to_s
    # Thread.new do
    res = Basic.sql_query2(:asap_data, @h_env['asap_data_db_version'], 'gene_sets', '', '*', "organism_id = #{@project.organism_id}")
    res.each do |gs|
      @h_gene_sets[gs.id.to_i] = gs
    end
#      ConnectionSwitch.with_db(:data_with_version, @h_env['asap_data_db_version']) do
#        GeneSet.where(:organism_id => @project.organism_id).all.each do |gs|
#          @h_gene_sets[gs.id] = gs
#        end
#      end
   # end

  end

  def get_step_ge

    ## get GE filters                                                                                                                                                                                                               
    @h_ge_filter = Basic.safe_parse_json(@project.ge_filter_json, {})

    @h_stats = {}
    filter_stats_file = @project_dir + 'tmp' + "#{(current_user) ? current_user.id : 1}_ge_filtered_stats.json" #+ 'gene_enrichment' + 'filtered_stats.json'
    if File.exist? filter_stats_file
      @h_stats = Basic.safe_parse_json(File.read(filter_stats_file), {})
    end
    @log4 = ''
    
    current_dashboard = session[:current_dashboard][@project.id][@step.id]
   
    ## check if lacking filtered DE results                                                                                                                                                                  
    @h_ge_lineage_runs={:clustering => {}, :de => {}}
    @h_ge_lineage_run_attrs={:clustering => {}, :de => {}}
    h_lineage_run_ids = {}
#    filtered_stats_file = @project_dir + 'ge' + 'filtered_stats.json'
    if @runs 
      
      if current_dashboard != 'std_runs' #and  !File.exist?(filtered_stats_file) 
        # annots = Annot.where(:run_id => @runs.map{|r| r.id}).all
        # @annots_to_filter = annots.select{|annot| !@h_stats[annot.run_id.to_s]}
        #   @log4 = @annots_to_filter.to_json
        @h_stats = filter_ge(@runs, 'ge_results', 0)
      end

      ### get lineage run_ids
      
      @runs.map{|r| h_lineage_run_ids[r.id] = r.lineage_run_ids.split(",").map{|e| e.to_i}}
      all_lineage_run_ids = h_lineage_run_ids.keys.map{|k| h_lineage_run_ids[k]}.flatten
    
      [:clustering, :de].each do |k|
        h_tmp_runs = {}
        Run.joins("join steps on (steps.id = step_id)").where(:steps => {:name => k}, :id => all_lineage_run_ids).all.each do |r|
          h_tmp_runs[r.id] = r
        end
        #  @h_clustering['bla'] = h_tmp_runs.keys
        h_lineage_run_ids.each_key do |run_id|
          tmp2 = h_lineage_run_ids[run_id].select{|rid| h_tmp_runs[rid]}        
          if tmp2.size == 1
            @h_ge_lineage_runs[k][run_id] = h_tmp_runs[tmp2.first]
            @h_ge_lineage_run_attrs[k][run_id] = Basic.safe_parse_json(h_tmp_runs[tmp2.first].attrs_json, {})
          end
        end
      end

    end

    @h_std_method_attrs = {}
    
    if current_dashboard == 'ge_table'
      @h_std_method_attrs = get_std_method_details(@runs |  @h_ge_lineage_runs[:clustering].values | @h_ge_lineage_runs[:de].values)
    end
    #    @log2 = 'bla'                                                                                                                                                                                                                  
  end

  def common_get_step
    
    [:active_step, :store_run_id].each do |k|
      session[k][@project.id] = params[k].to_i if params[k]
    end

    @project_dir = Pathname.new(APP_CONFIG[:user_data_dir]) + @project.user_id.to_s + @project.key
    
    get_dashboards()
    @h_std_methods = {}
#    StdMethod.where(:version_id => @project.version_id).all.map{|s| @h_std_methods[s.id] = s}
    StdMethod.where(:docker_image_id => @asap_docker_image.id).all.map{|s| @h_std_methods[s.id] = s} 

#    session[:active_step] = params[:active_step].to_i if params[:active_step]
    @step_id = params[:step_id].to_i || session[:active_step]
    @step = @h_steps[@step_id]
    #    @log = @step.name
    @ps = ProjectStep.where(:project_id => @project.id, :step_id => @step_id).first
    #   @h_nber_runs = {}
    #   begin
    @h_nber_runs = Basic.safe_parse_json(@ps.nber_runs_json, {}) if @ps
    @total_nber_runs = 0
    @h_nber_runs.keys.map{|k| @total_nber_runs += @h_nber_runs[k]}
    #   rescue
    #   end
    
    if @step.multiple_runs == true
      lineage_filter()
    end

    @results = {}
    @all_results = {}
    @results_parsing={}
    @h_batches={}
    #  @h_attrs = {}
    #  begin
    @h_attrs = (@step.attrs_json and !@step.attrs_json.empty?) ? Basic.safe_parse_json(@step.attrs_json, {}) : {}
    #  rescue
    #  end
    session[:current_dashboard][@project.id]||={}

    if params[:dashboard]
      session[:current_dashboard][@project.id][@step.id] = params[:dashboard]
       logger.debug("TEST_DASHBOARD: session[:current_dashboard][@project.id][@step.id]")
    elsif @h_attrs["dashboards"] and default_dashboard = @h_attrs["dashboards"].first
      session[:current_dashboard][@project.id][@step.id] ||= default_dashboard['name']
      logger.debug("TEST_DASHBOARD2: #{session[:current_dashboard][@project.id][@step.id]}")
    elsif @step.has_std_dashboard
    #  if @total_nber_runs > 1
    #    session[:current_dashboard][@project.id][@step.id] = 'std_runs'
    #  else
        session[:current_dashboard][@project.id][@step.id] ||= 'std_runs'
   #   end
    #end

    elsif @step
      session[:current_dashboard][@project.id][@step.id] ||= @step.name
      logger.debug("TEST_DASHBOARD3: session[:current_dashboard][@project.id][@step.id]")
    end
    logger.debug("TEST_DASHBOARD4: #{session[:current_dashboard][@project.id][@step.id]} #{@total_nber_runs}")
  #  if @step.has_std_dashboard
  #    if @total_nber_runs > 1
  #      session[:current_dashboard][@project.id][@step.id] = 'std_runs'
  #    else
  #      session[:current_dashboard][@project.id][@step.id] ||= 'std_runs'
  #    end
  #  end

     logger.debug("TEST_DASHBOARD5: #{session[:current_dashboard][@project.id][@step.id]} #{@total_nber_runs}")


    @last_update = get_last_update_status()
    session[:active_dr_id] ||= 1
    session[:active_viz_type] ||= 'dr'

    step_dir =  Pathname.new(APP_CONFIG[:user_data_dir]) + @project.user_id.to_s + @project.key + @step.name

    if readable? @project

      @list_cards = []
      

      if @step.multiple_runs == true or @total_nber_runs > 1
        @runs = @current_filtered_run_ids.map{|run_id| @h_all_runs[run_id]}
        @h_run_ids_by_req_id = {}
        @runs.map{|r| @h_run_ids_by_req_id[r.req_id]||=[]; @h_run_ids_by_req_id[r.req_id].push r.id}
        @h_reqs = {}
        Req.where(:id => @h_run_ids_by_req_id.keys).all.map{|r| @h_reqs[r.id] = r}
        ## compute the uniq list of methods for successful runs                                                                                                                                               
        @h_std_method_ids = {}
        @runs.select{|r| r.status_id == 3}.map{|r| @h_std_method_ids[r.std_method_id] = 1}
        current_dashboard = session[:current_dashboard][@project.id][@step.id]
        if @runs.size > 0 and (!@h_attrs["dashboards"] or current_dashboard=='std_runs')
          #       h_dashboard_card = JSON.parse(@step.dashboard_card_json)     
          #  session[:sel_req_id][@project_id][@step.id]
          
          session[:sel_req_id][@project.id][@step.id]= (params[:sel_req_id] and  params[:sel_req_id] != '') ? params[:sel_req_id].to_i : nil

          @h_cards = create_run_cards(@runs, session[:sel_req_id][@project.id][@step.id])
        elsif ['markers'].include? current_dashboard
          #  begin
         # eval("dashboard_#{current_dashboard}()")
          function = method(("dashboard_#{current_dashboard}").to_sym)
          function.call()

      #  rescue Exception => e
          #    @error = e.message
          #  end
        end
      else

      end

       logger.debug("TEST_DASHBOARD6: #{session[:current_dashboard][@project.id][@step.id]} #{@total_nber_runs}")


    end
  end

  def get_step_main

    ### update some session parameters
    logger.debug params[:step_id]
    logger.debug("TEST!")
    if params[:s]
      logger.debug("session!")
      params[:s].each_pair do |k, v|
        logger.debug("blaaaa" + k.to_json)                                                                                                                                                              
        if ["dr_params", "csp_params", "store_run_id"].include? k.to_s
          logger.debug("blaaaaa:" + k)                                                                                                                                                                
          session[k.to_sym] ||={}
          if v.is_a?(String)
            session[k.to_sym][@project.id]=v
          else
            session[k.to_sym][@project.id]||={}
            params[:s][k].each_pair do |k2, v2|
              session[k.to_sym][@project.id][k2.to_sym] = v2
              logger.debug(["SESSION: ", k, @project.id, k2, v2].join(", "))
              if [:displayed_nber_dims, :annot_id, :annot_cat_id, :dim1, :dim2].include? k2.to_sym
                session[k.to_sym][@project.id][k2.to_sym] = session[k.to_sym][@project.id][k2.to_sym].to_i
              end
              #  logger.debug("test session:" + k2 + "->" + v2)
            end
          end
        end
      end
    end
    
    if params[:sel_all_cats]
      annot = Annot.where(:id => session[:dr_params][@project.id][:cat_annot_id]).first
      h_cats = Basic.safe_parse_json(annot.categories_json, {})
      session[:dr_params][@project.id][:sel_cats] = h_cats.keys
    end
    logger.debug("test session:" + session[:csp_params].to_json)
    get_base_data()
    logger.debug params[:step_id]
    @step_id = params[:step_id].to_i || session[:active_step]
   
    @step = @h_steps[@step_id]

    if readable? @project
      @error = ''
      function = nil
      if ["ge"].include? @step.name
        function = method(("get_step_" + @step.name + "_prelude").to_sym)
        function.call()
      end
    end

     @log = "test"
    common_get_step()

    if readable? @project
      @error = ''
      function = nil
      if ["de", "ge", "metadata_expr", "summary", "dim_reduction", "cell_scatter", "import_metadata"].include? @step.name
        function = method(("get_step_" + @step.name).to_sym)
        function.call()
      end

      get_results()
      get_batch_file_groups()
    end

    ## set params[:open_controls]
    logger.debug("OPEN_CONTROL=#{params[:s]['open_controls']}")
    params[:open_controls] = '1' if params[:s]['open_controls'] == '1'
    
    respond_to do |format|
      format.html {
        render :partial => params[:partial] || "get_step"
      }
    end


  end
  
  def get_step_via_post

    if params[:landing_page_json]
      h_params = JSON.parse(params[:landing_page_json])
      h_params.each_key do |k|
        params[k.to_sym] ||= h_params[k]
      end
      
    end

    get_step_main()
    
  end

  def get_step
   
    ### update some session parameters
    
    if params[:s]
      params[:s].each_pair do |k, v|
       # logger.debug("blaaaa" + k.to_json)
        if ["dr_params", "csp_params", "store_run_id"].include? k.to_s 
          #  logger.debug("blaaaaa:" + k)
          session[k.to_sym] ||={}
          if v.is_a?(String)
            session[k.to_sym][@project.id]=v
          else
            session[k.to_sym][@project.id]||={}
            params[:s][k].each_pair do |k2, v2|
              session[k.to_sym][@project.id][k2.to_sym] = v2
              if [:displayed_nber_dims, :annot_id, :annot_cat_id, :dim1, :dim2].include? k2.to_sym
                session[k.to_sym][@project.id][k2.to_sym] = session[k.to_sym][@project.id][k2.to_sym].to_i
              end
              logger.debug("test session:" + k2 + "->" + v2)
            end
          end
        end
      end
    end
    if params[:sel_all_cats]
      annot = Annot.where(:id => session[:dr_params][@project.id][:cat_annot_id]).first
      h_cats = Basic.safe_parse_json(annot.categories_json, {})
      session[:dr_params][@project.id][:sel_cats] = h_cats.keys
    end
    logger.debug("test session:" + session[:csp_params].to_json)
    get_base_data()
    @step_id = params[:step_id].to_i || session[:active_step]
    @step = @h_steps[@step_id]
    
    if readable? @project
      @error = ''
      function = nil
      if ["ge"].include? @step.name
        function = method(("get_step_" + @step.name + "_prelude").to_sym)
        function.call()
      end
    end

    @log = "test"
    common_get_step()

    if readable? @project 
      @error = ''
      function = nil
      if ["de", "ge", "metadata_expr", "summary", "dim_reduction", "cell_scatter", "import_metadata"].include? @step.name
        function = method(("get_step_" + @step.name).to_sym)
        function.call()
      #  specific_function = "get_step_#{@step.name}()"
      #  begin
      #    eval(specific_function)
      #  #          get_step_de()
      #  rescue Exception => e
      #    ## do nothing for the moment - later we could check if this is normal regarding to the parameters - but for the moment this is not mandatory to create a specific method for a step
      #    @error = e.backtrace
      #  end
      end
      
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
#        session[:to_update] = 0
        render :partial => params[:partial] || "get_step"
#        session[:to_update] = 0
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

  def get_step_header

    get_base_data()
    @h_std_methods = {}
#    StdMethod.where(:version_id => @project.version_id).all.map{|s| @h_std_methods[s.id] = s}
    StdMethod.where(:docker_image_id => @asap_docker_image.id).all.map{|s| @h_std_methods[s.id] = s}
    @step_id = params[:step_id].to_i || session[:active_step]
    @step = @h_steps[@step_id]
    @ps = ProjectStep.where(:project_id => @project.id, :step_id => @step_id).first

    #    @h_attrs = {}
    #    @h_nber_runs = {}
    # begin
    @h_attrs = (@step.attrs_json and !@step.attrs_json.empty?) ? Basic.safe_parse_json(@step.attrs_json, {}) : {}
    @h_nber_runs = Basic.safe_parse_json(@ps.nber_runs_json, {})
   # rescue
   # end

    render :partial => "step_header_container"
    
  end

  def get_attributes_gene_enrichment
   # @filter_stats = {}
    @h_stats = {}
    @log2 = 'toto'
    if @ida['input_de']
      #     @log2+='tata'
      #     @log2+=@ida.to_json
      annots = Annot.where(:run_id => @ida['input_de'].map{|e| e[:run_id]}).all
      @h_stats = filter_de annots, "ge_form"
      #  @ida['input_de'].each do |e|
      #     @filter_stats.push({"down" => 0, "up" => 0})
      #  end
    end
  end

  def check_unavailable_inputs attrs, runs
    h_unavailable_inputs = {}
    h_available_inputs = {}
    attrs.each_key do |attr_name|
      if  c = attrs[attr_name]['constraints']
        dependent_attr_names = c['in_lineage'] || c['in_loom']
        if dependent_attr_names
          dependent_attr_names.each do |dependent_attr_name|
            vals = session[:input_data_attrs][@project.id][params[:step_id]][dependent_attr_name]
            if !vals or (vals.is_a? Array and vals.size == 0)
              h_unavailable_inputs[attr_name] = {}
            end
          end
        end
      elsif attrs[attr_name]['valid_types']
        valid_types = attrs[attr_name]['valid_types']
        source_steps = attrs[attr_name]['source_steps']
        h_constraints = attrs[attr_name]['constraints']
        
        source_step_ids = source_steps.map{|ssn| @h_steps_by_name[ssn].id}
        tmp_runs = runs.select{|run| source_step_ids.include? run.step_id}
        tmp_annots = Annot.where(:ori_run_id => runs.map{|r| r.id}, :ori_step_id => source_step_ids).all
        h_res2 = check_valid_types(@step, tmp_runs,  attrs[attr_name], tmp_annots) # valid_types, attrs[attr_name] #source_steps, h_constraints)
        if h_res2[:h_runs].keys.size == 0
          h_unavailable_inputs[attr_name] = h_res2
      #  else
      #    h_available_inputs[attr_name] = h_res2
      #  end
        end
      end
    end
    attrs.each_key do |attr_name|
      if attrs[attr_name]['valid_types']
        valid_types = attrs[attr_name]['valid_types']
        source_steps = attrs[attr_name]['source_steps']
        h_constraints = attrs[attr_name]['constraints']
        
        source_step_ids = source_steps.map{|ssn| @h_steps_by_name[ssn].id}
        tmp_runs = runs.select{|run| source_step_ids.include? run.step_id}
        tmp_annots = Annot.where(:ori_run_id => runs.map{|r| r.id}, :ori_step_id => source_step_ids).all
        h_res2 = check_valid_types(@step, tmp_runs,  attrs[attr_name], tmp_annots) # valid_types, attrs[attr_name] #source_steps, h_constraints) 
        h_available_inputs[attr_name] = h_res2
      end
    end
    
    
    attrs.each_key do |attr_name|
    if attrs[attr_name]['valid_types']
        valid_types = attrs[attr_name]['valid_types']
        source_steps = attrs[attr_name]['source_steps']
        if  c = attrs[attr_name]['constraints']
          dependent_attr_names = c['in_lineage'] || c['in_loom']
          if dependent_attr_names
            dependent_attr_names.each do |dependent_attr_name|
              vals = session[:input_data_attrs][@project.id][params[:step_id]][dependent_attr_name]              
              if !vals or (vals.is_a? Array and vals.reject{|h| h_available_inputs[dependent_attr_name][:h_runs].size == 0}.size == 0)
    #            h_available_inputs[attr_name][:h_runs] = {}
              end
            end
          end
        end
      end
    end
    
    return {:unavailable_inputs => h_unavailable_inputs, :available_inputs => h_available_inputs}
  end
  
  def get_attributes
    @log = ''
    session[:input_data_attrs][@project.id]||={}
    session[:input_data_attrs][@project.id][params[:step_id]]||={}
    @ida = session[:input_data_attrs][@project.id][params[:step_id]]
    #    h_obj = {
    #      'filter_method' => FilterMethod,
    #      'norm' => Norm,
    #      'cluster_method' => ClusterMethod,
    #      'diff_expr_method' => DiffExprMethod
    #    }
    
    #    h_step = {
    #      'filter_method' => 2,
    #      'norm' => 3,
    #      'cluster_method' => 5,
    #      'diff_expr_method' => 6
    #    }
    get_base_data()
    @project_dir = Pathname.new(APP_CONFIG[:user_data_dir]) + @project.user_id.to_s + @project.key
    @step = @h_steps[params[:step_id].to_i]
    @std_method = StdMethod.find(params[:obj_id])
#    @std_methods = StdMethod.where(:version_id => @project.version_id, :step_id => @step.id, :obsolete => false).all.sort{|a, b| a.name <=> b.name}
    @std_methods = StdMethod.where(:docker_image_id => @asap_docker_image.id, :step_id => @step.id, :obsolete => false).all.sort{|a, b| a.name <=> b.name}
    @h_std_methods = {}
    @std_methods.map{|s| @h_std_methods[s.id]=s}
    @h_data_classes={}
    DataClass.all.map{|dc| @h_data_classes[dc.id] = dc}
    
    h_res = get_attr(@step, @std_method)
    @h_attrs = h_res[:attrs]
    @attr_layout = h_res[:attr_layout]
    @h_dashboard_card={}
    @h_dashboard_card[@step.id] = Basic.safe_parse_json(@step.dashboard_card_json, {})

    ## check attributes with valid_types
    @h_runs = {}
    runs = Run.where(:project_id => @project.id, :status_id => @h_statuses_by_name['success'].id)
    runs.map{|run| @h_runs[run.id] = run}
    
    h_res3=check_unavailable_inputs(h_res[:attrs], runs)
    @h_unavailable_inputs = h_res3[:unavailable_inputs]
    @h_available_inputs = h_res3[:available_inputs]
 #   @h_runs = {}
 #   runs = Run.where(:project_id => @project.id, :status_id => @h_statuses_by_name['success'].id)
 #   runs.map{|run| @h_runs[run.id] = run}
 #   h_res[:attrs].each_key do |attr_name|
 #     if  c = h_res[:attrs][attr_name]['constraints'] 
 #       dependent_attr_names = c['in_lineage'] || c['in_loom']
 #       if dependent_attr_names
 #         dependent_attr_names.each do |dependent_attr_name|
 #           vals = session[:input_data_attrs][@project.id][params[:step_id]][dependent_attr_name] 
 #           if !vals or (vals.is_a? Array and vals.size == 0)
 #             @h_unavailable_inputs[attr_name] = {}
 #           end
 #         end
 #       end
 #     elsif  h_res[:attrs][attr_name]['valid_types']
 #       valid_types = h_res[:attrs][attr_name]['valid_types']
 #       source_steps = h_res[:attrs][attr_name]['source_steps']
 #       h_constraints =  h_res[:attrs][attr_name]['constraints']
 #       source_step_ids = source_steps.map{|ssn| @h_steps_by_name[ssn].id}
 #       tmp_runs = runs.select{|run| source_step_ids.include? run.step_id}
 #       h_res2 = check_valid_types(@step, tmp_runs, valid_types, source_steps, h_constraints)
 #       if h_res2[:h_runs].keys.size == 0
 #         @h_unavailable_inputs[attr_name] = h_res2                                                                                                                           
 #       end
 #     end
 #   end

    ### filter out datasets already selected and that are not available
    session[:input_data_attrs][@project.id][params[:step_id]].each_key do |attr_name|
      list_datasets_to_remove = []
      if session[:input_data_attrs][@project.id][params[:step_id]][attr_name].is_a? Array
        session[:input_data_attrs][@project.id][params[:step_id]][attr_name].reject!{|h| #each_index do |i|
        #  h = session[:input_data_attrs][@project.id][params[:step_id]][attr_name][i]
          if #(u = @h_unavailable_inputs[attr_name] and u[:h_runs] and u[:h_runs][h[:run_id].to_i]) or 
              (u = @h_available_inputs[attr_name] and u[:h_runs] and !u[:h_runs][h[:run_id].to_i]) or 
              !@h_runs[h[:run_id].to_i]
 #           @log += h[:run_id] + " => deleted"
         #   list_datasets_to_remove.push i
            true
          else
            false
          end
        }
        #        list_datasets_to_remove.each do |i|
#          session[:input_data_attrs][@project.id][params[:step_id]][attr_name].slice(i)
        #        end
      elsif session[:input_data_attrs][@project.id][params[:step_id]][attr_name].is_a? Hash
  #      if !@h_runs[session[:input_data_attrs][@project.id][params[:step_id]][attr_name][:run_id]] 
      end
#       @log += session[:input_data_attrs][@project.id][params[:step_id]][attr_name].to_json
    end

#    @h_attrs = {}
#    run = StdRun.where(:project_id => @project.id, :std_method_id => @obj_inst.id)

#    if params[:step_name] == 'gene_filtering'
#      @h_attrs = JSON.parse(@project.filter_method_attrs_json || "{}")
#    elsif params[:step_name] == 'normalization'
#      @h_attrs = JSON.parse(@project.norm_attrs_json || "{}")
#    elsif params[:step_name] == 'clustering'
#      @h_attrs = JSON.parse((c = Cluster.where(:project_id => @project.id, :cluster_method_id => @obj_inst.id).order("id desc").first && c && c.attrs_json) || "{}")
#    elsif params[:step_name] == 'diff_expr'
#      @h_attrs = JSON.parse((de = DiffExpr.where(:project_id => @project.id, :diff_expr_method_id => @obj_inst.id).order("id desc").first && de && de.attrs_json) || "{}")
#    end
#    begin
    if @step.name == 'gene_enrichment'
      get_attributes_gene_enrichment()
    end
#    rescue
#    end
    @warning = @std_method.warning if @std_method.respond_to?(:warning)
    
    @batch_file_exists = 1 if File.exist?(@project_dir + "parsing" + "group.tab") 
    @ercc_file_exists = 1 if File.exist?(@project_dir + "parsing" + "ercc.tab")

    render :partial => 'attributes' #, locals: {h_attrs: @h_attrs} 
    
  end

  def set_geneset

    ## get attributes                                                                                                                                           
    get_base_data()

    @step = @h_steps[params[:step_id].to_i]
    @std_method = StdMethod.find(params[:obj_id])
    h_res = get_attr(@step, @std_method)
    @h_attrs = h_res[:attrs]
    @attr_layout = h_res[:attr_layout]
    @log3 = ""
  
    if params[:step_id] and params[:attr_name]
      ## define input data  
     # @log3+='bla'
      session[:input_data_attrs][@project.id]||={}
      session[:input_data_attrs][@project.id][params[:step_id]] ||= {}
      session[:input_data_attrs][@project.id][params[:step_id]][params[:attr_name] + "_type"] = params[:geneset_type]
      session[:input_data_attrs][@project.id][params[:step_id]][params[:attr_name]] = params[:geneset]
      
    end

    ## find the layout context              
    horiz_element = false
    
    @attr_layout.each do |tmp_vertical_el|
      tmp_vertical_el["horiz_elements"].each do |tmp_horiz_element|
        if tmp_horiz_element['attr_list']
          tmp_horiz_element['attr_list'].select{|k| attr = @h_attrs[k]; attr and attr['widget'] and !attr['obsolete']}.each do |attr_name|
            if attr_name == params[:attr_name]
              horiz_element = tmp_horiz_element
              break
            end
          end
        end
      end
    end
    
    render :partial => 'attribute', :locals => {:attr_name => params[:attr_name], :horiz_element => horiz_element}

  end

  def set_input_data

    @log = ''

    ## get attributes                                                                                                                                                                                           
    get_base_data()
    @project_dir = Pathname.new(APP_CONFIG[:user_data_dir]) + @project.user_id.to_s + @project.key
    @step = @h_steps[params[:step_id].to_i]
    @std_method = StdMethod.find(params[:obj_id])
    h_res = get_attr(@step, @std_method)
    @h_attrs = h_res[:attrs]
    @attr_layout = h_res[:attr_layout]

    @h_dashboard_card = {}
    @h_dashboard_card[@step.id] = Basic.safe_parse_json(@step.dashboard_card_json, {})
    
    @h_data_classes={}
    DataClass.all.map{|dc| @h_data_classes[dc.id] = dc}
        
    ## define input data
    session[:input_data_attrs][@project.id]||={}
    session[:input_data_attrs][@project.id][params[:step_id]] ||= {}
    @ida = session[:input_data_attrs][@project.id][params[:step_id]]
    
    if @ida[params[:attr_name]] != params[:list_attrs]      
      @ida[params[:attr_name]] = []
      @h_attrs.keys.select{|attr_name| c = @h_attrs[attr_name]['constraints'] and ((c['in_lineage'] and c['in_lineage'].include?(params[:attr_name])) or (c['in_loom'] and c['in_loom'].include?(params[:attr_name])))}.each do |attr_name|
        @ida[attr_name]=[]
      end
      #get annots
      #      @h_annots = {}
      #      annot_ids = params[:list_attrs].split(",").map{|e| e2 = e.split(":"); (e2[0] == 'annot') ? e2[1].to_i : nil}.compact
      #      Annot.where(:id => annot_ids).all.map{|a| @h_annots[a.id] = a}
      
      params[:list_attrs].split(",").each do |e|
        e2 = e.split(":")
        puts "E2: #{e2.to_json}"
        if e2[0] == 'annot'
          @ida[params[:attr_name]].push({#:run_id => @h_annot[e2[1].to_i].run_id, :annot_id => e2[1].to_i
                                          :annot_id => e2[1].to_i, :run_id => e2[2].to_i
                                        })
        else
          @ida[params[:attr_name]].push({:run_id => e2[0].to_i, :output_attr_name => e2[1], :output_filename => e2[2], :output_dataset => (e2.size > 3) ? e2[3] : nil })
        end
      end
    end
    
    ## find annots
    annots = Annot.where(:run_id => @ida[params[:attr_name]].map{|e| e[:run_id]}).all
    h_annots = {}
    annots.each do |annot|
      h_annots[annot.run_id]||={}
      h_annots[annot.run_id][annot.name]=annot
    end
    
    ## add annot_id in ida
    @ida[params[:attr_name]].each_index do |i|
      e = @ida[params[:attr_name]][i]
      if h_annots[e[:run_id].to_i]
        @ida[params[:attr_name]][i][:annot_id] ||= (annot = h_annots[e[:run_id].to_i][e[:output_dataset]]) ? annot.id : nil      
      end
    end

    @h_runs = {}
    runs = Run.where(:id => @ida[params[:attr_name]].map{|e| e[:run_id]}).all
    runs.map{|r| @h_runs[r.id] = r}

    @warning = @obj_inst.warning if @obj_inst.respond_to?(:warning)
    
    @batch_file_exists = 1 if File.exist?(@project_dir + "parsing" + "group.tab")
    @ercc_file_exists = 1 if File.exist?(@project_dir + "parsing" + "ercc.tab")
    
    ## find the layout context
    horiz_element = false
    
    @attr_layout.each do |tmp_vertical_el|
      tmp_vertical_el["horiz_elements"].each do |tmp_horiz_element|
        if  tmp_horiz_element['attr_list']
          tmp_horiz_element['attr_list'].select{|k| attr = @h_attrs[k]; attr and attr['widget'] and !attr['obsolete']}.each do |attr_name| 
            if attr_name == params[:attr_name]
              horiz_element = tmp_horiz_element
              break 
            end
          end
        end
      end
    end

    ## set dependent attributes
    @dependent_attributes=[]    
     @h_attrs.each_key do |attr_name|
      if  c = @h_attrs[attr_name]['constraints'] and ((c['in_lineage'] and c['in_lineage'].include?(params[:attr_name])) or (c['in_loom'] and c['in_loom'].include?(params[:attr_name])))
        @dependent_attributes.push(attr_name)
      end
    end

#    h_res3=check_unavailable_inputs(@h_attrs, runs)
#    @h_unavailable_inputs = h_res3[:unavailable_inputs]
#    @h_available_inputs = h_res3[:available_inputs]
    
    if @step.name == 'gene_enrichment' and params[:attr_name] == 'input_de'
      get_attributes_gene_enrichment()
    end
    
    ## render the attribute
    params[:validate_form] = 1
    render :partial => 'attribute', :locals => {:attr_name => params[:attr_name], :horiz_element => horiz_element}
    ## render the form

    ## check attributes with valid_types                                                                                                                                                                        
    # @h_unavailable_inputs={}
    # runs = Run.where(:project_id => @project.id, :status_id => @h_statuses_by_name['success'].id)
    # h_res[:attrs].each_key do |attr_name|
    #   if  h_res[:attrs][attr_name]['valid_types']
    #     valid_types = h_res[:attrs][attr_name]['valid_types']
    #     source_steps = h_res[:attrs][attr_name]['source_steps']
    #     h_constraints =  h_res[:attrs][attr_name]['constraints']
    #     source_step_ids = source_steps.map{|ssn| @h_steps_by_name[ssn].id}
    #     tmp_runs = runs.select{|run| source_step_ids.include? run.step_id}
    #     h_res2 = check_valid_types(@step, tmp_runs, valid_types, source_steps, h_constraints)
    #     if h_res2[:h_runs].keys.size == 0
    #       @h_unavailable_inputs[attr_name] = h_res2
    #     end
    #   end
    # end

    #    render :partial => "attributes"

  end

  def get_file_old
 
    tmp_dir = Pathname.new(APP_CONFIG[:user_data_dir]) + @project.user.id.to_s + params[:key]
    
    ### get gene_file
    if File.exists?(tmp_dir + "parsing" + 'gene_names.json')
      list_gene_names = Basic.safe_parse_json(File.read(tmp_dir + "parsing" + 'gene_names.json'), [])
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
  
  def tsv_from_json
     project_dir = Pathname.new(APP_CONFIG[:user_data_dir]) + @project.user.id.to_s + @project.key
    run_id = (params[:run_id]) ? params[:run_id] : nil #((params[:filename] and m = params[:filename].match(/^(\d+)\.\w{1,3}/)) ? m[1].to_i : nil)         

    step_name = params[:step]
    if run_id
      run =  Run.where(:id => run_id).first
      h_outputs = Basic.safe_parse_json(run.output_json, {})
      h_file_by_id = {}
      h_outputs.each_key do |k|
        h_outputs[k].each_key do |k2|
          t = k2.split(":")
          relative_path = t[0]
          full_path = project_dir + relative_path
          h_file_by_id[h_outputs[k][k2]['onum']]={:filename => h_outputs[k][k2]['filename'], :filepath => full_path}
        end
      end
      step_name = (step = run.step) ? step.name : nil
    end

    filepath = nil
    filename = nil
    if params[:onum]
      filename = h_file_by_id[params[:onum].to_i][:filename]
      filepath = h_file_by_id[params[:onum].to_i][:filepath]
    end
    filename_base = filename.gsub(/\..+?$/, "")
    
    if readable?(@project) and exportable? @project
      if File.exist? filepath
        h_data = Basic.safe_parse_json(File.read(filepath), {})
        #          {"time_idle":0.0,"headers":["name","description","p-value","fdr","effect size","size geneset","overlap w/ genes"],"up":[["GO:0055114","oxidation-reduction process",0.0002792580318720095,0.11896392157747604,3.2605128205128207,95,17],["GO:0010033","response to organic substance",0.0051974186386104515,0.7346068434187418,4.680810028929605,23,6],["GO:0009636","response to toxic substance",0.006243466420143062,0.7346068434187418,5.470430107526882,17,5],["G
        data = []
        headers = h_data['headers'] + ['up|down']
        h_headers = {}
        headers.each_index do |i|
          h_headers[headers[i]] = i
        end
        data.push(headers)
        ["up", "down"].each do |type|
          h_data[type].sort{|a, b| b[h_headers['effect size']].to_f <=> a[h_headers['effect size']].to_f}.each do |e|
#           h_data[type].each do |e|
            data.push(e + [type])
          end
        end
        send_data data.map{|e| e.join("\t")}.join("\n"), type: params[:content_type] || 'text',
        x_sendfile: true, buffer_size: 512, disposition: (!params[:display]) ? ("attachment; filename=" + [@project.key, step_name,  run_id, (filename_base + ".tsv")].compact.join("_")) : ''
        
      end
    else
      render :plain => 'Not authorized to download this file.'
    end
  end
  
  def get_file

    project_dir = Pathname.new(APP_CONFIG[:user_data_dir]) + @project.user.id.to_s + @project.key
    run_id = (params[:run_id]) ? params[:run_id] : nil #((params[:filename] and m = params[:filename].match(/^(\d+)\.\w{1,3}/)) ? m[1].to_i : nil)                                                                       
    step_name = params[:step]
    if run_id
      run =  Run.where(:id => run_id).first
      h_outputs = Basic.safe_parse_json(run.output_json, {})
      h_file_by_id = {}
      h_outputs.each_key do |k|
        h_outputs[k].each_key do |k2|
          t = k2.split(":")
          relative_path = t[0]
          full_path = project_dir + relative_path 
          h_file_by_id[h_outputs[k][k2]['onum']]={:filename => h_outputs[k][k2]['filename'], :filepath => full_path}
        end
      end
      step_name = (step = run.step) ? step.name : nil
    end
    
    filepath = nil
    filename = nil
    if params[:onum]
      filename = h_file_by_id[params[:onum].to_i][:filename]
      filepath = h_file_by_id[params[:onum].to_i][:filepath]
    elsif params[:filename]
      filename = params[:filename]
      tmp_dir = Pathname.new(APP_CONFIG[:user_data_dir]) + @project.user.id.to_s + params[:key] 
      tmp_dir += step_name if step_name
      tmp_dir += params[:run_id].to_s if params[:run_id]
      filepath = tmp_dir + filename
    end
    
    ext =  filename.split(".").last
    #    obj = c.constantize if params[:step] and c= params[:step].classify and ['GeneSet'].include?(c)
    #    obj = Run
    
    if readable?(@project) and (exportable? @project or ['png', 'pdf', 'jpeg', 'jpg'].include?(ext)) or (step_name == 'visualization' and filename.match(/trajectory/) and ext == 'json') or (step_name and run and exportable_item?(@project, run))

      ## export to h5ad
      if filepath.to_s.match(/output\.h5ad$/) 
        loom_filepath = filepath.dup.to_s
        loom_filepath.gsub!(/\.h5ad$/, '.loom')
        if !File.exist? filepath or (File.exist? filepath and File.ctime(filepath) < File.mtime(loom_filepath))  ## convert everytime                                                                                                                                                                      
          h_env = Basic.safe_parse_json(@project.version.env_json, {})
          docker_name = "#{h_env['docker_images']['asap_run']['name']}:#{h_env['docker_images']['asap_run']['tag']}"
          loom_filepath = filepath.dup.to_s
          loom_filepath.gsub!(/\.h5ad$/, '.loom')
          # if !File.exist? project_dir + h5ad_file                                                                                                                                                                                       
          rscript_cmd = "Rscript -e 'library(\\\"sceasy\\\"); loom_file <- \\\"#{loom_filepath}\\\"; sceasy::convertFormat(loom_file, from=\\\"loom\\\", to=\\\"anndata\\\", outFile=\\\"#{filepath.to_s}\\\")'"
          cmd = "docker run --entrypoint '/bin/sh' --rm -v #{APP_CONFIG[:data_dir]}:#{APP_CONFIG[:data_dir]} #{docker_name} -c \"#{rscript_cmd}\""
          logger.debug("CREATE H5AD file: " + cmd)
          `#{cmd}`
        end
      end
      
      if File.exist? filepath
        if ['exec.err', 'exec.out'].include? filename
          content = File.read(filepath) 
          content.gsub!(project_dir.to_s, "$PROJECT_DIR")
          send_data content, type: params[:content_type] || 'text', # type: 'application/octet-stream'                                                                   
          x_sendfile: true, buffer_size: 512, disposition: (!params[:display]) ? ("attachment; filename=" + [@project.key, step_name,  run_id, filename].compact.join("_")) : ''        
        else
          logger.debug "FILEPATH:" + filepath.to_s
          new_filepath = filepath.to_s.gsub(/^\/data\/asap2/, '/rails_send_file')
      #      response.headers["X-Accel-Redirect"]=  new_filepath
      #     response.headers['Content-Length'] = File.size filepath

#           headers['Content-Disposition'] = (!params[:display]) ? ("attachment; filename=" + [@project.key, step_name,  run_id, filename].compact.join("_")) : ''
#           headers['Content-Type'] = "application/octet-stream"
#           headers['Content-Length'] = File.size filepath
           
 #         send_file filepath.to_s, #type: params[:content_type] || 'text',
 #                   type: 'application/octet-stream', x_sendfile: true, #stream: true, 
 #                    buffer_size: 512, disposition: (!params[:display]) ? ("attachment; filename=" + [@project.key, step_name,  run_id, filename].compact.join("_")) : ''
           #   #redirect_to "/data/" + filepath.to_s.gsub(/\/data\/asap2\//, "")         
           #          render :partial => 'get_file', :locals => {:filepath => filepath, :filename => [@project.key, step_name,  run_id, filename].compact.join("_")}
           
                     path = filepath.to_s.gsub(/\/data\/asap2/, "/rails_send_file") #"/rails_send_file/FB2020_05.sql.gz.05"
           headers['Content-Disposition'] = (!params[:display]) ? ("attachment; filename=" + [@project.key, step_name,  run_id, filename].compact.join("_")) : ''
            headers['X-Accel-Redirect'] = path #'/download_public/uploads/stories/' + params[:story_id] +'/' + params[:story_id] + '.zip'                                    
           # headers["X-Accel-Mapping"]=  "/data/asap2/=/rails_send_file/" 
           headers['Content-Type'] = "application/octet-stream"
           headers['Content-Length'] = File.size filepath
          render :nothing => true
           
        end
      else
        render :plain => "This file doesn't exist."
      end
    else
      render :plain => 'Not authorized to download this file.'
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
    public_limit = (params[:format] == 'json') ? 10000 : settings[:public_limit] 
    @h_counts={:public => 0, :private => 0}
    @h_counts[:public] =  public_base_search.where(h).count
    @public_projects = public_base_search.where(h).order("updated_at desc").limit(public_limit).all.to_a
    
    free_txt = settings[:free_text].downcase.gsub("*", "").gsub(/([\[\]()])/, '\\' + "\1")
    
    base_search = (settings[:free_text] and !settings[:free_text].empty?) ? Project.joins("join users on (users.id = user_id)").where("lower(name) ~ ? or key ~ ? or users.email ~ ?", free_txt, free_txt, free_txt) : Project

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

  def format_gene g

    return {
      :name => g['name'],
      :ensembl_id => g['ensembl_id'],
      :biotype => g['biotype'],
      :chr => g['chr'],
      :ncbi_gene_id => g['ncbi_gene_id'],
      :latest_ensembl_release => g['latest_ensembl_release'],
      :description => g['description'],
      :function_description => g['function_description'],
      :alt_names => g['alt_names']
    }
    
  end

  # GET /projects
  # GET /projects.json
  def index
    get_projects()
    @h_statuses = {}
    Status.all.map{|s| @h_statuses[s.id] = s}
    @h_archive_statuses = {}
    ArchiveStatus.all.map{|s| @h_archive_statuses[s.id] = s}
    @h_organisms = {}
    Organism.all.map{|o| @h_organisms[o.id]=o}

    @sel_projects = Project.where(:key => session[:project_cart].keys).all
    
     respond_to do |format|
      format.html { 
        if params[:nolayout]
          render :partial => 'index'
        else
          if current_user
            render :layout => 'welcome'
          else
            @sandbox_project = Project.where(:key => session[:sandbox]).first
            render "welcome", :layout => 'welcome'
          end
        end
      }
      format.json { 
         
#        render :plain => File.read(Pathname.new(APP_CONFIG[:data_dir]) + 'projects.json')
        file_path = Pathname.new(APP_CONFIG[:data_dir]) + 'projects.json'
     #   path = filepath.to_s.gsub(/\/data\/asap2/, "/rails_send_file") #"/rails_send_file/FB2020_05.sql.gz.05"                                                                   
     #   headers['Content-Disposition'] = "attachment; filename=projects.json"
     #   headers['X-Accel-Redirect'] = path #'/download_public/uploads/stories/' + params[:story_id] +'/' + params[:story_id] + '.zip'                                            
     #   headers['Content-Type'] = "application/octet-stream"
     #   headers['Content-Length'] = File.size filepath
     #   render :nothing => true
      
        headers['Content-Type'] = 'application/json'
        headers['Cache-Control'] = 'no-cache'
        headers['Content-Disposition'] = "inline; filename=#{File.basename(file_path)}"
        
        # Use send_file to stream the content directly to the client
        send_file(file_path, type: 'application/json', disposition: 'inline', stream: true)
        
      }
    end
    
  end

  # GET /projects/1
  # GET /projects/1.json
  def show

    if params[:direct_link_key]
      @direct_link = DirectLink.where(:view_key => params[:direct_link_key]).first
      if @direct_link
        @direct_link.update_attribute(:nber_views, (@direct_link.nber_views || 0) + 1)
      end
    end
    
     respond_to do |format|
      format.html{

    @error = ''
    if @project
      public_txt = (@project.public) ? "[#{@project.public_key}] " : ''
      @title = "Project #{@project.key} #{public_txt}- ASAP Automated Single-cell Analysis Portal"
    #  @version =@project.version
    #  @h_env = {}
    #  begin
    #    @h_env = Basic.safe_parse_json(@version.env_json, {})
    #  rescue
    #  end
      
      ### define the current project
      #if session[:current_project] != @project.key

      [:input_data_attrs, :filter_lineage_run_ids, :activated_filter, :current_dashboard, :dr_params, :csp_params, :clust_comparison, :de_markers, :metadata_type, :store_run_id, :tmp_de_filter, :sel_req_id, :marker_genes].each do |k|
        session[k]||={}
      end
      
      session[:store_run_id][@project.id]=0
      session[:metadata_type][@project.id]=1
      session[:input_data_attrs][@project.id]||={}
      session[:filter_lineage_run_ids][@project.id]||=[]
      session[:activated_filter][@project.id]=false
      session[:current_dashboard][@project.id]||={}
      session[:sel_req_id][@project.id]||={} 
      session[:tmp_de_filter][@project.id]={"fc_cutoff" => 2, "fdr_cutoff" => 0.05}
#      session[:global_dr_params][@project.id]||={:dot_opacity => 0.5, :dot_size => 3, :coloring_type => "1", :std_method_id => nil, :nber_dims => 2}
      session[:csp_params][@project.id]||={
        :mode => '1', :dot_opacity => 0.5, :dot_size => 3, :coloring_type => "1", :std_method_id => nil, :nber_dims => 2, :displayed_nber_dims => 2, :cat_annot_id => nil, :cat_annot_id2 => nil, :main_menu => "coloring", :info_cat => "gene_exp", :sel_cats => [], :sel_cats2 => [], :sel_cat2 => nil, :dim1 => 1, :dim2 => 2, :dim3 => 3,
          :occ_1 => {:data_type => "1", :geneset_annot_id => nil, :geneset_annot_cat => nil,  :geneset_id => nil, :geneset_item_id => nil, :autocomplete_geneset_item => nil},
        :occ_2 => {:data_type => "1"},
        :occ_3 => {:data_type => "1"},
        :occ_4 => {:data_type => "1"}
      }
      session[:dr_params][@project.id]||={
        :dot_opacity => 0.9, :dot_size => 3, :cell_names_on_hover => '0', :coloring_type => "1", :std_method_id => nil, :nber_dims => 2, :displayed_nber_dims => 2, :cat_annot_id => nil, :cat_annot_id2 => nil, :main_menu => "coloring", :info_cat => "gene_exp", :sel_cats => [], :sel_cat2 => nil, :sel_cats2 => [], 
        #   :row_i_1 => nil,
        #   :dataset_annot_id_1 => nil,
        #   :gene_selected_1 => '',
        #   :annot_id_1 => nil,
        #   :header_i_annot_id_1 => nil,
        #      :coloring_type => "1",
        # :data_type => "1",
        :occ_1 => {:data_type => "1"},
        :occ_2 => {:data_type => "1"},
        :occ_3 => {:data_type => "1"},
        :occ_4 => {:data_type => "1"}
        #        :gradients => [],
        #        :channels => [],
        #        :gene_pos => nil,
        #        :annot_id => nil
      }

      session[:dr_params][@project.id][:dot_opacity] ||= 0.5
      session[:dr_params][@project.id][:dot_size] ||= 3
      session[:dr_params][@project.id][:coloring_type]||= "1" if !["1", "2"].include?(session[:dr_params][@project.id][:coloring_type])
      session[:dr_params][@project.id][:displayed_nber_dims]||=2
      session[:dr_params][@project.id][:main_menu]||='coloring'
      session[:dr_params][@project.id][:info_cat]||= 'gene_expr'
      session[:dr_params][@project.id][:sel_cats]||=[]
      session[:clust_comparison][@project.id]||={}
      session[:clust_comparison][@project.id][:op] ||= "1"
      session[:marker_genes][@project.id] = {:up => {}, :down => {}}
#      session[:sel_marker_genes][@project.id] = {:up => {}, :down => {}}
      session[:current_project]=@project.key
      #    session[:reload_step]=0
      
      if readable? @project

        ### check if all project_steps exist
        init_project_steps()
        
        if ! File.exist? @project_dir
          job_handler = Project::Unarchive.new(@project).to_yaml
          if Delayed::Job.where(
               queue: 'fast',
               locked_at: nil, # Not in progress
               failed_at: nil  # Not failed
             ).where("handler LIKE ?", "%#{job_handler}%").exists?
            # Job already exists, skip enqueuing
            Rails.logger.info("A similar job is already enqueued for project #{@project.id}")
          else
            # No duplicate found, enqueue the job
            Delayed::Job.enqueue(Project::Unarchive.new(@project), queue: 'fast')
          end
        end

        ### have to ensure the project is in status unarchived
#        if @project.archive_status_id != 1
#          delayed_job = Delayed::Job.enqueue(Project::Unarchive.new(@project), :queue => 'fast')
          #      while [2, 4].include? @project.archive_status_id
          #        sleep 0.2
          #      end
          #      if @project.archive_status_id == 3
    #        @unarchive_cmd = "rails unarchive[#{@project.key}]"
          #        `#{@unarchive_cmd}`
          #        logger.debug(@unarchive_cmd)
          #      end
#        end
        
        #      session[:viz_params]={
        #        'dim1' => 1,
        #        'dim2' => 2,
        #        'dim3' => 3,
        #        'color_by' => 'gene_text',
        #        'gene_text' => '',
        #        'dataset' => 'normalization',
        #        'cluster_id' => nil,
        #        'selection_id' => nil,
        #        'geneset_type' => 'all',
        #        'global_geneset' => (global_geneset = GeneSet.where(:user_id => 1, :project_id => nil, :organism_id => @project.organism_id).order("label").first && global_geneset && global_geneset.id) || nil,
        #        'custom_geneset' => (custom_geneset = GeneSet.where(:project_id => @project.id).order("label").first && custom_geneset && custom_geneset.id) || nil,
        #        'geneset_name' => ''
        #        #        'heatmap_input_type' => 'normalization'
        #      }
        session[:cart_display]=nil
        
        last_ps =  ProjectStep.where(:project_id => @project.id, :status_id => [1, 2, 3, 4]).order("updated_at desc").first
        last_step_id = (last_ps) ? last_ps.step_id : 1
        @last_update = get_last_update_status()
        session[:active_step]=last_step_id
        ### override active step if coming from update project form                                                                                                                     
        session[:active_step] = session[:override_active_step] if session[:override_active_step]
        @step_id = params[:step_id].to_i || session[:active_step]
        session.delete(:override_active_step)
        
        params[:active_step]=last_step_id
        session[:last_step_status_id]=@project.status_id
        params[:last_step_status_id]=@project.status_id
        session[:last_step_id]=last_step_id

        ### init subdir
        if @project.archive_status_id == 1  
          project_dir =  Pathname.new(APP_CONFIG[:user_data_dir]) + @project.user_id.to_s + @project.key
          if File.exist? project_dir
            ["tmp"].each do |d|
              Dir.mkdir project_dir + d if !File.exist?(project_dir + d)
            end
          end
          
          ### setup selections
          session[:selections]={}
          if readable?(@project)
            selection_dir = project_dir + 'selections'
            Dir.mkdir selection_dir if File.exist?(project_dir) and !File.exist?(selection_dir)
            @project.selections.each do |selection|
              file = selection.id.to_s + ".txt"
              File.open(selection_dir + file, 'r') do |f|
                session[:selections][selection.id]={:item_list => f.readlines.map{|e| e.chomp}.sort, :edited => selection.edited}
              end
            end
          end
        end

        @h_statuses={}
        Status.all.map{|s| @h_statuses[s.id]=s}
        @h_steps={}
        @h_attrs_by_step={}
#        all_steps = Step.where(:version_id => @project.version_id).all
        all_steps = []
        if @asap_docker_image
          all_steps = Step.where(:docker_image_id => @asap_docker_image.id).all
          all_steps.map{|s| @h_steps[s.id]=s; @h_attrs_by_step[s.id]= Basic.safe_parse_json(s.attrs_json, {})}
          @h_steps_by_name = {}
          all_steps.map{|s| @h_steps_by_name[s.name] = s}
        end
        
        ## update views
        if !admin?
          last_day_session_ids = @project.last_day_session_ids.split(",")
          last_day_session_ids.push(session.id) if !last_day_session_ids.include? session.id
          h_upd = {
            :viewed_at => Time.now,
            :last_day_session_ids => last_day_session_ids.join(",")
          }
          @project.update_attributes(h_upd)
        end
        
        # elsif @project.archive_status_id == 2 ## project is not unarchived
        #  @error = "The project is being unarchived..."
      end
    else
      @error = "The project doesn't exist or the session has expired. Please create a new project."
    end

    if @project.version_id > 3
      render :layout => 'project'
    else
      redirect_to "https://asap-old.epfl.ch/projects/#{@project.key}"
    end
      } 
      format.json {render :json => Basic.generate_project_json(@project)}
    end
  end
    
  def get_hca_data #h_p

    @nber_hits_displayed = 200
    @h_hca= {} #JSON.parse(h_p[:q])

    #    @h_filters = {
    #     'file' => {'fileFormat' => {"is" => ["matrix"]}}
    #    }
    
    #    if h_p[:filters]
    #      @h_filters.merge(h_p[:filters])
    #    end
    
    #    @h_urls = {
    #      :summary => "https://service.dev.explore.data.humancellatlas.org/repository/summary?filters=#{@h_filters.to_json}",
    #      :projects => "https://service.dev.explore.data.humancellatlas.org/repository/projects?filters=#{@h_filters.to_json}&size=15"
    #    }


    @h_filters = JSON.parse(params[:q]) if params[:q]

    q_txt = URI::encode(@h_filters.to_json)
#    q_txt = @h_filters.to_json
#    q_txt.gsub!(/\:/, "%3A")
#    q_txt.gsub!(/\[/, "%5B")
#    q_txt.gsub!(/\]/, "%5D")

    @h_urls = {
#      :summary => "https://service.explore.data.humancellatlas.org/repository/summary?filters=#{q_txt}",
      :projects => #"https://service.explore.data.humancellatlas.org/repository/projects?filters=#{q_txt}&size=#{@nber_hits_displayed}"
    #  "https://service.explore.data.humancellatlas.org/repository/projects?filters=#{q_txt}&size=#{@nber_hits_displayed}&sort=projectTitle&order=asc"
      "https://service.azul.data.humancellatlas.org/index/projects?filters=#{q_txt}&size=#{@nber_hits_displayed}&sort=projectTitle&order=asc&catalog=dcp14"
    }

    @errors = []
    @log = ""
    hca_data = {}
    hca_dir = Pathname.new(APP_CONFIG[:data_dir]) + 'hca'

    @h_urls.each_key do |k|

      hca_data_file = hca_dir + (k.to_s + ".json")
      hca_upd_time = File.ctime(hca_data_file) if File.exist? hca_data_file
      hca_json_data = ''
      if !hca_upd_time or Time.now - hca_upd_time > 1.day
        cmd = "wget -O #{hca_data_file} '#{@h_urls[k]}'"
        @log +="=>" + cmd + "<= " 
        hca_json_data = `#{cmd}`
      elsif File.exist? hca_data_file
        hca_json_data = File.read(hca_data_file)
      end
      
      @h_hca[k]= {}
#      @log += JSON.parse(hca_json_data).to_json
      if !hca_json_data.empty?
        begin
          @h_hca[k] = Basic.safe_parse_json(hca_json_data, {})
        rescue Exception => e
          @errors.push("Data from HCA is not accessible at this time.")
        end
      end
    end
  end

  def provider_projects
    #    https://service.explore.data.humancellatlas.org/repository/projects?filters=%7B%22fileFormat%22%3A%7B%22is%22%3A%5B%22matrix%22%5D%7D%7D&size=15&sort=projectTitle&order=asc
    #   params[:q] = '%7B%22fileFormat%22%3A%7B%22is%22%3A%5B%22matrix%22%5D%7D%7D' #'{"fileFormat":{"is":["matrix"]}}'
  #  params[:q] = '{"fileFormat":{"is":["matrix"]}}'
    params[:q] = '{"fileFormat":{"is":["loom"]}}'
    get_hca_data()
    
    respond_to do |format|
      format.json {
        render :plain => @h_hca[:projects]['hits'].map{|e| 
          total_cells = 0;
          e['cellSuspensions'].map{|e2| total_cells += e2['totalCells']};
          {'entryId' => e['entryId'], 'projectTitle' => e['projects'].map{|e2| e2['projectTitle']}.join(", "), 'totalCells' => total_cells}}.to_json
      }
      
    end
  end

  def get_sel_projects
    @sel_projects = Project.where(:key => session[:project_cart].keys).all
    @h_annots = {}
    @sel_projects.each do |p|
      version =p.version
      h_env = Basic.safe_parse_json(version.env_json, {})
      if h_env['docker_images']
        list_docker_image_names = h_env['docker_images'].keys.map{|k| h_env['docker_images'][k]["name"] + ":" + h_env['docker_images'][k]["tag"]}
        docker_images = DockerImage.where("full_name in (" + list_docker_image_names.map{|e| "'#{e}'"}.join(",") + ")").all
        asap_docker_image = docker_images.select{|e| e.name == APP_CONFIG[:asap_docker_name]}.first
      end
      parsing_step = Step.where(:docker_image_id => asap_docker_image.id, :name => 'parsing').first
      parsing_run = Run.where(:project_id => p.id, :step => parsing_step.id).first
      @h_annots[p.id] = Annot.where(:project_id => p.id, :store_run_id => parsing_run.id, :data_type_id => 3, :dim => 1).all
    end
  end
    
  
  def integrate_form
    get_sel_projects()
    render :partial => 'integrate_form'
  end

  def hca_preview

    h_p = {}
    begin
      h_p = JSON.params[:q] if params[:q]
    rescue Exception => e
    end
    
    get_hca_data()

    @sum_matrices = []
    list_fields = ['genusSpecies', 'organ', 'libraryConstructionApproach', 'developmentStage']
    if @h_hca[:projects] and @h_hca[:projects]['hits']
      @h_hca[:projects]['hits'].each_index do |i| 
        e = @h_hca[:projects]['hits'][i] 
        #h_sum_matrices = {} 
        h_matrices = e['projects'][0]['matrices'] 
        h_project_sum_matrices = {} 
        #      k = h_matrices.keys.first 
        h_cur = {} 
        #      h_tmp = h_matrices[k] 
        #      while (list_fields.include? k) do 
        
        h_res = Basic.recursive_parse_hca list_fields, h_matrices, h_cur, h_project_sum_matrices
        @sum_matrices.push h_res[:h_project_sum_matrices]  
      end
    end
    render :partial => 'hca_preview'
  end

  def hca_download
  end

  # GET /projects/new
  def new
    version = nil
    if params[:version_id] 
      version = Version.where(:id => params[:version_id]).first
    end
    @notice = nil
    if (params[:version_id] and !version) or (version and version.id < 4)
      @notice = "Invalid version ID (#{params[:version_id]})!"
      version = nil
    end
    
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
    @project = Project.where(:key => project_key).first
    if !@project
      @project = Project.new
      @project.key = project_key
      @project.version_id = (version && version.id) || Version.where(:activated => true).last.id #APP_CONFIG[:version_id]
      @shares = @project.shares.to_a
      @h_env = Basic.safe_parse_json(Version.where(:id => @project.version_id).first.env_json, {})
    end    
    #    @h_list_organisms = {'Most popular species' => Organism.where(:id => [1, 2, 35]).map{|o|  [o.short_name.capitalize + " - #{o.name} [TaxID:#{o.tax_id}]", o.id]}}
      #    EnsemblSubdomains.all.each do |e| 
    #      @h_list_organisms.merge({e.name => e.organisms.map{|o| [o.short_name.capitalize + " - #{o.name} [TaxID:#{o.tax_id}]", o.id]}})
    #    end
    #    'All species' => Organism.all.select{|o| o.short_name}.map{|o|  [o.short_name.capitalize + " - #{o.name} [TaxID:#{o.tax_id}]", o.id]}.sort}
    
    
    ### get initial HCA data
    #get_hca_data()
 # else
  
 #   end
    if params[:project_name] 
      @project.name ||= params[:project_name]
    end

    get_sel_projects()
    
    render :layout => 'welcome'

  end

  # GET /projects/1/edit
  def edit
    tmp_dir = Pathname.new(APP_CONFIG[:user_data_dir]) + @project.user.id.to_s + params[:key]
    @existing_group_file = 1 if File.exist?(tmp_dir + "parsing" + "group.tab")
    @h_steps={}
    @results = {}
    @all_results = {}
    @shares = @project.shares.to_a
#    Step.where(:version_id => @project.version_id).all.map{|s| @h_steps[s.id]=s}
    @annots = []
    if @asap_docker_image
      Step.where(:docker_image_id => @asap_docker_image.id).all.map{|s| @h_steps[s.id]=s} 
      active_step_name = @h_steps[session[:active_step]].name if @h_steps[session[:active_step]]
      #  get_results()
      
      parsing_step = Step.where(:docker_image_id => @asap_docker_image.id, :name => 'parsing').first
      parsing_run = Run.where(:project_id => @project.id, :step => parsing_step.id).first
      @annots = Annot.where(:project_id => @project.id, :store_run_id => parsing_run.id, :data_type_id => 3, :dim => 1).all
    end
    
    @h_annots = {}
    @annots.map{|e| @h_annots[e.id] = e}
    @h_ott_projects = {}
    @h_ot_projects = {}
    @h_ontologies = {}
    @h_ots = {}
    CellOntology.all.map{|e| @h_ontologies[e.id] = e}
    @otts = OntologyTermType.all
    OttProject.where(:project_id => @project.id).all.each do |ott_project|
      @h_ott_projects[ott_project.ontology_term_type_id] = ott_project
    end
    ot_projects = OtProject.where(:project_id => @project.id)
    ot_projects.all.each do |ot_project|
      @h_ot_projects[ot_project.ontology_term_type_id] ||= []
      @h_ot_projects[ot_project.ontology_term_type_id].push ot_project
    end
    CellOntologyTerm.where(:id => ot_projects.map{|e| e.cell_ontology_term_id}).all.map{|ot| @h_ots[ot.id] = ot}
    
    respond_to do |format|
      format.html {
        if params[:global]
          render :partial => "edit"
        else
          #          @h_attrs_parsing = {}
          #          begin
          @h_attrs_parsing = Basic.safe_parse_json(@project.parsing_attrs_json, {}) if @project.parsing_attrs_json
          #          rescue
          #          end
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
      
      #      params[:sids].split(",").each do |sid|
      params[:shares].to_unsafe_h.each_key do |sid|
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

  def init_project_steps
 
#    (1 .. Step.count).each do |step_id|
   # Step.where(:version_id => @project.version_id).all.each do |step|
    if @asap_docker_image
      Step.where(:docker_image_id => @asap_docker_image.id).all.each do |step|
        project_step = ProjectStep.where(:project_id => @project.id, :step_id => step.id).first
        if !project_step
          project_step = ProjectStep.new(:project_id => @project.id, :step_id => step.id, :status_id => (step.name == 'parsing') ? 1 : nil  )
          project_step.save
        end
      end
    end
    
  end

  # POST /projects
  # POST /projects.json
  def create
    @project = Project.new(project_params)

    @h_formats = {}
    FileFormat.all.map{|f| @h_formats[f.name] = f}
    #    tmp_dir = Pathname.new(APP_CONFIG[:user_data_dir]) + @project.user_id.to_s
    #    Dir.mkdir(tmp_dir) if !File.exist?(tmp_dir)
    #    tmp_dir += @project.key
    #    Dir.mkdir(tmp_dir) if !File.exist?(tmp_dir)

    ### delete project if already exists with this key    
    if p = Project.where(:key => @project.key).first and editable? p
      delete_project(p)
    end
    
#    h_attrs_by_choice = {
#      'upload' => [:file_type, :sel_name, :nber_cols, :nber_rows],
#      'hca' =>  [:sel_provider_projects, :provider_project_id]
#    }

    tmp_attrs = params[:attrs] || {}
    tmp_attrs[:has_header] = 1 if tmp_attrs[:has_header]
  
    [:file_type, :sel_name, :nber_cols, :nber_rows, :sel_provider_projects, :provider_project_id, :provider_project_filename, :provider_project_title, :provider_project_filekey, :provider_project_fileurl, :colname_metadata, :rowname_metadata, :integrate_batch_paths, :integrate_n_pcs].each do |k|
      tmp_attrs[k] = params[k] if params[k] and (!params[k].is_a?(String) or !params[k].strip.empty?)
    end
    tmp_attrs[:file_type] = 'LOOM' if params[:tab_choice] == 'hca' #!tmp_attrs[:file_type] ### HCA import case  
  
    if params[:tab_choice] == 'hca' or (tmp_attrs[:file_type] and @h_formats[tmp_attrs[:file_type]].child_format != 'RAW_TEXT') ## delete the RAW_TEXT parsing options
      [:delimiter, :gene_name_col, :has_header].each do |k|
        tmp_attrs.delete(k)
      end
    end
    if params[:tab_choice] == 'upload'
      [:sel_provider_projects, :provider_project_id].each do |k|
        tmp_attrs.delete(k)
      end
    end
    
    @project.parsing_attrs_json = tmp_attrs.to_json
    @project.nber_cols = params[:nber_cols]
    @project.nber_rows = params[:nber_rows]
    @project.user_id = (current_user) ? current_user.id : 1
    @project.sandbox = (current_user) ? false : true
    @project.session_id = (s = Session.where(:session_id => session.id.to_s).first) ? s.id : nil
    # @project.version_id = params[:version_id].to_i #Version.where(:activated => true).last.id
    
    #    parsing_step = Step.where(:version_id => @project.version_id, :name => 'parsing').first
    @version = @project.version
    @h_env = Basic.safe_parse_json(@version.env_json, {})
    @list_docker_image_names = @h_env['docker_images'].keys.map{|k| @h_env['docker_images'][k]["name"] + ":" + @h_env['docker_images'][k]["tag"]}
    tmp_text = "full_name in (" + @list_docker_image_names.map{|e| "'#{e}'"}.join(",") + ")"
    @docker_images = DockerImage.where(tmp_text).all
    @asap_docker_image = @docker_images.select{|e| e.name == APP_CONFIG[:asap_docker_name]}.first

    parsing_step = Step.where(:docker_image_id => @asap_docker_image.id, :name => 'parsing').first 

    if params[:tab_choice] == 'upload'
      input_file = Fu.where(:project_key => @project.key).first
      file_path = nil
      if input_file and input_file.upload_file_name
        @project.input_filename = input_file.upload_file_name     
        @project.fu_id = input_file.id
        file_path = Pathname.new(APP_CONFIG[:upload_data_dir]) + input_file.id.to_s + input_file.upload_file_name
        logger.debug("CMD_ls0 " + `ls -alt #{file_path}`)
      end
    end
    
    default_de_filter = {
      :fc_cutoff => '2',
      :fdr_cutoff => '0.05' #,
      #    :pval_cutoff => '0.05'
    }    
    @project.de_filter_json = default_de_filter.to_json
    
    default_ge_filter = {
      :fdr_cutoff => 0.05
    }
    @project.ge_filter_json = default_ge_filter.to_json

    #    tmp_dir = Pathname.new(APP_CONFIG[:user_data_dir]) + @project.user_id.to_s
    #    File.delete tmp_dir + ('input.' + @project.extension) if File.exist?(tmp_dir + ('input.' + @project.extension))
    # logger.debug("1. File #{file_path} exists!") if File.exist?(file_path)

    @project.modified_at = Time.now

    respond_to do |format|
      if ((input_file and input_file.upload_file_name) or params[:provider_project_id] != '' ) and @project.save
        
        session[:active_dr_id] = 1
        
        # initialize directory
        tmp_dir = Pathname.new(APP_CONFIG[:user_data_dir]) + @project.user_id.to_s
        Dir.mkdir(tmp_dir) if !File.exist?(tmp_dir)
        tmp_dir += @project.key
        Dir.mkdir(tmp_dir) if !File.exist?(tmp_dir)
        
        if input_file and input_file.upload_file_name
          
          ## get preparsing data
          upload_dir = Pathname.new(APP_CONFIG[:data_dir]) +  'fus' + input_file.id.to_s
          output_json_file = upload_dir + 'output.json'
          h_output = Basic.safe_parse_json(File.read(output_json_file), {})
          h_inputs = {
            "MEX" => 'input.h5',
            "RDS" => 'input.loom'
          }
          input_filename = (h_inputs[h_output['detected_format']]) ? h_inputs[h_output['detected_format']] : input_file.upload_file_name
       
          ### get extension                                                                                                                                                   
          ext = input_filename.split(".").last
          if !['zip', 'bz', 'bz2', 'gz', 'h5', 'loom', 'h5ad'].include? ext
            ext = 'txt'
          end
          #ext = 'txt'
          # get preparsing output_json
          #output_json_path = Pathname.new(APP_CONFIG[:user_data_dir]) +  'fus' + input_file.id.to_s + 'output.json'
          #if File.exist? output_json_path
          #  h_output_json = Basic.safe_parse_json File.read(output_json_path), {}
          #  if h_output_json['detected_format'] and file_format = h_formats[h_output_json['detected_format']]
          #    ext = file_format.ext
          #  end
          #end

          ### set the project id to the upload file
          
          input_file.update_attributes(:project_id => @project.id)
          
          ### link upload to working directory
          upload_path =  Pathname.new(APP_CONFIG[:upload_data_dir]) + input_file.id.to_s + input_filename
          #`dos2unix #{upload_path}`
          #`mac2unix #{upload_path}`        
          ### to be sure because normally it is already deleted
          #          File.delete tmp_dir + ('input.' + ext) if File.exist?(tmp_dir + ('input.' + ext))
          # ext = input_file.upload_file_name.split(".").last
          # if ext != 'zip' and ext != 'gz'
          #   ext = 'txt'
          # end
          
          File.delete tmp_dir + ('input.' + ext) if File.exist?(tmp_dir + ('input.'+ ext))
          File.symlink upload_path, tmp_dir + ('input.' + ext) 
          #        logger.debug("2. File #{file_path} exists!") if File.exist?(file_path)
          ### parse batch_file
          
          #        @project.parse_batch_file()
        else
          ext = 'loom'
        end

        @project.update_attribute(:extension, ext)

        ### Setup HCA project key                                                                                                                                                
        if params[:tab_choice] == 'hca' and params[:provider_project_id] != ''
          h_provider_project = {
            :key => params[:provider_project_id],
            :provider_id => params[:provider_id]
          }
          provider_project = ProviderProject.where(h_provider_project).first
          if ! provider_project
            provider_project = ProviderProject.new(h_provider_project)
            provider_project.save
          end
          if params[:provider_project_title] != ''
            provider_project.update_attribute(:title, params[:provider_project_title])
          end
          @project.provider_projects << provider_project if !@project.provider_projects.include? provider_project

          ### add accessions
          #          h_q = {"fileFormat" => {"is" => ["matrix"]}}
          h_q = {"fileFormat" => {"is" => ["loom"]}, "projectId" => {"is" => [params[:provider_project_id]]}}
          q_txt = URI::encode(h_q.to_json)
          
          #          url = "https://service.explore.data.humancellatlas.org/repository/projects?filters=#{q_txt}"
          url = "https://service.azul.data.humancellatlas.org/index/projects?filters=#{q_txt}"
          cmd = "wget -U 'Safari Mac' -q -O - '#{url}'"
          puts "CMD: #{cmd}"
          res = `#{cmd}`
          puts "RES: " + res.to_json
          h_hca = JSON.parse(res) #Basic.safe_parse_json(res, {})
   #       puts "HCA: #{h_hca.to_json}"
          #:[{\"namespace\":\"geo_series\",\"accession\":\"GSE148963\"},{\"namespace\":\"insdc_project\",\"accession\":\"SRP257542\"},{\"namespace\":\"insdc_study\",\"accession\":\"PRJNA626628\"}]
          accession_types = ["array_express", "geo_series", "ega"] #"insdc_project", "insdc_study", "ega"]
 #         accession_types = ["arrayExpressAccessions", "geoSeriesAccessions"]
          h_accessions = {}
          accession_types.each do |acc_type|
            h_accessions[acc_type] = []
          end
          
          if h_hca['hits']
            h_hca['hits'].each do |hit|
              if hit["entryId"] == params[:provider_project_id]
                #            puts "entry: " + hit["projects"][0]["arrayExpressAccessions"].to_json #e['projects'][0].to_json
                accession_types.each do |k|
                  if h_accessions[k] and hit["projects"][0]['accessions']
                    hit["projects"][0]['accessions'].each do |accession|
                      if h_accessions[accession['namespace']]
                        h_accessions[accession['namespace']].push accession['accession']
                      end
                    end
                  end
                end
              end
            end
          end
          
          #     puts "ACCESSIONS: " + h_accessions.to_json
          
          Fetch.add_upd_exp_codes({
                                    :project => @project,
                                    :geo_codes => h_accessions["geo_series"].uniq.join(", "),
                                    :array_express_codes => h_accessions["array_express"].uniq.join(", "),
                                    :ega_codes => h_accessions["ega"].uniq.join(", ")
                                  })
          
        end

        ### init project_steps

        init_project_steps()
        
        ### read_write access

        manage_access()
        #   logger.debug("3. File #{file_path} exists!") if File.exist?(file_path)
        
        h_data = {}
        @project.parse_files(h_data)
        #   logger.debug("4. File #{file_path} exists!") if File.exist?(file_path)
        
        ### setup project sqlite database
        sqlite_schema_file = Pathname.new(Rails.root) + 'db' + 'asap_project_data.sql'
        sqlite_file = tmp_dir + 'asap_data.db'
        cmd = "less #{sqlite_schema_file} | sqlite3 #{sqlite_file}"
        `#{cmd}`
        logger.debug(cmd)
        #        @project.parse()
        session[:active_step]=parsing_step.id
        format.html { redirect_to project_path(@project.key) #, notice: 'Project was successfully created.'
        }
        format.json { render :show, status: :created, location: @project }
      elsif params[:integrate_batch_paths] and @project.save

        tmp_dir = Pathname.new(APP_CONFIG[:user_data_dir]) + @project.user_id.to_s
        Dir.mkdir(tmp_dir) if !File.exist?(tmp_dir)
        tmp_dir += @project.key
        Dir.mkdir(tmp_dir) if !File.exist?(tmp_dir)

        init_project_steps()
        manage_access()
 
        @project.integrate()
        format.html { redirect_to project_path(@project.key)}
      else
        format.html { redirect_to new_project_path(), notice: "<div class='alert alert-danger'>Something went wrong. Please send us <a href='mailto:bioinfo.epfl@gmail.com?subject=ASAP feedback'>feedback</a>.</div>"}
        format.json { render json: @project.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /projects/1
  # PATCH/PUT /projects/1.json
  def update

    require "csv"
    if @project
      tmp_dir = Pathname.new(APP_CONFIG[:user_data_dir]) + @project.user_id.to_s + params[:key]
      # parsing_step = Step.where(:version_id => @project.version_id, :name => 'parsing').first
      parsing_step = Step.where(:docker_image_id => @asap_docker_image.id, :name => 'parsing').first
      
      @h_steps={}
      Step.where(:docker_image_id => @asap_docker_image.id).all.map{|s| @h_steps[s.id]=s}
      
      if params[:project][:step_id]
        #      session[:active_step]= params[:project][:step_id]
        
        ### cannot apply to new asap
        #   (params[:project][:step_id].to_i + 1 .. Step.all.size).to_a.each do |step_id|
        #     project_step = ProjectStep.where(:project_id => @project.id, :step_id => step_id).first
        #     project_step.update_attribute(:status_id, nil)
        #   end
        ###
        
        project_step = ProjectStep.where(:project_id => @project.id, :step_id => params[:project][:step_id]).first
        project_step.update_attributes(:status_id => 1)
        params[:project][:status_id]=1
        params[:project][:duration]=0
        step = @h_steps[params[:project][:step_id].to_i] # Step.where(:id => params[:project][:step_id].to_i).first
        params[:attrs]||={}
        params[:project][(step.obj_name + "_attrs_json").to_sym]=(params[:attrs].keys.size > 0) ? params[:attrs].to_json : "{}" 
      else ### update of project details 
        
        #@project.parse_batch_file()
        #  cmd = "rails parse_batch_file[#{@project.key}]"
        #  `#{cmd}`
        
        logger.debug("TEST GSE")
        
        Fetch.add_upd_exp_codes({
                                  :project => @project,
                                  :geo_codes => params[:geo_codes], 
                                  :array_express_codes => params[:array_express_codes]})
        
        
        if params[:project][:doi] ## replace :pmid by :doi
          logger.debug("DOI: " + params[:project][:doi])
          h_article = Fetch.doi_info(params[:project][:doi])
          article = Article.where(:doi => params[:project][:doi]).first
          if !article
            article = Article.new(h_article)
            article.save
          else
            article.update_attributes(h_article)
          end
        end
        
        ### if organism changes, update the gene file                                                                                                                                                
        if @project.organism_id != params[:project][:organism_id].to_i
          #    parsing_dir =  tmp_dir + 'parsing'
          #    gene_names_file = parsing_dir + 'gene_names.json'
          #    cmd = "java -jar #{Rails.root}/lib/ASAP.jar -T RegenerateNewOrganism -organism #{params[:project][:organism_id]} -j #{gene_names_file} -o #{parsing_dir}"
          #    logger.debug("CMD: " + cmd)
          #    `#{cmd}`
          #    
          #    ### rewrite download files
          #    Step.where(["id <= ?", @project.step_id]).all.select{|e| e.id < 4}.each do |step|
          #      output_dir =  tmp_dir + step.name 
          #      output_file = output_dir + 'output.tab'
          #      cmd = "java -jar #{Rails.root}/lib/ASAP.jar -T CreateDLFile -f #{output_file} -j #{gene_names_file} -o #{output_dir + 'dl_output.tab'}"
          #      logger.debug("CMD: " + cmd)
          #      `#{cmd}`
          #    end
          
          
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

      [:replaced_by_project_key, :replaced_by_comment].each do |e|
        params[:project][e] = nil if params[:project][e] == ''
        end
      
      respond_to do |format|
        if @project.update(project_params)
          
          ### read_write access                                                                                                                                   
          manage_access()
          
          #  if params[:project][:step_id]
          
          #    list_steps = (params[:project][:step_id].to_i .. 7).to_a
          
          #    ### remove foreign keys to jobs  
          
          #    list_steps.each do |step_id|
          #      if step_id == 1
          #        @project.update_attribute(:parsing_job_id, nil)
          #      elsif step_id == 2
          #        @project.update_attribute(:filtering_job_id, nil)
          #      elsif step_id == 3
          #        @project.update_attribute(:normalization_job_id, nil)
        #      elsif step_id == 4
          #        @project.project_dim_reductions.each do |pdr|
          #          pdr.update_attribute(:job_id, nil)
          #        end
          #      elsif step_id == 5
          #        @project.clusters.map{|cluster| cluster.update_attribute(:job_id, nil)}
          #      elsif step_id == 6
          #        @project.diff_exprs.map{|de| de.update_attribute(:job_id, nil)}
          #      elsif step_id == 7
        #        @project.gene_enrichments.map{|ge| ge.update_attribute(:job_id, nil)}
        #      end
        #    end
        
        #    ### remove pending delayed jobs
        #    list_pending_jobs = @project.jobs.select{|j| list_steps.include?(j.step_id) and j.status_id == 1}
        #    Delayed::Job.where(:id => list_pending_jobs.map{|j| j.delayed_job_id}).all.destroy_all
        #    list_pending_jobs.map{|j| j.destroy}
        
        
        #    ### kill jobs
        #    list_steps.each do |step_id|
        #      if step_id !=4
        #        Basic.kill_jobs(logger, @project.id, step_id, @project)
        #      else
        #        @project.project_dim_reductions.each do |pdr|
        #          Basic.kill_jobs(logger, @project.id, step_id, pdr)
        #        end
        #      end
        #    end
        
        #    #### remove files
        #    list_steps.each do |step_id|
        #      if ! (step_id == 5 and params[:project][:step_id].to_i == 3)
        #        ProjectStep.where(:project_id => @project.id, :step_id => step_id).all.each do |ps|
        #          step_name = ps.step.name
        #          if File.symlink?(tmp_dir + step_name)
        #            File.delete(tmp_dir + step_name)
        #          else
        #            FileUtils.rm_r Dir.glob((tmp_dir + step_name).to_s + "/*")
        #          end
        #          ps.update_attributes(:status_id => nil) if ps.step_id != params[:project][:step_id].to_i
        #          logger.debug("PROJECTSTEP: " + ps.to_json)
        #        end
        #      end
        #    end
        
        #    ### clean existing clusters / de analyses / visualization / diff_exprs                                                                                                                                                              
        #    if params[:project][:step_id].to_i < 4
        #      @project.gene_enrichments.destroy_all
        #      @project.diff_exprs.destroy_all
        #      @project.project_dim_reductions.destroy_all
      #      @project.clusters.select{|c| !c.step_id or c.step_id > 2}.map{|c| c.destroy} if params[:project][:step_id].to_i != 3
        #    end
        
        #    if @project.step_id==1
        #      @project.parse_files()
        #    elsif @project.step_id==2
      #      @project.run_filter()
        #    elsif @project.step_id==3
        #      @project.run_norm()          
        #    end
        
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
       # end
        
          
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
              session[:override_active_step]=parsing_step.id
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
  end

  def delete_project(p)

    begin
      ## remove foreign keys to jobs    
      p.update_attributes(:parsing_job_id => nil, :filtering_job_id => nil, :normalization_job_id => nil, :being_deleted => true)
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
    
    ### delete potential archive
    project_dir = Pathname.new(APP_CONFIG[:user_data_dir]) + p.user_id.to_s
    archive_file = project_dir + (p.key + '.tgz')
    if File.exist? archive_file
      File.delete archive_file
    end

    # delete objects
  
      p.shares.destroy_all
      p.annot_cell_sets.destroy_all
#      clas = p.clas
#      ClaVote.where(:cla_id => clas.map{||}
#      p.clas.destroy_all
      #    p.annots.map{|a| a.clas}.flatten.destroy_all
      p.annots.destroy_all
      p.del_runs.destroy_all
      p.active_runs.destroy_all
      p.fos.destroy_all

    ## delete runs
    p.runs.sort{|a,b| b.id <=> a.id}.each do |r|
      RunsController.destroy_run_call p, r
    end
    #    p.runs.destroy_all
    ##### strange have to do thing for a project ### not normal 
    p.reqs.map{|r| r.runs.map{|r| RunsController.destroy_run_call p, r}}
    #### 
    p.reqs.destroy_all
      #p.fus.destroy_all
      p.project_steps.destroy_all
      p.gene_enrichments.destroy_all
      p.diff_exprs.destroy_all
      p.project_dim_reductions.destroy_all
      p.selections.destroy_all
      p.clusters.destroy_all
  #    p.gene_sets.destroy_all
      # p.jobs.select{|j| j.status_id == 1}.map{|j| j.destroy}
      list_pending_jobs = p.jobs.select{|j| j.status_id == 1}
      Delayed::Job.where(:id => p.jobs.map{|j| j.delayed_job_id}).all.destroy_all
      list_pending_jobs.map{|j| j.destroy}
      
      ### delete fus
      p.fus.map{|fu|
        #      file_path = Pathname.new(APP_CONFIG[:upload_data_dir]) + fu.id.to_s + fu.upload_file_name
        #      File.delete file_path if File.exist?(file_path)
      }
      p.fus.destroy_all
      p.exp_entries.clear
      p.provider_projects.clear
      p.direct_links.destroy_all
      #    p.runs.destroy_all

      Sunspot.remove(p)
      p.destroy
      #      Sunspot.remove(p)
    rescue Exception => e
      puts e.message
      logger.debug(e.backtrace)
      p.update_attributes(:being_deleted => false)
    end
  end
  
  # DELETE /projects/1
  # DELETE /projects/1.json
  def destroy
    
    if editable? @project
      delete_project(@project)
    end
    get_projects()

    @h_archive_statuses = {}
    ArchiveStatus.all.map{|s| @h_archive_statuses[s.id] = s}
    @h_statuses = {}
    Status.all.map{|o| @h_statuses[o.id]=o}
    @h_organisms = {}
    Organism.all.map{|o| @h_organisms[o.id]=o}
    
    respond_to do |format|
      #      format.html { redirect_to projects_url, notice: 'Project was successfully destroyed.' }
      format.html {
        #        render :partial => 'index'
        render :nothing => true, :body => nil
      }
      
      format.json { head :no_content }
    end
  end
  
  private
  # Use callbacks to share common setup or constraints between actions.
  def set_project
    public_id = params[:key].gsub(/ASAP/, "")
    public_id = (public_id.match(/^\d+$/)) ? public_id.to_i : 0
    @project = Project.where(["key = ? or public_id = ?", params[:key],public_id]).first
    if @project
      @project_dir =  Pathname.new(APP_CONFIG[:user_data_dir]) + @project.user_id.to_s + @project.key
      @project_type = @project.project_type
      @organism = @project.organism
      @version =@project.version
      @h_env = Basic.safe_parse_json(@version.env_json, {})
      if @h_env['docker_images']
        @list_docker_image_names = @h_env['docker_images'].keys.map{|k| @h_env['docker_images'][k]["name"] + ":" + @h_env['docker_images'][k]["tag"]}
        @docker_images = DockerImage.where("full_name in (" + @list_docker_image_names.map{|e| "'#{e}'"}.join(",") + ")").all 
        @asap_docker_image = @docker_images.select{|e| e.name == APP_CONFIG[:asap_docker_name]}.first
      end
    end
  end
  
  # Never trust parameters from the scary internet, only allow the white list through.
  def project_params
    #      params.fetch(:project, {})
  
    params.fetch(:project).permit(:name, :key, :organism_id, :group_filename, :input_filename, :status_id, :duration, :step_id, :filter_method_id, :norm_id, :parsing_attrs_json, :filter_method_attrs_json, :norm_attrs_json, :public, :pmid, :doi, :diff_expr_filter_json, :gene_enrichment_filter_json, :read_access, :write_access, :replaced_by_project_key, :replaced_by_comment, :version_id, :technology, :tissue, :extra_info, :description, :project_type_id)
  end
end
  
