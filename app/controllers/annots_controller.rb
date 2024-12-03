class AnnotsController < ApplicationController
  before_action :set_annot, only: [:get_cats, :get_cat_legend, :get_cat_details, :show, :edit, :update, :destroy]

  def get_cat_details
    @project = @annot.project
    if readable?(@project) and @annot.data_type_id == 3
      @project_dir =  Pathname.new(APP_CONFIG[:user_data_dir]) + @project.user_id.to_s + @project.key
      @cmd = "java -jar #{APP_CONFIG[:local_asap_run_dir]}/ASAP.jar -T MatchValues -loom #{@project_dir + @annot.filepath} -iAnnot #{@annot.name} -value #{params[:cat_value]}"
      @h_results = JSON.parse(`#{@cmd}`)

      @h_results['list_names'] = []
      @test = nil
      if @annot.dim == 1
        ## get cell names
        cmd = "java -jar #{APP_CONFIG[:local_asap_run_dir]}/ASAP.jar -T ExtractMetadata -loom #{@project_dir + @annot.filepath} -meta /col_attrs/CellID"
        h_res = JSON.parse(`#{cmd}`)
        @h_results["indexes_match"].each do |i|
          @h_results["list_names"].push h_res["values"][i]
        end
      end

    end

    render :partial => 'get_cat_details'
  end

  def get_cats
    @project = @annot.project
    if readable?(@project) and @annot.data_type_id == 3
      @project_dir =  Pathname.new(APP_CONFIG[:user_data_dir]) + @project.user_id.to_s + @project.key
      @cmd = "java -jar #{APP_CONFIG[:local_asap_run_dir]}/ASAP.jar -T ExtractMetadata -names -loom #{@project_dir + @annot.filepath} -meta \"#{@annot.name}\""
      @h_results = JSON.parse(`#{@cmd}`)
      @cats = @h_results['values'].uniq
      
      @h_list_indexes_by_cat={}
      ## init
      @cats.each do |c|
         @h_list_indexes_by_cat[c]=[]
      end
      @h_results['values'].each_index do |i|
        @h_list_indexes_by_cat[@h_results['values'][i]].push i
      end
      render :partial => 'get_cats'
    end
  end

  def get_cat_legend
    @list_cats = Basic.safe_parse_json(@annot.list_cat_json, [])
    @h_cats = Basic.safe_parse_json(@annot.categories_json, [])   
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
    
