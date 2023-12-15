class ClasController < ApplicationController
  before_action :set_cla, only: [:show, :edit, :update, :destroy, :vote]

  # GET /clas
  # GET /clas.json
  def index
    if params[:annot_id] and params[:cat_i]
      @annot = Annot.where(:id => params[:annot_id]).first
      @cat_i = params[:cat_i]
      @annot_cell_set = AnnotCellSet.where(:annot_id => params[:annot_id], :cat_idx => params[:cat_i].to_i).first
      @cell_set = CellSet.where(:id => @annot_cell_set.cell_set_id).first
      @project = @annot.project
      @version = @project.version
      @h_env = Basic.safe_parse_json(@version.env_json, {})
      # @cell_set = CellSet.where(:id => @annot).first
      @all_clas = Cla.where(#:project_id => @project.id, 
                            :cell_set_id => @cell_set.id #@annot_cell_set.cell_set_id
                            #:annot_id => params[:annot_id], :cat_idx => params[:cat_idx].to_i
                            ).all
      @h_cla_sources = {}
      ClaSource.all.map{|e| @h_cla_sources[e.id] = e}
      
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
      
      render :partial => 'index'
    else
      @clas = Cla.all
      render
    end
  end

  # GET /clas/1
  # GET /clas/1.json
  def show
  end

  # GET /clas/new
  def new
    @project = Project.where(:key => @project.key).first
    @organism = @project.organism
    @cla = Cla.new
  end

  # GET /clas/1/edit
  def edit
  end


  def vote

    if current_user

      orcid_user = current_user.orcid_user
      all_clas = Cla.where(:annot_id => @cla.annot_id, :cat => @cla.cat).all
      
      @cla_vote = ClaVote.where(:cla_id => @cla.id, :user_id => current_user.id).first
      
      h_vote = {
        :cla_id => @cla.id,
        :cla_source_id => 1,
        :agree => (params[:type] == '1') ? true : false,
        :user_id => current_user.id,
        :user_name => current_user.displayed_name,
        :orcid_user_id => (orcid_user) ? orcid_user.id : nil
      }

      logger.debug("add_cla_vote")
      if params[:type2] == 'add'
        logger.debug("add cla vote")
        if @cla_vote
          @cla_vote.update_attributes(h_vote)
        else
          @cla_vote = ClaVote.new(h_vote)
          @cla_vote.save
        end
      elsif params[:type2] == 'del' and @cla_vote and  (@cla_vote.user_id != @cla.user_id or admin?)
        #        @cla_vote = ClaVote.where({:cla_id =>}).first
        @cla_vote.destroy
      end

      votes = @cla.cla_votes

      h_cla = {
        :nber_agree => votes.select{|v| v.agree == true}.size,
        :nber_disagree => votes.select{|v| v.agree == false}.size
      }

      @cla.update_attributes(h_cla)
    
      render :partial => 'vote', :locals => {:cla_vote => @cla_vote}
  
    else
      render :nothing => true
    end
    
  end


  # POST /clas
  # POST /clas.json
  def create
    @cla = Cla.new(cla_params)
    
    if params[:cla][:annot_id]

      orcid_user = (current_user) ? current_user.orcid_user : nil
            
      #complement attributes
      @annot = Annot.where(:id => params[:cla][:annot_id]).first
      list_cats = Basic.safe_parse_json(@annot.list_cat_json, [])
      @cat_idx = list_cats.index(@cla.cat)

      if @annot
        @cla.project_id = @annot.project_id
        @project = @annot.project
        @version =@project.version
        @h_env = Basic.safe_parse_json(@version.env_json, {})
        @annot_cell_set = AnnotCellSet.where(:annot_id => @annot.id, :cat_idx => @cat_idx).first
        @cell_set = CellSet.where(:id => @annot_cell_set.cell_set_id).first
        @all_annot_cell_sets = AnnotCellSet.where(:annot_id => @annot.id).all        
      end
      @cla.user_id = (current_user) ? current_user.id : nil
      @cla.orcid_user_id = (ou = current_user.orcid_user) ? ou.id : nil
      @cla.cla_source_id = 1
      
      tmp_gene_ids = []
      if @h_env
        #    tmp_gene_ids = Basic.@cla.genes.split(",").map{|e| e.}
        tmp_gene_ids = Basic.sql_query2(:asap_data, @h_env['asap_data_db_version'], 'genes', '', 'id', "organism_id = #{@project.organism_id} and ensembl_id in (#{@cla.up_gene_ids.split(",").map{|e| "'#{e}'"}.join(",")})")
      end
      @cla.up_gene_ids = tmp_gene_ids.map{|g| g.id}.uniq.join(",")
      
      tmp_gene_ids = []
      if @h_env
        #    tmp_gene_ids = Basic.@cla.genes.split(",").map{|e| e.}                                                                                               
        tmp_gene_ids = Basic.sql_query2(:asap_data, @h_env['asap_data_db_version'], 'genes', '', 'id', "organism_id = #{@project.organism_id} and ensembl_id in (#{@cla.down_gene_ids.split(",").map{|e| "'#{e}'"}.join(",")})")
      end
      @cla.down_gene_ids = tmp_gene_ids.map{|g| g.id}.uniq.join(",")

      ## reorder ids
      up_gene_ids =  (@cla.up_gene_ids) ? @cla.up_gene_ids.split(",") : []
      down_gene_ids =  (@cla.down_gene_ids) ? @cla.down_gene_ids.split(",") : []
      sorted_up_gene_ids = (@cla.up_gene_ids) ? @cla.up_gene_ids.split(",").sort : []
      sorted_down_gene_ids = (@cla.down_gene_ids) ? @cla.down_gene_ids.split(",").sort : []
      
      h_gene_ids = {}
      gene_ids = up_gene_ids | down_gene_ids
      gene_ids.map{|e| h_gene_ids[e] = 1}

      cot_ids = (@cla.cell_ontology_term_ids) ? @cla.cell_ontology_term_ids.split(",") : []
      sorted_cot_ids = (@cla.cell_ontology_term_ids) ? @cla.cell_ontology_term_ids.split(",").sort : []
     
      h_cot_ids = {}
      cot_ids.map{|e| h_cot_ids[e] = 1}
      
      @cla.cell_ontology_term_ids = (cot_ids.size > 0) ? cot_ids.join(",") : ""
      @cla.sorted_cell_ontology_term_ids = (sorted_cot_ids.size > 0) ? sorted_cot_ids.join(",") : ""
      @cla.up_gene_ids = (up_gene_ids.size > 0) ? up_gene_ids.join(",") : ""
      @cla.down_gene_ids = (down_gene_ids.size > 0) ? down_gene_ids.join(",") : ""
      @cla.sorted_up_gene_ids = (sorted_up_gene_ids.size > 0) ? sorted_up_gene_ids.join(",") : ""
      @cla.sorted_down_gene_ids = (sorted_down_gene_ids.size > 0) ? sorted_down_gene_ids.join(",") : ""

      @cla.cell_set_id = @annot_cell_set.cell_set_id

      @errors = []
      
      #####check if cla already exists
      #h_cla = @cla.attributes
      #h_cla.delete("user_id")
      if  @cla.cell_ontology_term_ids != ''
      h_cla = {
#        :annot_id => @annot.id,
        :cell_set_id => @annot_cell_set.cell_set_id,
        #      :cat => @cla.cat,
        #   :genes => @cla.genes,
        :cell_ontology_term_ids => @cla.cell_ontology_term_ids
      }
      existing_cla = Cla.where(h_cla).first
      
      if existing_cla 
        @errors.push("Annotation ##{existing_cla.num} in group " + existing_cla.cat + " has the same ontology terms.")
      end

      end
      #  if !existing_cla
      if  @cla.name != ''
      h_cla = {
#        :annot_id => @annot.id,
        :cell_set_id => @annot_cell_set.cell_set_id,
        #       :cat => @cla.cat,
        :name => @cla.name,
        :cell_ontology_term_ids => ["", nil]
      }
      existing_cla = Cla.where(h_cla).first
      if existing_cla
        @errors.push("Annotation ##{existing_cla.num} in group " + existing_cla.cat + " has the same name.")
      end
      end
      # end
      
      # if ! existing_cla and !["", nil].include? @cla.genes
      if @cla.up_gene_ids != '' or  @cla.down_gene_ids != ''
        h_cla = {
#          :annot_id => @annot.id,
          :cell_set_id => @annot_cell_set.cell_set_id,
          #        :cat => @cla.cat,
          :sorted_up_gene_ids => @cla.sorted_up_gene_ids,
          :sorted_down_gene_ids => @cla.sorted_down_gene_ids
        }
        existing_cla = Cla.where(h_cla).first
        if existing_cla
          @errors.push("Annotation ##{existing_cla.num} in group " + existing_cla.cat + " has the same gene lists (up and down).")
        end
      end
      # end
      
      h_clas = {
        :by_cot_id => {},
        :by_gene_id => {}
      }
      all_clas = Cla.where(
                           :cell_set_id => @cell_set.id #@all_annot_cell_sets.map{|e| e.cell_set_id}
                           #:annot_id => @annot.id, :cat => @cla.cat
                           ).all
      @cla.num = (all_clas.size > 0) ? (all_clas.map{|e| e.num}.sort.last+1) : 1
      
      @h_all_clas = {}
      all_clas.each do |cla|
        @h_all_clas[cla.id] = cla
        #      tmp_up_gene_ids = (cla.up_gene_ids) ? cla.up_gene_ids.split(",") : []
        #      tmp_cot_ids = (cla.cell_ontology_term_ids) ? cla.cell_ontology_term_ids.split(",") : []
        #      tmp_up_gene_ids.map{|e| h_clas[:by_gene_id][e] ||= []; h_clas[:by_gene_id][e].push cla.id}
        #      tmp_cot_ids.map{|e| h_clas[:by_cot_id][e] ||= []; h_clas[:by_cot_id][e].push cla.id}       
      end
      
      @approaching_clas = {:cot_ids => [], :up_gene_ids => [], :down_gene_ids => []}
      @max_common = {:up_gene_ids => 0, :down_gene_ids => 0, :cot_ids => 0}
      if @errors.size == 0
        all_clas.each do |cla|
          if cla.sorted_up_gene_ids != @cla.sorted_up_gene_ids
            tmp_gene_ids = (cla.up_gene_ids and cla.up_gene_ids != '') ? cla.up_gene_ids.split(",") : []
            nber_common_gene_ids = (tmp_gene_ids.size >0) ? tmp_gene_ids.map{|e| h_gene_ids[e] || 0}.sum : 0
            if nber_common_gene_ids > @max_common[:up_gene_ids]
              @max_common[:up_gene_ids] = nber_common_gene_ids
              @approaching_clas[:up_gene_ids] = [cla.id]
            elsif nber_common_gene_ids == @max_common[:up_gene_ids]
              @approaching_clas[:up_gene_ids].push cla.id
            end
          end
          if cla.sorted_down_gene_ids != @cla.sorted_down_gene_ids
            tmp_gene_ids = (cla.down_gene_ids and cla.down_gene_ids != '') ? cla.down_gene_ids.split(",") : []
            nber_common_gene_ids = (tmp_gene_ids.size >0) ? tmp_gene_ids.map{|e| h_gene_ids[e] || 0}.sum : 0
            if nber_common_gene_ids > @max_common[:down_gene_ids]
              @max_common[:down_gene_ids] = nber_common_gene_ids
              @approaching_clas[:down_gene_ids] = [cla.id]
            elsif nber_common_gene_ids == @max_common[:down_gene_ids]
              @approaching_clas[:down_gene_ids].push cla.id
            end
          end
          
          if cla.sorted_cell_ontology_term_ids != @cla.sorted_cell_ontology_term_ids
            tmp_cot_ids = (cla.cell_ontology_term_ids and cla.cell_ontology_term_ids != '') ?  cla.cell_ontology_term_ids.split(",") : []
            nber_common_cots = (tmp_cot_ids.size  > 0) ? tmp_cot_ids.map{|e| h_cot_ids[e] || 0}.sum : 0
            if nber_common_cots > @max_common[:cot_ids]
              @max_common[:cot_ids] = nber_common_cots
              @approaching_clas[:cot_ids] = [cla.id]
            elsif nber_common_cots == @max_common[:cot_ids]
              @approaching_clas[:cot_ids].push cla.id
            end
          end
        end
      end
      
      @approaching_clas.each_key do |k|
        @approaching_clas[k].uniq!
      end
      
      #      @cla.user_name = current_user.displayed_name
      @cla.user_id = (current_user) ? current_user.id : nil
      @cla.orcid_user_id = (orcid_user) ? orcid_user.id : nil
      
      respond_to do |format|
        if ((@max_common[:down_gene_ids] == 0 and @max_common[:up_gene_ids] == 0  and @max_common[:cot_ids] == 0) or params[:confirm] == '1') and @errors.size == 0 and @annot and @cla.save        

          ## add vote
          cla_vote = ClaVote.where(:cla_id => @cla.id, :user_id => current_user.id).first
                   
          h_vote = {
            :cla_id => @cla.id,
            :cla_source_id => 1,
            :agree => true,
            :user_id => (current_user) ? current_user.id : nil,
            :user_name => current_user.displayed_name,
            :orcid_user_id => (orcid_user) ? orcid_user.id : nil
          }
          
          logger.debug("add_cla_vote")
          if cla_vote
            cla_vote.update_attributes(h_vote)
          else
            cla_vote = ClaVote.new(h_vote)
            cla_vote.save
          end

          @cla.update_attributes({:nber_agree => 1})
          
          ## init h_cat_info
          h_cat_info = Basic.safe_parse_json(@annot.cat_info_json, {})

          if !h_cat_info["nber_clas"]
            h_cat_info = {"nber_clas" => [], "selected_cla_ids" => []}
            list_cats.each_index do |cat_i|
              h_cat_info["nber_clas"][cat_i] = 0
              h_cat_info["selected_cla_ids"][cat_i] = ""
            end
            h_cat_info["nber_clas"][@cat_idx] = all_clas.size + 1
          end
          
          all_clas = Cla.where(:cell_set_id => @cla.cell_set_id
                               #:annot_id => @annot.id, :cat => @cla.cat
                               ).all
          selected_cla = all_clas.sort{|a, b| a.nber_agree - a.nber_disagree <=> b.nber_agree - b.nber_disagree}.last
          
          h_cat_info["selected_cla_ids"][@cat_idx] = selected_cla.id if selected_cla
          @annot.update_attributes({:cat_info_json => h_cat_info.to_json})

          ## replaced by cell_set associated info
          @cell_set.update_attributes({:nber_clas => all_clas.size, :cla_id => selected_cla.id})
          
          #        format.html { redirect_to @cla, notice: 'Cla was successfully created.' }
          format.html{ render :partial => 'create'}
          format.json { render :show, status: :created, location: @cla }
        else
          format.html { render :partial => 'create_error_or_warning' }
          format.json { render json: @cla.errors, status: :unprocessable_entity }
        end
      end
    end
  end

  # PATCH/PUT /clas/1
  # PATCH/PUT /clas/1.json
  def update
    respond_to do |format|
      if @cla.update(cla_params)
        format.html { redirect_to @cla, notice: 'Cla was successfully updated.' }
        format.json { render :show, status: :ok, location: @cla }
      else
        format.html { render :edit }
        format.json { render json: @cla.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /clas/1
  # DELETE /clas/1.json
  def destroy
#    cat_idx = @cla.cat_
    cla_votes = @cla.cla_votes
    if cla_votes.size == 0 or cla_votes.size == 1 and (admin? or (current_user and cla_votes.first.user_id == current_user.id))
      cla_votes.destroy_all
    end
    @cla.destroy
    
    all_clas = Cla.where(:cell_set_id => @cell_set.id
                         #:annot_id => @annot.id, :cat => @cla.cat                                                                                                                                                 
                         ).all
    selected_cla = all_clas.sort{|a, b| a.nber_agree - a.nber_disagree <=> b.nber_agree - b.nber_disagree}.last
    
    # h_cat_info["selected_cla_ids"][cat_idx] = selected_cla.id if selected_cla
    #    @annot.update_attributes({:cat_info_json => h_cat_info.to_json})
    
    ## replaced by cell_set associated info                                                                                                                                                                        
    @cell_set.update_attributes({:nber_clas => all_clas.size, :cla_id => selected_cla.id})
    
    respond_to do |format|
      format.html { 
        render :partial => 'destroy'
        #redirect_to clas_url, notice: 'Cla was successfully destroyed.' 
      }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_cla
      @cla = Cla.find(params[:id])
      @annot = Annot.where(:id => @cla.annot_id).first
      @annot_cell_set = AnnotCellSet.where(:annot_id => @annot.id, :cat_idx => @cla.cat_idx).first
      @cell_set = CellSet.where(:id => @annot_cell_set.cell_set_id).first
      @project = @annot.project if @annot
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def cla_params
      params.fetch(:cla).permit(:name, :comment, :clone_id, :annot_id, :cell_ontology_term_ids, :up_gene_ids, :down_gene_ids, :cat, :cat_idx)
    end
end
