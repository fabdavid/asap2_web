class GeneSetItemsController < ApplicationController
  before_action :set_gene_set_item, only: [:show, :edit, :update, :destroy]

  def get_version
    @version = Version.where(:id => params[:version_id]).first
    @h_env = (@version) ? Basic.safe_parse_json(@version.env_json, {}) : {"bla" => "test"}
  end
  

  def search
 
    get_version()
    # @h_ge_run_attrs = {}
    h_stable_ids = {}
    @h_all_genes = {}
    @h_enriched_genes = {}
   
    if params[:ge_run_id] and params[:type]
      ge_run = Run.where(:id => params[:ge_run_id]).first
      if ge_run
        project = ge_run.project
        
        project_dir = Pathname.new(APP_CONFIG[:user_data_dir]) + project.user_id.to_s + project.key
        h_ge_run_attrs = Basic.safe_parse_json(ge_run.attrs_json, {})
        if h_ge_run_attrs['input_de'] and h_ge_run_attrs['input_de']['run_id']
          de_run = Run.where(:id => h_ge_run_attrs['input_de']['run_id']).first 
          all_genes = File.readlines(project_dir + 'de' + de_run.id.to_s + "output.txt")
          all_genes.map{|e| t = e.split("\t"); @h_all_genes[t[1]] = 1; h_stable_ids[t[0]] = t[1]}
          filename = "#{ge_run.user_id}_#{h_ge_run_attrs['input_de']['run_id']}_#{h_ge_run_attrs['fc_cutoff']}_#{h_ge_run_attrs['fdr_cutoff']}_filtered_ids.json"
          puts "looking_for: " + filename
          if File.exist? project_dir + 'tmp' + filename
            filtered_json = File.read(project_dir + 'tmp' + filename)
            h_filtered = Basic.safe_parse_json(filtered_json, {})
            @h_enriched_genes = {}
            h_filtered[params[:type]].each do |gid|
              @h_enriched_genes[h_stable_ids[gid.to_s]] = 1
            end
          end
        end
      end
    end
    @project = Project.where(:key => params[:project_key]).first
    @log = "gene_set_id = #{params[:gene_set_id]} and identifier = '#{params[:name]}'"
    @gsi = Basic.sql_query2(:asap_data, @h_env['asap_data_db_version'], 'gene_set_items', '', '*', "gene_set_id = #{params[:gene_set_id]} and identifier = '#{params[:identifier]}'").first
    if @gsi
      @genes =  Basic.sql_query2(:asap_data, @h_env['asap_data_db_version'], 'genes', '', '*', "id IN (#{@gsi.content})")
    end
    #    res.each do |gs|                                                                                                                                                                                    
#      @h_gene_set_items[gsi.name] = gsi                                                                                                                                                                 
#    end                  
#    ConnectionSwitch.with_db(:data_with_version, @h_env['asap_data_db_version']) do
#      @gsi = GeneSetItem.where(:gene_set_id => params[:gene_set_id], :name => params[:name]).first
#      # @gene = nil                                                                                                                                                                                    #  
#    end
    render :partial => "search"
    
  end

  # GET /gene_set_items
  # GET /gene_set_items.json
  def index
    @gene_set_items = GeneSetItem.all
  end

  # GET /gene_set_items/1
  # GET /gene_set_items/1.json
  def show
  end

  # GET /gene_set_items/new
  def new
    @gene_set_item = GeneSetItem.new
  end

  # GET /gene_set_items/1/edit
  def edit
  end

  # POST /gene_set_items
  # POST /gene_set_items.json
  def create
    @gene_set_item = GeneSetItem.new(gene_set_item_params)

    respond_to do |format|
      if @gene_set_item.save
        format.html { redirect_to @gene_set_item, notice: 'Gene set item was successfully created.' }
        format.json { render :show, status: :created, location: @gene_set_item }
      else
        format.html { render :new }
        format.json { render json: @gene_set_item.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /gene_set_items/1
  # PATCH/PUT /gene_set_items/1.json
  def update
    respond_to do |format|
      if @gene_set_item.update(gene_set_item_params)
        format.html { redirect_to @gene_set_item, notice: 'Gene set item was successfully updated.' }
        format.json { render :show, status: :ok, location: @gene_set_item }
      else
        format.html { render :edit }
        format.json { render json: @gene_set_item.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /gene_set_items/1
  # DELETE /gene_set_items/1.json
  def destroy
    @gene_set_item.destroy
    respond_to do |format|
      format.html { redirect_to gene_set_items_url, notice: 'Gene set item was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_gene_set_item
      @gene_set_item = GeneSetItem.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def gene_set_item_params
      params.fetch(:gene_set_item, {})
    end
end
