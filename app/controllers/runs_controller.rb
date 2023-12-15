class RunsController < ApplicationController
  before_action :set_run, only: [:get_de_gene_list, :get_ge_geneset_list, :show, :edit, :update, :destroy]
  before_action :get_base_data, only: [:get_de_gene_list, :get_ge_geneset_list, :download_de_gene_list]
  include ApplicationHelper
  
  def get_base_data 
    @h_dashboard_card = {}
    @h_dashboard_card[@step.id] = JSON.parse(@step.dashboard_card_json)
    @h_attrs = (@step.attrs_json and !@step.attrs_json.empty?) ? JSON.parse(@step.attrs_json) : {}
    @h_nber_runs = JSON.parse(@ps.nber_runs_json)
    @h_steps = {}
    #    Step.where(:version_id => @project.version_id).all.map{|s| @h_steps[s.id] = s}
    Step.where(:docker_image_id => @asap_docker_image.id).all.map{|s| @h_steps[s.id] = s}
    @h_statuses = {}
    Status.all.map{|s| @h_statuses[s.id] = s}
    #    @h_std_methods = {}
    #    StdMethod.all.map{|s| @h_std_methods[s.id] = s}
  end

  def get_ge_geneset_list
    params[:from] ||= 'ge_results'
    @h_ge_filters = Basic.safe_parse_json(@project.ge_filter_json, {})
    @limit = 3000
    @data = []
    @h_run_attrs = (@run.attrs_json) ? JSON.parse(@run.attrs_json) : {}

    @project_dir = Pathname.new(APP_CONFIG[:user_data_dir]) + @project.user_id.to_s + @project.key
    filename =  @project_dir + "ge" + @run.id.to_s + "output.json"
    h_output = Basic.safe_parse_json(File.read(filename), {})
    @fields = h_output["headers"]
    h_fields = {}
    @fields.each_index do |i|
      h_fields[@fields[i]] = i
    end
#    h_fields['genes'] = h_fields.keys.size

#    @h_gsis = {}
#    res = Basic.sql_query2(:asap_data, @h_env['asap_data_db_version'], 'gene_set_items', '', '*', "gene_set_id = #{@h_run_attrs['gene_set_id']} and identifier IN (#{h_output[params[:type]].map{|e| e[0]}})")
#    res.each do |gs|
#      @h_gene_set_items[gsi.name] = gsi
#    end

#    h_genes = Basic.safe_parse_json(params[:genes_json], {})
    
    if  h_output[params[:type]]
      h_output[params[:type]].sort{|a, b| b[h_fields['effect size']].to_f <=> a[h_fields['effect size']].to_f}.each do |e|
        #      h_output[params[:type]].each do |e|
        if e[h_fields['fdr']] <= @h_ge_filters['fdr_cutoff'].to_f
   #       e['genes'] =  @h_gene_set_items[e['name']].content.split(",").map{|gid| gid.to_i}.select{|gid| h_genes[gid]}.map{|g| h_genes[gid]}]  
          @data.push e
        end
      end
    end
    @nber_genesets = @data.size
    
    if !params[:download]
      if params[:from] == 'ge_results'
        render :partial => 'get_ge_geneset_list'
      elsif params[:from] == 'markers'
        render :partial => 'get_simple_ge_geneset_list'
      end
    else
      send_data ((params[:format]=='json') ? @data.to_json : @data.map{|e| e.join("\t")}.join("\n")), type: 'text', disposition: "attachment; filename=" + @project.key  + "_" + display_run_ultra_short_txt(@run) + "_de_table_#{params[:type]}"  + "." + ((params[:format]=='json') ? 'json' : 'txt')
    end
        
  end
  
  def get_de_gene_list
    params[:from] ||= 'de_results'
    @fields = ["Gene index", "EnsemblID", "Gene name", "Alt names", "Description", "logFC", "P-value", "FDR", "Avg group1", "Avg group2"]
    @limit = 3000
    @h_std_method_attrs = {
      @std_method.id => Basic.get_std_method_attrs(@std_method, @step)[:h_attrs]
    }
    @h_run_attrs = (@run.attrs_json) ? JSON.parse(@run.attrs_json) : {}
    @data = []
    @project_dir = Pathname.new(APP_CONFIG[:user_data_dir]) + @project.user_id.to_s + @project.key
    list_filtered_rows = []
    if params[:from]== 'ge_form'
      filename = @project_dir + "tmp" + "#{(current_user) ? current_user.id : 1}_#{@run.id}_filtered.json"
      tmp_h = Basic.safe_parse_json(File.read(filename), {})
      list_filtered_rows = tmp_h[params[:type]] if tmp_h[params[:type]]
    else
      filename = @project_dir + "de" + @run.id.to_s + "filtered.#{params[:type]}.json"
      list_filtered_rows = Basic.safe_parse_json(File.read(filename), [])
    end
    @h_filtered_rows = {}