#    @palette = ["ff0000","ffc480","149900","307cbf","d580ff","cc0000","bf9360","1d331a","79baf2","deb6f2","990000","7f6240","283326","2d4459","8f00b3","4c0000","ccb499","00f220","accbe6","520066","330000","594f43","16591f","697c8c","290033","cc3333","e59900","ace6b4","262d33","ee00ff","e57373","8c5e00","2db350","295ba6","c233cc","994d4d","664400","336641","80b3ff","912699","663333","332200","86b392","4d6b99","3d1040","bf8f8f","cc9933","4d6653","202d40","c566cc","8c6969","e5bf73","008033","0044ff","944d99","664d4d","594a2d","39e67e","00144d","a37ca6","f2553d","403520","30bf7c","3d6df2","ff80f6","a63a29","ffeabf","208053","2d50b3","73396f","bf6c60","736956","134d32","13224d","4d264a","402420","f2c200","53a67f","7391e6","735671","ffc8bf","8c7000","003322","334166","40303f","ff4400","ccad33","3df2b6","a3b1d9","ff00cc","b23000","594c16","00bf99","737d99","8c0070","7f2200","ffe680","66ccb8","393e4d","331a2e","591800","b2a159","2d5950","00138c","ffbff2","330e00","7f7340","204039","364cd9","b30077","ff7340","ffee00","b6f2e6","1d2873","40002b","cc5c33","403e20","608079","404880","e639ac","994526","bfbc8f","00998f","1a1d33","731d56","f29979","8c8a69","00736b","0000f2","ff80d5","8c5946","778000","39e6da","0000d9","a6538a","59392d","535900","005359","0000bf","f20081","bf9c8f","3b4000","003c40","2929a6","660036","735e56","ced936","30b6bf","bfbfff","bf8fa9","403430","fbffbf","23858c","8273e6","d90057","f26100","ccff00","79eaf2","332d59","a60042","bf4d00","cfe673","7ca3a6","14004d","bf3069","331400","8a994d","394b4d","170d33","8c234d","ff8c40","494d39","005266","a799cc","bf6086","995426","a3d936","39c3e6","7d7399","804059","733f1d","739926","23778c","290066","59434c","f2aa79","88ff00","0d2b33","8c40ff","b20030","b27d59","3d7300","59a1b3","622db3","7f0022","7f5940","294d00","acdae6","2a134d","40101d","33241a","4e6633","566d73","7453a6","f27999","ffd9bf","bfd9a3","00aaff","4c4359","4d2630","8c7769","92a67c","006699","2b2633","ffbfd0","ff8800","52cc00","002b40","6d00cc","99737d","a65800","234010","3399cc","4b008c","33262a","663600","a1ff80","86a4b3","9c66cc","7f0011","331b00","79bf60","007ae6","583973","f23d55","cc8533","518040","003059","312040","59161f","4c3213","688060","001b33","69238c","bf606c"].map{|e| "##{e}"} #(x => "#" + x)

    render :partial => 'get_cat_legend'
  end

  # GET /annots
  # GET /annots.json
  def index
    @annots = Annot.all
  end

  def compute_bins l, nber_bins
    min = l.min #.map{|e| e.to_f}.min                                                                                                                                                                       
    max = l.max #.map{|e| e.to_f}.max                                                                                                                                                                        

    h = {:bin_counts => [], :min => min, :max => max}
    #@h_bin_counts = []
    (0 .. nber_bins-1).map{|bin_i| h[:bin_counts][bin_i] = 0}
    bin_size = (max-min).to_f / nber_bins
    #          if  !(@min.is_a?(Float) && @min.nan?) and !(@bin_size.is_a?(Float) && @bin_size.nan?)                                                                                                                                      
    l.each do |e| #.map{|e| e.to_f}.each do |e|                                                                                                                                                            
    #  logger.debug("MIN: " + @min.to_json + " BIN_SIZE: " + @bin_size.to_json + " VAL: " + e.to_json)
      #   if !(e.is_a?(Float) && e.nan? and @bin_size > 0)                                                                                                                                                                      
      if bin_size > 0
        bin_i = ((e- min)/bin_size).to_i
        bin_i = nber_bins-1 if bin_i == nber_bins
        #     @log = "#{bin_i} -> #{e} / min = #{@min} / max = #{max} / bin_size = #{@bin_size}" if !@bin_counts[bin_i]                                                                            
        bin_i = 0 if bin_i < 0
        h[:bin_counts][bin_i]||= 0
        h[:bin_counts][bin_i] += 1
        
      end
      #           end                                                                                                                                                                                                           
    end
    h[:bin_size] = bin_size
    return h
  end

  # GET /annots/1
  # GET /annots/1.json
  def show
    @h_steps = {}
    @h_steps_by_name = {}
    @h_statuses = {}
    @project = @annot.project
  #  Step.where(:version_id => @project.version_id).all.map{|s| @h_steps[s.id]=s; @h_steps_by_name[s.name]=s}
    steps = Step.where(:docker_image_id => @asap_docker_image.id).all
    @h_attrs_by_step = {}

    steps.map{|s| @h_attrs_by_step[s.id]= Basic.safe_parse_json(s.attrs_json, {})}
    steps.select{|s| (s.admin == false or admin?) and (!@h_attrs_by_step[s.id]['project_types'] or @h_attrs_by_step[s.id]['project_types'].include?((@project_type) ? @project_type.tag : nil))}.map{|s| @h_steps[s.id]=s; @h_steps_by_name[s.name]=s}
    Status.all.map{|s| @h_statuses[s.id]=s}

