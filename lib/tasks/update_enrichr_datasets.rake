desc '####################### Update EnrichR datasets'
task update_enrichr_datasets: :environment do
  puts 'Executing...'

  now = Time.now
  
  h_datasets = {
  'Human Gene Atlas' => {:tag => 'human_gene_atlas', :url => 'https://amp.pharm.mssm.edu/Enrichr/geneSetLibrary?mode=text&libraryName=Human_Gene_Atlas', :tax_ids => [9606]},
  'Mouse Gene Atlas' => {:tag => 'mouse_gene_atlas', :url => 'https://amp.pharm.mssm.edu/Enrichr/geneSetLibrary?mode=text&libraryName=Mouse_Gene_Atlas', :tax_ids => [10090, 10091, 10092, 39442]}  
  }
  
  ## update db_sets
  h_datasets.each_key do |db_name|
    db_set = DbSet.where(:label => db_name).first
    h_db_set = {
      :label => db_name,
      :tag => h_datasets[db_name][:tag]
    }
    if !db_set
      db_set = DbSet.new(h_db_set)
      db_set.save
    else
      db_set.update_attributes(h_db_set)
    end
  end

  ##parse files

  h_datasets.each_key do |db_name|
    
    db_set = DbSet.where(:label => db_name).first

    url = h_datasets[db_name][:url]
    file = Pathname.new(APP_CONFIG[:data_dir]) + (h_datasets[db_name][:tag] + '.txt')
    `wget -O #{file} '#{url}'`

    Organism.where(:tax_id => h_datasets[db_name][:tax_ids]).each do |o|

      ## create gene set
      gene_set = GeneSet.where(:organism_id => o.id, :ref_id => db_set.id).first
        h_gene_set = {
          :organism_id => o.id,
          :label => db_name,
          :user_id => 1,
          :ref_id => db_set.id
        }

      if !gene_set
#         id | user_id | project_id | organism_id |            label            |          original_filename          |         created_at         |         updated_at         | nb_items | tool_id | ref_id
        gene_set = GeneSet.new(h_gene_set)
        gene_set.save
      else
      gene_set.update_attributes(h_gene_set)	
      end
      
      ## get genes
      h_genes_by_name = {}
      h_genes_by_alt_names = {}
      h_genes_by_obsolete_alt_names = {}
      Gene.where(:organism_id => o.id).all.each do |g|        
        h_genes_by_name[g.name.downcase] = g.id if g.name
        if g.alt_names
          g.alt_names.downcase.split(",").each do |gn|
            h_genes_by_alt_names[gn] ||= []
            h_genes_by_alt_names[gn].push g.id
          end
        end
	if g.obsolete_alt_names	
          g.obsolete_alt_names.downcase.split(",").each do |gn|
            h_genes_by_obsolete_alt_names[gn] ||= []
            h_genes_by_obsolete_alt_names[gn].push g.id
          end
        end
      end

      File.open(file, 'r') do |f|
        while (l = f.gets) do
        
          l.chomp!
	#  puts l
          t = l.split(/\t+/)
          name = t[0]
          name_first_word = t[0].split(/\s+/)[0]
#          t2 = t.split(/\s+/)
        #  puts name
	#  puts t.size
          list_gene_names = (1 .. t.size-1).map{|i| a = t[i].split(",")[0];  a.downcase}
        #  puts "#{name} : #{list_gene_names.join(",")}" 
          list_genes = []
          list_gene_names.each do |gene_name|
            tmp_gene_id = h_genes_by_name[gene_name]
            if !tmp_gene_id
              tmp_gene_id = h_genes_by_alt_names[gene_name][0] if h_genes_by_alt_names[gene_name] and h_genes_by_alt_names[gene_name].size == 1 
              if !tmp_gene_id
                 tmp_gene_id = h_genes_by_obsolete_alt_names[gene_name][0] if h_genes_by_obsolete_alt_names[gene_name] and h_genes_by_obsolete_alt_names[gene_name].size == 1 
              end
            end
            list_genes.push tmp_gene_id
          end
          
          ## add gene set item
          gene_set_item = GeneSetItem.where(:identifier => name, :gene_set_id => gene_set.id).first
          h_gene_set_item = {
            :identifier => name, 
            :name => name,
            :gene_set_id => gene_set.id,
            :content => list_genes.compact.join(",")
          }
          if !gene_set_item
            gene_set_item = GeneSetItem.new(h_gene_set_item)
            gene_set_item.save
          else
            gene_set_item.update_attributes(h_gene_set_item)
          end
        end
        
      end
    end
    
  end

end