#    list_filtered_rows = []
#    begin
#      list_filtered_rows = JSON.parse(File.read(filename))
#    rescue
#    end
    list_filtered_rows.map{|e| @h_filtered_rows[e.to_i] = 1}
    @nber_genes = list_filtered_rows.size
    
    filename = @project_dir + "de" + @run.id.to_s + "output.txt"
    i = 0
    j = 0

    @tmp_data = File.readlines(filename)
    if params[:type] == 'up'
      #File.open(filename, 'r') do |f|
      @tmp_data.reverse.each do |l|     
        #      while (l = f.gets  and (params[:download] or j < @limit) 
        if @h_filtered_rows[@tmp_data.size-1-i]
          t = l.chomp.split("\t")
          t[2] = t[2].split(",").join(", ")
          @data.push t
          j+=1
        end
        i+=1
        if j == @limit and !params[:download]
          break
        end
      end
    else
      
      @tmp_data.each do |l|
        if @h_filtered_rows[i]
          t = l.chomp.split("\t")
          t[2] = t[2].split(",").join(", ")
          @data.push t
          j+=1
        end
        i+=1
        if j == @limit and !params[:download]
          break
        end
      end
    end
    #end
    #    @data.reverse! if params[:type] == 'up'
    if !params[:download]
      render :partial => 'get_de_gene_list'
    else
      send_data ((params[:format]=='json') ? @data.to_json : @data.map{|e| e.join("\t")}.join("\n")), type: 'text', disposition: "attachment; filename=" + @project.key  + "_" + display_run_ultra_short_txt(@run) + "_de_table_#{params[:type]}"  + "." + ((params[:format]=='json') ? 'json' : 'txt')
    end
  end

  # GET /runs
  # GET /runs.json
  def index
    @runs = Run.all
  end

  # GET /runs/1
  # GET /runs/1.json
  def show
  end

  # GET /runs/new
  def new
    @run = Run.new
  end

  # GET /runs/1/edit
  def edit
  end

  # POST /runs
  # POST /runs.json
  def create
    @run = Run.new(run_params)

    respond_to do |format|
      if admin? and @run.save
        format.html { redirect_to @run, notice: 'Run was successfully created.' }
        format.json { render :show, status: :created, location: @run }
      else
        format.html { render :new }
        format.json { render json: @run.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /runs/1
  # PATCH/PUT /runs/1.json
  def update
    respond_to do |format|
      if admin? and  @run.update(run_params)
        format.html { redirect_to @run, notice: 'Run was successfully updated.' }
        format.json { render :show, status: :ok, location: @run }
      else
        format.html { render :edit }
        format.json { render json: @run.errors, status: :unprocessable_entity }
      end
    end
  end

  def self.destroy_run project, step, run

    project_dir = Pathname.new(APP_CONFIG[:user_data_dir]) + project.user_id.to_s + project.key
    step_dir = project_dir + step.name
    output_dir = (step.multiple_runs == true) ? (step_dir + run.id.to_s) : step_dir
    
    tmp_dir = project_dir + 'tmp'
    ## kill run if necessary
    Basic.kill_run run
    
    ## remove potential annotations
    ### from the loom
    #run.annots.each do |annot|
    h_outputs = JSON.parse(run.output_json)
    logger.debug(h_outputs.to_json)
    
    annots1 = run.annots 
    annots2 = Annot.where(:ori_run_id => run.id).all
    #store_run_annots = Annot.where(:store_run_id => run.id).all
    now = Time.now.to_i
    h_annots= {}
    all_annots = (annots1 | annots2)
    all_annots.each do |annot|
      h_annots[annot.filepath]||=[] 
      h_annots[annot.filepath].push annot
    end
    h_annots.each_key do |filepath|
      if File.exist? (project_dir + filepath) and !["gene_filtering", "cell_filtering"].include? step.name
        tmp_file = project_dir + "tmp" + ("remove_metadata_#{now}.json")
        tmp_data = {:meta => h_annots[filepath].map{|a| a.name}}
        File.open(tmp_file, 'w') do |f|
          f.write tmp_data.to_json
        end
        cmd = "java -jar #{APP_CONFIG[:local_asap_run_dir]}/ASAP.jar -T RemoveMetaData -loom #{project_dir + filepath} -metaJSON '#{tmp_file}' 2>&1 > tmp/remove_metadata_output_#{now}.json"
        File.open(project_dir + "tmp" + "toto.txt", "w") do |f|
          f.write("CMD: " + cmd)
          `#{cmd}`
        end
      end
    end
    ## delete loom file if it's a filtering 
    #    if ["gene_filtering", "cell_filtering"].include? step.name
    #      h_annots.each_key do |filepath|
    #        File.delete(project_dir + filepath) if 
    #      end
    #    end
    #    (annots1 | annots2).each do |annot|
    #      if File.exist? (project_dir + annot.filepath)
    #        cmd = "java -jar #{APP_CONFIG[:local_asap_run_dir]}/ASAP.jar -T RemoveMetaData -o #{tmp_dir} -loom #{project_dir + annot.filepath} -meta '#{annot.name}' 2>&1 > tmp/bla.txt"
    #        logger.debug("CMD: " + cmd)
    #        `#{cmd}`
    #      end
    #    end
    
    #    if h_outputs
    #      h_outputs.each_key do |k|
    #        h_outputs[k].each_key do |output_key|
    #          t = output_key.split(":")
    #          if t.size == 2 
    #            if File.exist? (project_dir + t[0])
    #              cmd = "java -jar #{APP_CONFIG[:local_asap_run_dir]}/ASAP.jar -T RemoveMetaData -o #{tmp_dir} -loom #{project_dir + t[0]} -meta #{t[1]} 2>&1 > tmp/bla.txt"
    #              logger.debug("CMD: " + cmd)
    #              `#{cmd}`
    #            end
    #            #        elsif t.size == 1
    #            #          if File.exist? (project_dir + t[0])
    #            #            logger.debug("DEL_FILE: " + t.to_json + '---' + (project_dir + t[0]).to_s)
    #            #            File.delete (project_dir + t[0]) 
    #            #          end
    #          end
    #        end
    #      end
    #    end
    
    #    logger.debug()
    FileUtils.rm_r output_dir if File.exist? output_dir
    
    ### from the database
    all_annots.map do |annot| 
    #  cell_sets = CellSet.where(:id => annot.clas.map{|e| e.cell_set_id}).all
    #  cell_sets.each do |cell_set|
    #    other_clas = Cla.
    #  end
      annot.clas.map{|c| c.cla_votes.destroy_all}
      annot.clas.destroy_all
      annot.annot_cell_sets.destroy_all
    end
    annots1.destroy_all
    annots2.destroy_all
 
#    all_annots.destroy_all
    store_run_annots = Annot.where(:store_run_id => run.id).all
    store_run_annots.map{|annot| 
      annot.clas.map{|c| c.cla_votes.destroy_all}
      annot.clas.destroy_all
      annot.annot_cell_sets.destroy_all
    }
    store_run_annots.destroy_all ## shouldn't need to add this line if everything happens normally...
    run.fos.destroy_all
    
    ## remove the run
    active_run = run.active_run
    active_run.destroy if active_run
    
    ## move run in the deleted_runs if it finished or failed                                                                                                                    
    if [3, 4].include? run.status_id
      h_run = run.as_json
        if ! DelRun.where(h_run).first
          del_run = DelRun.new(h_run)
          del_run.run_id = h_run["id"]
          del_run.save!        
        end
    end
    
    run.destroy  
    
      
  end

  def self.destroy_children project, step, run #, h_step_ids
    if run.children_run_ids
      run_children = run.children_run_ids.split(",")
      if run_children.size > 0
        @log += "children: " + run_children.to_json + ". "
        runs = Run.where(:project_id => project.id, :id => run_children).all
        runs.each do |run|
          @h_step_ids[run.step_id] = 1
          @log += "call destroy_children on #{run.id}. "
          h_step_ids = destroy_children project, step, run
        end
      end
    end
    # else
    @h_step_ids[run.step_id] = 1
    @log += "destroy #{run.id}. "
    destroy_run project, step, run

    #return h_step_ids
    #  end
  end
  
  def self.destroy_run_call project, run
    start_time = Time.now
    @log = ""
    log = ''
    log += (Time.now - start_time).to_s + " step 2</br>"

    step = run.step

    ActiveRecord::Base.transaction do

      ## edit parent's children_run_ids                                                                                                                                  
      parents = (run.run_parents_json) ? JSON.parse(run.run_parents_json) : []
      if parents
        parent_runs = Run.where(:project_id => project.id, :id => parents.map{|p| p['run_id']}).all
        parent_runs.each do |parent_run|
          children_run_ids = parent_run.children_run_ids.split(",").reject{|e| e == run.id}
          parent_run.update_attribute(:children_run_ids, children_run_ids.join(","))
        end
      end
      
      log += (Time.now - start_time).to_s + " step 3</br>"
      ## destroy run and descendants                                                                                                                                                                                    
      log += "call destroy_children on #{run.id}. "
      @h_step_ids = {}
      destroy_children project, step, run
      
      log += (Time.now - start_time).to_s + " step 4</br>"
      ### update project_step for each step affected                                                                                                                                                                    
      @h_step_ids.each_key do |step_id|
        Basic.upd_project_step project, step_id
      end
      
      log += (Time.now - start_time).to_s + " step 5</br>"
      Basic.upd_project_size project
    end
    return log

  end

  def destroy_run_call project, run
    RunsController.destroy_run_call(project, run)
  end

  # DELETE /runs/1
  # DELETE /runs/1.json
  def destroy
    @log = ''
    start_time = Time.now
    @log += (Time.now - start_time).to_s + " start</br>"
    if editable?(@project)

      @log += RunsController.destroy_run_call(@project, @run)
      
      respond_to do |format|
        format.json { #redirect_to runs_url, notice: 'Run was successfully destroyed.' }
          render :json => {:status => 'success', :log => @log}
          #redirect_to {:controller => :projects, :action => :get_step, :key => @project.key, :step_id => @step.id, "_method" => :get}, {:turbolinks => false}
        }
        #      format.json { head :no_content }
      end
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_run
      @run = Run.find(params[:id])
      @project = @run.project
      @version =@project.version
      @h_env = Basic.safe_parse_json(@version.env_json, {})
      @list_docker_image_names = @h_env['docker_images'].keys.map{|k| @h_env['docker_images'][k]["name"] + ":" + @h_env['docker_images'][k]["tag"]}
      @docker_images = DockerImage.where("full_name in (#{@list_docker_image_names.map{|e| "'#{e}'"}.join(",")})").all
      @asap_docker_image = @docker_images.select{|e| e.name == APP_CONFIG[:asap_docker_name]}.first

      @step = @run.step
      @std_method = @run.std_method
      @ps = ProjectStep.where(:project_id => @project.id, :step_id => @step.id).first
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def run_params
      params.fetch(:run, {})
    end
end
