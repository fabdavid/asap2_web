desc '####################### Update gene sets'
task update_gene_sets: :environment do
  puts 'Executing...'

  now = Time.now

  gene_set_dir = Pathname.new(APP_CONFIG[:data_dir]) + 'Genesets'
  
  Organism.all.each do |o|
    puts "=> #{o.name}..."
    
    DbSet.all.each do |db_set|	
      filename =  [db_set.tag + "_" + o.tax_id.to_s, 'gmt'].join(".")
      filepath = gene_set_dir + filename
      puts "searching for #{filepath}..."
      if File.exist? filepath        
        puts "Found #{filename}!"
        
        #user_id int references users,
        #project_id int references projects, -- this field allows to know if it is a global dataset or not          
        #organism_id int references organisms,
        #label text, -- db name if gene set global                      
        #original_filename text, -- can be null if imported from de         
        #ref_id int, -- cannot be null : =diff_expr_id if from DE or =db_set_id if from geneset database   
        #nb_items int default 3, -- number of lines in the file = number of sets   
        
        h = {
          :user_id => 1, 
          :project_id => nil,
          :organism_id => o.id,
          :ref_id => db_set.id
        }
        
        gene_set = GeneSet.where(h).first
        
        h[:nb_items]=`wc -l #{filepath}`
        h[:label]=db_set.label
        h[:original_filename] = filename
        
        if gene_set
          gene_set.update_attributes(h)
        else
          gene_set = GeneSet.new(h)
          gene_set.save
        end
     
      end
    end
  end
   
end
