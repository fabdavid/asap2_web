desc '####################### extract ids from ontologies'
task extract_ids_from_ontologies: :environment do
  puts 'Executing...'

  now = Time.now

  data_dir = Pathname.new(APP_CONFIG[:data_dir])
  ontology_dir = data_dir + 'ontologies'
  latest_asap_data_version = 5

  def add_lineage tmp, cur_id, h_parents
    if tmp and cur_id and h_parents and h_parents[cur_id] and h_parents[cur_id].size > 0
      h_parents[cur_id].each do |k|
  #    puts "add #{k} -> #{tmp.to_json}..."
        if !tmp.include? k
          tmp.push k 
          tmp = add_lineage(tmp, k, h_parents)
        end
      end
    end
    return tmp
  end

  ## get all terms by id
  h_co = {}
  CellOntology.all.map{|co| h_co[co.id] = co}
  h_terms = {}
  h_terms2 = {}
  h_parents_by_id = {}
  CellOntologyTerm.all.to_a.select{|cot| co = h_co[cot.cell_ontology_id]; cot.identifier and cot.identifier.match(/^#{co.tag}/)}.each do |cot|
    h_terms[cot.identifier] = cot
    h_terms2[cot.id] = cot
  end

#puts h_terms['CL:0002238'].to_json
#exit
  h_children = {}
  
  CellOntology.all.each do |co|
    
    puts "=> Treating #{co.name}"
      
    ## get genes
    puts " - get genes..."
    h_genes = {}
    organism_ids =  co.organisms.map{|o| o.id}
    ConnectionSwitch.with_db(:data_with_version, latest_asap_data_version) do
      Gene.where(:organism_id => organism_ids).all.each do |g|
        h_genes[g.ensembl_id] = g
      end
    end
    
    cots = co.cell_ontology_terms
 #   h_parents= {}

    if cots
      puts " - update parents and related gene and term ids..."

      ## get all terms     
    #  h_terms = {}
    #  h_terms2 = {}
    #  h_parents_by_id = {}
    #  co.cell_ontology_terms.select{|cot| cot.identifier.match(/^#{co.tag}/) }.each do |cot|
    #    h_terms[cot.identifier] = cot
    #	h_terms2[cot.id] = cot
    #  end
      ## number of terms 
    #  puts "Number of terms: " + h_terms.keys.size

      ## extraction
      co.cell_ontology_terms.each do |cot|
        
        h_related = {:genes => [], :terms => []}
        
        h_cot = Basic.safe_parse_json(cot.content_json, {})
     #    h_parents_by_id[cot.id] = h_cot
        tmp_list = []				
#        tmp_parents = []
        h_cot.each_key do |k|
#          tmp_list = []
          if h_cot[k].is_a? Array
            tmp_list += h_cot[k]
         #   tmp_parents.push 
          elsif h_cot[k].is_a? Hash
            h_cot[k].each_key do |k2|
              if h_cot[k][k2]
                tmp_list += h_cot[k][k2]
              end
            end
          end
        end
        tmp_list.uniq!
	h_parents_by_id[cot.id] =(h_cot["is_a"]) ? h_cot["is_a"].map{|e| (h_terms[e]) ? h_terms[e].id : nil}.compact : []
        h_parents_by_id[cot.id] |=(h_cot["relationship"] and  h_cot["relationship"]["part_of"]) ? h_cot["relationship"]["part_of"].map{|e| (h_terms[e]) ? h_terms[e].id : nil}.compact : []

        if h_cot["is_a"]
          h_cot["is_a"].select{|e| h_terms[e] and h_terms[cot.identifier]}.map{|e| h_children[h_terms[e].id] ||= []; h_children[h_terms[e].id].push h_terms[cot.identifier].id}
        end
        if h_cot["relationship"] and  h_cot["relationship"]["part_of"]
          h_cot["relationship"]["part_of"].select{|e| h_terms[e] and h_terms[cot.identifier]}.map{|e| h_children[h_terms[e].id] ||= []; h_children[h_terms[e].id].push h_terms[cot.identifier].id}
        end
#        h_parents_by_id[cot.id].map{|e| h_children}
        h_upd = {
          :node_gene_ids => tmp_list.map{|e| (h_genes[e]) ? h_genes[e].id : nil}.compact.join(","),          
          :node_term_ids => tmp_list.map{|e| (h_terms[e]) ? h_terms[e].id : nil}.compact.join(","),
          :parent_term_ids => h_parents_by_id[cot.id].join(",") #(h_cot["is_a"]) ? h_cot["is_a"].map{|e| (h_terms[e]) ? h_terms[e].id : nil}.compact.join(",") : ''
        }
        #        h_parents_by_id[cot.id] = h_upd[:parent_term_ids]
        #        h_parents[cot.id] = h_upd[:parent_term_ids]
        puts h_upd.to_json	
        cot.update_attributes(h_upd)
        
      end
      
      #add lineages
      puts " - compute lineages..."
      related_gene_ids = {}
      h_parents_by_id.each_key do |k|
        lineage = add_lineage([], k, h_parents_by_id)
        lineage.each do |e|
       #   h_children[e] ||= []
       #   h_children[e].push k if !h_children[e].include? k
          related_gene_ids[e]||=[]
	  if h_terms2[e]
            #	   h_terms2[e].node_gene_ids.split(',').map{|e2| e2.to_i}.each do |gene_id|
            if h_terms2[e].node_gene_ids
              related_gene_ids[e] += h_terms2[e].node_gene_ids.split(',').map{|e2| e2.to_i} 
            end
          end
        end

        h_upd = {
          :lineage => lineage.join(",")
        }

        h_terms2[k].update_attributes(h_upd) if h_terms2[k]
      
      end

      #compute related gene ids
      
       related_gene_ids.each_key do |k|

        h_upd = {
          :related_gene_ids => related_gene_ids[k].uniq.join(",")
        }

	puts "-#{k}-"
        h_terms2[k].update_attributes(h_upd)

      end


    end


  end
  
  h_children.each_key do |e|
    h_terms2[e].update_attributes(:children_term_ids =>  (h_children[e]) ? h_children[e].join(",") : '')
  end

  
end
