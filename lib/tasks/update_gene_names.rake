desc '####################### Update gene names'
task update_gene_names: :environment do

  puts 'Executing...'

  start = Time.now

  dev_null = Logger.new("/dev/null")
  Rails.logger = dev_null
  ActiveRecord::Base.logger = dev_null

  Organism.order(:id).all.each do |o|
    puts "#{o.id} : #{o.name}..."
    h_gene_names = {}
    GeneName.where(:organism_id => o.id).all.each do |gn|
    h_gene_names[gn.gene_id]||={}  
      h_gene_names[gn.gene_id][gn.value] = 1
    end
    
    ActiveRecord::Base.transaction do

      o.genes.each do |g|
        gene_names = [g.name] 
	gene_names += g.alt_names.split(",") if g.alt_names
	gene_names += g.obsolete_alt_names.split(",") if g.obsolete_alt_names
        
        gene_names.each do |gene_name|

          if !h_gene_names[g.id] or !h_gene_names[g.id][gene_name]
            h_gene_name = {
              :organism_id => o.id,
              :gene_id => g.id,
              :value => gene_name
            }
            
            gene_name = GeneName.new(h_gene_name)
            gene_name.save
	     h_gene_names[g.id]||={}
            h_gene_names[g.id][gene_name]=1
          end
        end
        
      end
      
    end
  end

  
end