#    @step = Step.find_by_name('cell_')
    @step = @h_steps_by_name['metadata_expr']
    @annot_step = @run.step
    #  @annot_ps = ProjectStep.where(:project_id => @project.id, :step_id => @annot_step.id).first
    @h_attrs = Basic.safe_parse_json(@annot_step.attrs_json, {})
 
    @project_dir =  Pathname.new(APP_CONFIG[:user_data_dir]) + @project.user_id.to_s + @project.key
#    @run = @annot.run
    @h_dashboard_card = {}
    @h_dashboard_card[@run.step_id] = JSON.parse(@h_steps[@run.step_id].dashboard_card_json)
    
    ## get annot
    @h_results = {}
    @cmd = ""
    @log = ''
    @res = nil
    @genes_annot = nil
    @cells_annot = nil
    @h_sums = {}
    if @annot.dim == 3
      @genes_annot = Annot.where(:name => '/row_attrs/Gene', :store_run_id => @annot.store_run_id).first
      @cells_annot = Annot.where(:name => '/col_attrs/CellID', :store_run_id => @annot.store_run_id).first
       @cmd = " ./hdf5/bin/h5dump -y -w 0 -d \"#{@annot.name}\" --start=\"0,0\" --block=\"10,10\" #{@project_dir + @annot.filepath}"
#      @cmd = " ./hdf5/bin/h5dump -y -w 0 -d \"/layers/norm_1_asap_seurat\" --start=\"0,0\" --block=\"10,10\" /data/asap2/users/1/hv08j9/parsing/output.loom" 
           # @cmd = "docker run -it --network=asap2_asap_network -e HOST_USER_ID=$(id -u) -e HOST_USER_GID=$(id -g) --rm -v /data/asap2:/data/asap2 -v /srv/asap_run/srv:/srv fabdavid/asap_run:v5 ./h5dump -y -w 0 -d \"/layers/norm_1_asap_seurat\" --start=\"0,0\" --block=\"10,10\" /data/asap2/users/1/hv08j9/parsing/output.loom"
#      @cmd ="docker run -it --network=asap2_asap_network -e HOST_USER_ID=$(id -u) -e HOST_USER_GID=$(id -g) --rm -v /data/asap2:/data/asap2  -v /srv/asap_run/srv:/srv fabdavid/asap_run:v5 ./h5dump -y -w 0 -d \"#{@annot.name}\"  --start=\"0,0\" --block=\"10,10\" #{@project_dir + @annot.filepath}"
      #      @cmd = "java -jar #{APP_CONFIG[:local_asap_run_dir]}/ASAP.jar -T ExtractRow -prec 2 -i #{s[:row_i]} -f #{loom_path} -iAnnot #{@dataset_annot.name}"
