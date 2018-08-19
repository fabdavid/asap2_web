desc '####################### Update gene sets'
task update_genes: :environment do
  puts 'Executing...'

  now = Time.now

  genes_dir = Pathname.new(APP_CONFIG[:data_dir]) + 'genes'
  
  Organism.all.each do |o|
    puts "=> #{o.name}..."
    
    filename = o.name.downcase.gsub(" ", "_") + ".txt"

    #Ensembl Name    AltNames        Biotype GeneLength      SumExonLength   Chr
        
    if File.exist? genes_dir + filename
      
      File.open(genes_dir + filename, 'r') do |f|
        
        header = f.gets
        
        while (l = f.gets) do 
          l.chomp!
          t = l.split("\t")
          list_names = [t[1]]
          list_names.push t[2].split(",")
          
#          gene_name = t[1]
          h = {
            :organism_id => o.id,
            :ensembl_id => t[0],
#            :name => gene_name
          }
          
          gene = Gene.where(h).first
          if !gene
            h[:name] = t[1]
            h[:biotype] = t[3]
            h[:gene_length] = t[4]
            h[:sum_exon_length] = t[5]
	    h[:alt_names] = t[2]
            h[:chr] = t[6]
            gene = Gene.new(h)
            gene.save!
          else
            gene.update_attributes(:name => t[1], :biotype => t[3], :gene_length => t[4], :sum_exon_length => t[5], :chr => t[6], :alt_names => t[2])
          end
          
          
          names = [list_names, t[1], t[0]].flatten.uniq
          

          names.each do |gn|
            gene_name = GeneName.new({:value => gn, :organism_id => o.id})
            gene.gene_names << gene_name if !gene.gene_names.include?(gene_name)            
          end
          

#          gene_name = GeneName.new({:value => t[1], :organism_id => o.id})
#          gene.gene_names << gene_name if !gene.gene_names.include?(gene_name)
#          ensembl_id = GeneName.new({:value => t[0], :organism_id => o.id})
#          gene.gene_names << ensembl_id if !gene.gene_names.include?(ensembl_id)
          
          #        puts t.to_json
          #        exit
        end
      end
      
    end
  
  end
   
end
