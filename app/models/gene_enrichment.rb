class GeneEnrichment < ApplicationRecord

  belongs_to :project
  belongs_to :diff_expr
  belongs_to :speed
  belongs_to :status
  belongs_to :job
  belongs_to :user

  NewGeneEnrichment = Struct.new(:gene_enrichment) do
    def perform
      gene_enrichment.run
    end

    def error(job, exception)
      if job.last_error
        lines = job.last_error.split("\n")
        lines = lines.join("\\n")
        project_step = ProjectStep.where(:project_id => project.id, :step_id => 7).first
        project_step.update_attributes(:error_message => lines, :status_id => 4)
        gene_enrichment.update_attributes(:status_id => 4)
      end
    end
  end

  def run
    require 'basic.rb'
    
    project = self.project
    project_dir =  Pathname.new(APP_CONFIG[:user_data_dir]) + project.user_id.to_s + project.key
    gene_enrichment_dir = project_dir + 'gene_enrichment'
    Dir.mkdir gene_enrichment_dir if !File.exist?(gene_enrichment_dir)
    gene_enrichment_dir += self.id.to_s
    Dir.mkdir gene_enrichment_dir if !File.exist?(gene_enrichment_dir)

    h_parameters = JSON.parse(self.attrs_json)

    diff_expr = self.diff_expr

    diff_expr_dir = project_dir + 'de' + diff_expr.id.to_s
    list_input = []
    types = ['up', 'down']
    types.each do |t|
      if [t, 'both'].include?(h_parameters['type_best_hits'])
        logger.debug("TEST_DE FILE: " + (diff_expr_dir + "output.#{t}_filtered.json").to_s) #if File.exist?(diff_expr_dir + "output.#{t}.json")
        data = File.read(diff_expr_dir + "output.#{t}_filtered.json")
        if data
          h_data = JSON.parse(data)          
          h_data['text'].each_index do |i|
            e = h_data['text'][i]
            tab = e.split("|")
            tab[1] ||= ''
            tab[2] ||= ''
            list_input.push(tab)
            break if i == h_parameters['nber_best_hits'].to_i-1
          end
        end
      end
    end
    
    h_tmp = {
      'original' => 'parsing',
      'filtered' => 'filtering',
      'normalized' => 'normalization'
    }
    h_de_attrs = JSON.parse(diff_expr.attrs_json) 
    normalization_file = project_dir + h_tmp[h_de_attrs['typefile']] + 'dl_output.tab'

    ## database
    database_filepath= Pathname.new("/data/asap/Genesets/")
    #    /data/asap/Genesets/Cancer_Cell_Line_Encyclopedia.gmt  /data/asap/Genesets/gene_atlas.mmu.gmt  /data/asap/Genesets/GO_CC_hsa.gmt  /data/asap/Genesets/GO_MF_mmu.gmt  /data/asap/Genesets/kegg.mmu.gmt
    #/data/asap/Genesets/drugbank.gmt                       /data/asap/Genesets/GO_BP_hsa.gmt       /data/asap/Genesets/GO_CC_mmu.gmt  /data/asap/Genesets/gsea.c2.gmt    /data/asap/Genesets/MSigDB_Oncogenic_Signatures.gmt
    #/data/asap/Genesets/gene_atlas.hsa.gmt                 /data/asap/Genesets/GO_BP_mmu.gmt       /data/asap/Genesets/GO_MF_hsa.gmt  /data/asap/Genesets/kegg.hsa.gmt   /data/asap/Genesets/NCI-60_Cancer_Cell_Lines.gmt

    organism = project.organism
    
    
    #    tmp_db_filename = h_parameters['db_type']
    #    #    if h_parameters['db_type'].match('^GO_')
    #    tmp_t = organism.name.split(" ").map{|e| e.downcase}
    #    tag = tmp_t[0][0]
    #    tag += tmp_t[1][0,2]
    #    tmp_db_filename += '.' + tag
    #    #    end
    #    tmp_db_filename += '.gmt'
    #    database_filepath += tmp_db_filename
    
    if h_parameters['geneset_type'] == 'custom'
      database_filepath = project_dir + 'gene_sets' + (h_parameters['custom_geneset'] + ".txt")
    elsif h_parameters['geneset_type'] == 'global' ### global gene set                         
      dir = Pathname.new(APP_CONFIG[:data_dir]) + "Genesets"
      gene_set = GeneSet.find(h_parameters['global_geneset'])
      database_filepath = dir + gene_set.original_filename
    end
    
    
    input_filename = gene_enrichment_dir + 'input.json'
    
    File.open(input_filename, 'w') do |f|
      f.write(list_input.to_json)
    end

    h_cmds = {
    }

    start_time = Time.now
    project.update_attributes(:status_id => 2) if project.status_id !=2
    self.update_attributes(:status_id => 2)
    project_step = ProjectStep.where(:project_id => project.id, :step_id => 7).first
    project_step.update_attributes(:status_id => 2) if project_step.status_id !=2

    #    cm = self.gene
    #    list_p = []
    #    list_attrs = JSON.parse(cm.attrs_json)
    #    list_attrs.reject{|e| e['not_in_cmd_line']}.each do |attr|
    #      list_p.push((h_parameters[attr['name']]) ? h_parameters[attr['name']] : attr['default'])
    #    end
    
    #    input_file = ''
    #    if self.dim_reduction_id
    #      dr = DimReduction.where(:id => self.dim_reduction_id).first
    #      input_file = project_dir + 'visualization' + dr.name + 'output.json'
    #    else
    #      step = self.step
    #      input_file = project_dir + step.name + 'output.tab'
    #    end
    ### deal with is_log2                                                                                                                                                                                              
    #     java -jar lib/Enrichment.jar -m fet -o /tmp/test -path /data/asap/Genesets/GO_BP_hsa.gmt -p 1 -test /data/asap/users/3/36niti/parsing/gene_test.json -background /data/asap/users/3/36niti/normalization/dl_output.tab
    max_nber_genes = (h_parameters['geneset_type'] == 'custom') ? 100000 : 500
    min_nber_genes = (h_parameters['geneset_type'] == 'custom') ? 1 : 15
    #    cmd = "java -jar lib/Enrichment.jar -m fet -o #{gene_enrichment_dir} -path #{database_filepath} -p #{h_parameters['p_value']} -max 500 -min 15 -adj #{h_parameters['adj']} -test #{input_filename} -background #{normalization_file}"
    cmd = "java -jar lib/ASAP.jar -T Enrichment -m fet -o #{gene_enrichment_dir} -path #{database_filepath} -p 1 -max #{max_nber_genes} -min #{min_nber_genes} -adj fdr -test #{input_filename} -background #{normalization_file}"
    #    logger.debug("CMD: " + cmd)
    
    #    pid = spawn(cmd)
    #    Basic::create_job(cmd, project)
    #    Process.waitpid(pid)
    
    queue = 1

    output_json = gene_enrichment_dir + "output.json"
    job = Basic.run_job(logger, cmd, project, self, 7, output_json, output_json, queue, self.job_id, self.user)

    ### filter results                                                                                                                                                                               
    cmd = "rails filter_ge_results[#{project.key},#{self.id}] --trace 2>&1 > log/filter_ge_results.log"
    `#{cmd}`
    
    h_res = {}
    
    result_file = project_dir + "gene_enrichment" + self.id.to_s  + "output_filtered.json"
    if File.exist?(result_file)
      h = JSON.parse(File.read(result_file))
      if h 
        if h['pathways']
          logger.debug("H_PATHWAYS:" + h['pathways'].size.to_s)
          h_res['nber_pathways'.intern]=h['pathways'].size
        end
        if h['displayed_error']
          h_res[:error]=h['displayed_error']
        end
      end
    end

#    logger.debug("PATHWAYS: " + (project_dir + "gene_enrichment" + self.id.to_s  + "output.json").to_s)

#    duration =  Time.now - start_time
#    h_res[:duration]=duration
#    h_res[:status_id]=3
#    logger.debug("H_RES: " + h_res.to_json)
#
    self.update_attributes(h_res)
#    project.update_attributes(:duration => duration, :status_id => 3)
#    project_step.update_attributes(:status_id => 3)
    Basic.finish_step(logger, start_time, project, 7, self, output_json, output_json)
    if project.gene_enrichments.select{|c| c.status_id == 3}.size > 0
      project_step.update_attributes(:status_id => 3)
    end

  end

end
