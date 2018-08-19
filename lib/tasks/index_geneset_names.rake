desc '####################### Index geneset names'
task :index_geneset_names, [:gene_set_id] => [:environment] do |t, args|
  puts 'Executing...'

  now = Time.now
  
  list_gene_sets = (args and args[:gene_set_id]) ? [GeneSet.find(args[:gene_set_id])] : GeneSet.all

  list_gene_sets.each do |gene_set|
    puts "working on #{gene_set.label}..."

    filename = ''
    if gene_set.project_id ### specific project gene set
      project = gene_set.project
      dir = Pathname.new(APP_CONFIG[:user_data_dir]) + project.user_id.to_s + project.key + 'gene_sets'
      filename = dir + (gene_set.id.to_s + '.txt')
    else ### global gene set
      dir = Pathname.new(APP_CONFIG[:data_dir]) + "Genesets"
      filename = dir + gene_set.original_filename
    end
    
    ### get existing names
    
    h_existing_gene_set_names = {}
    gene_set.gene_set_names.each do |e|
      h_existing_gene_set_names[e.identifier]=e
    end

    ### parse names
    h_names = {}
    File.open(filename, 'r') do |f|
    
      i=1
      while (l = f.gets) do
        tab = l.chomp.split("\t")
        if tab.size > 2
          nb_items = tab.size - 3
          gene_set_name = nil
          if h_existing_gene_set_names[tab[0]]
            gene_set_name =  h_existing_gene_set_names[tab[0]]
            gene_set_name.update_attributes(:name => tab[1], :num => i, :nb_items => nb_items)
          else
            gene_set_name = GeneSetName.new(:identifier => tab[0], :name => tab[1], :num => i, :nb_items => nb_items)
            gene_set.gene_set_names << gene_set_name
          end
          h_names[gene_set_name.identifier]=1
          i+=1
        end
      end

    end

    ### delete existing gene names that are obsolete
    
    h_existing_gene_set_names.each_key do |identifier|    
      if !h_names[identifier]
        gene_set_name = GeneSetName.where(:gene_set_id => gene_set.id, :identifier => identifier).first
        gene_set_name.destroy
      end
    end
    
    #  GeneSetName.where(:gene_set_id => gene_set.id).all.each do |geneset|
    #    if p.session		 
    #      d = now - p.session.updated_at
    #      if d > 24 * 60 * 60 * 2
    #        puts "Deleting #{p.key}..."
    #        ProjectsController.new.delete_project(p)
    #      else
    #	puts "Keep project #{p.key}"
    #      end
    #    else
    #      puts "No session for #{p.key} => delete"
    #      ProjectsController.new.delete_project(p)  	   
    #    end
    
  end
  
end