#      row_txt = `#{@cmd}`
#      @row = (row_txt.match(/^\{/)) ? JSON.parse(row_txt)['row'] : nil
   #   @res = []
   #   cur_i = 0
      @res = `#{@cmd}`.split("\n").map{|l| l.split(",")}.select{|e| e.size == 10}
     #  @h_results = Basic.safe_parse_json(@json_str, {})
    #  row Basic.safe_parse_json(row_txt, {})
      h_sum_names = {:sum => "/row_attrs/_Sum", :depth => "/col_attrs/_Depth"}
      h_nber_bins = {
        :sum => (@annot.nber_rows >10000) ? 1000 : 100, #((@annot.nber_rows >999) ? @annot.nber_rows/10 : @annot.nber_rows),
        :depth => (@annot.nber_cols >10000) ? 1000 : 100 #((@annot.nber_cols > 999) ? @annot.nber_cols/10 : @annot.nber_cols)
      }
      
      h_sum_names.each_key do |k|
        cmd = "java -jar #{APP_CONFIG[:local_asap_run_dir]}/ASAP.jar -T ExtractMetadata -names -loom #{@project_dir + @annot.filepath} -type 'NUMERIC' -meta \"#{h_sum_names[k]}\""
        res = Basic.safe_parse_json(`#{cmd}`, {})
        @h_sums[k] = {:cmd => cmd}
        @h_sums[k] = compute_bins(res['values'], h_nber_bins[k].to_i) if res.keys.size > 0
      end
      #      @h_sums[:gene] = 
    else
      @cmd = "java -jar #{APP_CONFIG[:local_asap_run_dir]}/ASAP.jar -T ExtractMetadata " + ((dt = @annot.data_type and dt.name) ? "-type #{dt.name}" : "") + " -names -loom #{@project_dir + @annot.filepath} -meta \"#{@annot.name}\""
      @json_str = `#{@cmd}`
      #      if @annot.dim == 4
      #        @json_str.gsub!(/\\\\/, "\\")
      #      end
      @h_results = Basic.safe_parse_json(@json_str, {})
      # @h_results['values'] = @h_results['values'].map{|e| (e == '') ? "Empty" : e.to_s}
      
      nber_cols = ((@annot.dim == 1) ? @annot.nber_rows : @annot.nber_cols) 
     
      if nber_cols == 1
        
        @h_counts = {}
        @bin_counts = []
        if @annot.data_type_id == 3
          @h_results['values'].each do |e|
            e = (e=='') ? 'Empty' : e 
            @h_counts[e]||=0
            @h_counts[e]+=1
          end
        elsif @annot.data_type_id == 1
          h_res_bins = compute_bins(@h_results['values'], 100)
          @bin_size = h_res_bins[:bin_size]
          @min = h_res_bins[:min]
          @bin_counts = h_res_bins[:bin_counts]
          #          @min = @h_results['values'].min #.map{|e| e.to_f}.min
          #          max = @h_results['values'].max #.map{|e| e.to_f}.max
          #          nber_bins = 100
          #          (0 .. nber_bins-1).map{|bin_i| @bin_counts[bin_i] = 0}       
          #          @bin_size = (max-@min).to_f / nber_bins 
          #          #          if  !(@min.is_a?(Float) && @min.nan?) and !(@bin_size.is_a?(Float) && @bin_size.nan?)
          #            @h_results['values'].each do |e| #.map{|e| e.to_f}.each do |e|
          #              logger.debug("MIN: " + @min.to_json + " BIN_SIZE: " + @bin_size.to_json + " VAL: " + e.to_json)
          #            #   if !(e.is_a?(Float) && e.nan? and @bin_size > 0)
          #            if @bin_size > 0
          #              bin_i = ((e- @min)/@bin_size).to_i
          #              bin_i = nber_bins-1 if bin_i == nber_bins
          #              #     @log = "#{bin_i} -> #{e} / min = #{@min} / max = #{max} / bin_size = #{@bin_size}" if !@bin_counts[bin_i]
          #              @bin_counts[bin_i]||= 0
          #              @bin_counts[bin_i] += 1 
          #            end
          #            #           end
          #          end
        end
        #      if @h_results['values'] and @annot.dim < 4
        #        ### get the list of genes or cells
        #        name = (@annot.dim == 2) ? '/row_attrs/Gene' : 'col_attrs/CellID'
        #        cmd = "java -jar #{APP_CONFIG[:local_asap_run_dir]}/ASAP.jar -T ExtractMetadata -prec 2 -names -loom #{@project_dir + @annot.filepath} #-meta #{name}"
        #        key = (@annot.dim == 2) ? 'genes' : 'cells'
        #        @h_results[key] = Basic.safe_parse_json(`#{cmd}`, {})['values']
        #      end 
      end
    end


    if !readable? @project
      render :text => 'Not authorized'
    end
    render :layout => false
  end

  # GET /annots/new
  def new
    @annot = Annot.new
  end

  # GET /annots/1/edit
  def edit
    @h_steps = {}
    @h_steps_by_name = {}
    @h_statuses = {}
    @project = @annot.project
    Step.where(:docker_image_id => @asap_docker_image.id).all.map{|s| @h_steps[s.id]=s; @h_steps_by_name[s.name]=s}
    Status.all.map{|s| @h_statuses[s.id]=s}

    @step = @h_steps_by_name['metadata_expr']
    @annot_step = @run.step
    @h_attrs = Basic.safe_parse_json(@annot_step.attrs_json, {})
    @h_dashboard_card = {}
    @h_dashboard_card[@run.step_id] = JSON.parse(@h_steps[@run.step_id].dashboard_card_json)

    render :layout => false
    
  end

  # POST /annots
  # POST /annots.json
  def create
    @annot = Annot.new(annot_params)

    respond_to do |format|
      if editable?(@project) and @annot.save
        format.html { redirect_to @annot, notice: 'Annot was successfully created.' }
        format.json { render :show, status: :created, location: @annot }
      else
        format.html { render :new }
        format.json { render json: @annot.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /annots/1
  # PATCH/PUT /annots/1.json
  def update
    respond_to do |format|
      if editable?(@project) #and @annot.update(annot_params)

        h_data_types = {}
        DataType.all.map{|dt| h_data_types[dt.name] = dt; h_data_types[dt.id] = dt}
        h_data_classes = {}
        DataClass.all.map{|dc| h_data_classes[dc.name] = dc; h_data_classes[dc.id] = dc}

        if annot_params[:data_type_id] != @annot.data_type_id
          #need to reset this parameter
          annot_params[:data_class_ids] = ''
        end

        h_annot = {}
        if annot_params[:data_type_id]
          h_annot = {
            :data_type_id => annot_params[:data_type_id].to_i,
            :data_class_ids => annot_params[:data_class_ids]
          }
        elsif annot_params[:sim_step_id]
           h_annot = {:sim_step_id => annot_params[:sim_step_id]}
        end
        
        # change ori_annot (equivalent annot attached to the main dataset)
        ori_annot = Annot.where(:project_id => @project.id, :name => @annot.name).order("id asc").first
        #puts annot_params.to_json
        ori_annot.update(h_annot)
        
        # change all annots, starting with ori_annot, and then propagating to others
        # run = ori_annot.run
        #        relative_filepath = ori_annot.filepath #relative_path(@project, ori_annot.filepath)
        
        all_annots =  Annot.where(:project_id => @project.id, :name => @annot.name).order("id asc").all
        all_annots.each do |annot|
          meta = {
            "name" => annot.name,
            "forced_type_id" => h_annot[:data_type_id]
          }
          Basic.load_annot( annot.run, meta, annot.filepath, h_data_types, h_data_classes, logger)
        end

        format.html { 
          render :partial => 'update', notice: 'Annot was successfully updated.'
          #redirect_to @annot, layout: false, notice: 'Annot was successfully updated.' 
        }
        format.json { render :show, status: :ok, location: @annot }
      else
        format.html { render :edit }
        format.json { render json: @annot.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /annots/1
  # DELETE /annots/1.json
  def destroy
    if editable?(@project)        
      @annot.clas.destroy_all
      @annot.destroy
      respond_to do |format|
        format.html { redirect_to annots_url, notice: 'Annot was successfully destroyed.' }
        format.json { head :no_content }
      end
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_annot
      @annot = Annot.find(params[:id])      
      @run = @annot.run
      @project = @annot.project
      @project_type = @project.project_type
      @version =@project.version
      @h_env = Basic.safe_parse_json(@version.env_json, {})
      @list_docker_image_names = @h_env['docker_images'].keys.map{|k| @h_env['docker_images'][k]["name"] + ":" + @h_env['docker_images'][k]["tag"]}
      @docker_images = DockerImage.where("full_name in (#{@list_docker_image_names.map{|e| "'#{e}'"}.join(",")})").all
      @asap_docker_image = @docker_images.select{|e| e.name == APP_CONFIG[:asap_docker_name]}.first
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def annot_params
      params.fetch(:annot, {})
    end
end
