class GenesController < ApplicationController
  before_action :set_gene, only: [:show, :edit, :update, :destroy]

  def get_version
    @version = Version.where(:id => params[:version_id]).first
    @h_env = (@version) ? Basic.safe_parse_json(@version.env_json, {}) : {"bla" => "test"}
  end

  def check
    to_render = []
    final_list=[]
    db_version = params[:db_version]
    h_genes = nil
    gene_names = []
#    ConnectionSwitch.with_db(:data_with_version, db_version) do
    gene_names = Basic.sql_query2(:asap_data, db_version, 'gene_names', '', 'gene_id, value', "organism_id = #{params[:organism_id]} and lower(value) = '#{params[:term].downcase}'")
   
    #      gene_names = GeneName.select("gene_id, value").where("organism_id = ? and lower(value) = ?", params[:organism_id], params[:term].downcase).all
    h_gene_names = {}
    h_all_gene_names = {}
    gene_names.each do |gn|
      h_all_gene_names[gn.value.downcase]=1
    end
    final_list = Gene.select("id, name, ensembl_id, alt_names").where(:id => gene_names.map{|e| e.gene_id}.uniq)# | Gene.where(:id => gene_names[1].map{|e| e.gene_id}.uniq)    
    
    to_render = final_list.to_a.select{|e| !h_genes or (h_genes[e.ensembl_id.downcase] or h_genes[e.name.downcase])}.first(20).map{|e| {:id => e.id, :label => "#{e.ensembl_id} #{e.name}" + ((e.alt_names.size > 0) ? " [" + e.alt_names.split(",").join(", ") + "]" : '')}}
    #  end
    render :json => to_render.to_json
  end
  
  def autocomplete
    to_render = []
    final_list=[]
    db_version = params[:db_version]
    h_genes = nil
    if params[:project_key]
      project = Project.find_by_key(params[:project_key])
      version = project.version
      h_env =  Basic.safe_parse_json(version.env_json, {}) 
      db_version = h_env['asap_data_db_version']
      data_dir = Pathname.new(APP_CONFIG[:user_data_dir]) + project.user_id.to_s + project.key
      filename = data_dir + 'parsing' + "gene_names.json"
      
      gene_list = JSON.parse(File.read(filename)).flatten
      h_genes = {}
      
      gene_list.each do |identifier|
        identifier.split(",").each do |tmp|
          h_genes[tmp.downcase]=1
        end
      end
    end
    gene_names = []
    # ConnectionSwitch.with_db(:data_with_version, db_version) do
    # gene_names = GeneName.select("gene_id, value").where("organism_id = ? and lower(value) ~ ?", params[:organism_id], ("^" + params[:term].downcase)).all
   # gene_names = Basic.sql_query2(:asap_data, db_version, 'gene_names', '', 'gene_id, value', "organism_id = #{params[:organism_id]} and lower(value) = '#{params[:term].downcase}'")
    
    gene_names = Basic.sql_query2(:asap_data, db_version, 'gene_names', '', 'gene_id, value', "organism_id = #{params[:organism_id]} and lower(value) ~ '^#{params[:term].downcase}'")
    
    h_gene_names = {}
    h_all_gene_names = {}
    gene_names.each do |gn|
      h_all_gene_names[gn.value.downcase]=1
    end
    final_list = Gene.select("id, name, ensembl_id, alt_names").where(:id => gene_names.map{|e| e.gene_id}.uniq).order(:name)# | Gene.where(:id => gene_names[1].map{|e| e.gene_id}.uniq)                                                   
    
    to_render = final_list.to_a.select{|e| !h_genes or (h_genes[e.ensembl_id.downcase] or h_genes[e.name.downcase])}.first(50).map{|e| {:id => e.id, :label => "#{e.ensembl_id} #{e.name}" + ((e.alt_names.size > 0) ? " [" + e.alt_names.split(",").join(", ") + "]" : '')}}
    # end
    render :json => to_render.to_json
  end
  

  # GET /genes
  # GET /genes.json
  def index
    h_cond={}
    h_cond[:organism_id] = params[:organism_id] if params[:organism_id]
    
    @genes = Gene.select("id, name").where(h_cond).all
    output = []
    @genes.each do |g|
      h = {:name => g.name}
      output.push h 
    end
    respond_to do |format|
      format.html {render :nothing}
      format.json {render :json => output.to_json}
    end
  end

  def search
    
    get_version()
    ConnectionSwitch.with_db(:data_with_version, @h_env['asap_data_db_version']) do
      if params[:ensembl_id]
        @gene = Gene.where(:ensembl_id => params[:ensembl_id]).first
      elsif params[:gene_id]
        @gene =  Gene.where(:id => params[:gene_id]).first
      end
        # @gene = nil
    end
    render :partial => "search"

  end

  # GET /genes/1
  # GET /genes/1.json
  def show

    if params[:no_layout] == '1'
      render :partial => 'show'
    else
      render 
    end
  end

  # GET /genes/new
  def new
    @gene = Gene.new
  end

  # GET /genes/1/edit
  def edit
  end

  # POST /genes
  # POST /genes.json
  def create
    @gene = Gene.new(gene_params)

    respond_to do |format|
      if admin? and @gene.save
        format.html { redirect_to @gene, notice: 'Gene was successfully created.' }
        format.json { render :show, status: :created, location: @gene }
      else
        format.html { render :new }
        format.json { render json: @gene.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /genes/1
  # PATCH/PUT /genes/1.json
  def update
    respond_to do |format|
      if admin? and @gene.update(gene_params)
        format.html { redirect_to @gene, notice: 'Gene was successfully updated.' }
        format.json { render :show, status: :ok, location: @gene }
      else
        format.html { render :edit }
        format.json { render json: @gene.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /genes/1
  # DELETE /genes/1.json
  def destroy
    if admin?
      @gene.destroy
      respond_to do |format|
        format.html { redirect_to genes_url, notice: 'Gene was successfully destroyed.' }
        format.json { head :no_content }
      end
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_gene
      @gene = Gene.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def gene_params
      params.fetch(:gene, {})
    end
end
