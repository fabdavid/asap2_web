# lib/tasks/db.rake
namespace :asap do

  desc "Create gene list"
  task :create_gene_list => :environment do

    gene_lists_dir = Pathname.new(APP_CONFIG[:data_dir]) + 'gene_lists'
    
    Organism.all.each do |o|
      
      h_cond={:organism_id => o.id}
      #    h_cond[:organism_id] = params[:organism_id] if params[:organism_id]
      
      genes = Gene.select("id, name, ensembl_id, alt_names").where(h_cond).all
      output = []
      genes.each do |e|
        output.push("#{e.ensembl_id} #{e.name}" + ((e.alt_names.size > 0) ? " [" + e.alt_names.split(",").join(", ") + "]" : ''))
      end
    
      File.open(gene_lists_dir + (o.id.to_s + '.json'), 'w') do |f|
        f.write(output.to_json)
      end
      
    end
  end

end
