desc '####################### Update gene sets'
task update_gene_sets: :environment do
  puts 'Executing...'

  now = Time.now

    GeneSet.all.each do |gene_set|	
    
    h = {
      :nb_items => gene_set.gene_set_items.size
    }
    if h[:nb_items] > 0
      gene_set.update_attributes({:nb_items => h[:nb_items]})
    else
      puts "Delete gene_set!"
        gene_set.destroy
    end
  end
   
end
