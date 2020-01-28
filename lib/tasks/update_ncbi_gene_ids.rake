desc '####################### Clean'
task update_ncbi_gene_ids: :environment do

  puts 'Executing...'

  require 'biomart'

  now = Time.now
  
#  biomart = Biomart::Server.new( "http://www.biomart.org/biomart" )
  biomart = Biomart::Server.new("http://www.ensembl.org/biomart/martservice")
# List all of the available datasets on this Biomart server
# (be patient - this will take a while on this server as there's 
# a lot there...)


#puts biomart.list_datasets.select{|d| d.match(/mmus/)}.to_json

#  Organism.each do |o|
#  dbname = o.ensembl_db_name.split("_")
#end
 
  biomart.list_datasets.select{|e| e.match(/gene_ensembl/)}.each do |dataset_name|
    puts "extract #{dataset_name}..."
    dataset = biomart.datasets[dataset_name]
    # puts dataset.list_attributes.to_json
    if dataset.list_attributes.include? "entrezgene_id"
      results = dataset.search(:attributes => ["ensembl_gene_id", "entrezgene_id"])
      #   puts results.to_json
      #   puts results.keys.to_json   
      i = 0
      results[:data].select{|e| e[1]}.each do |e|
        #  puts e[0] + "->" + e[1] + "\n"
        if g = Gene.where(:ensembl_id => e[0]).first
          g.update_attributes({:ncbi_gene_id => e[1]})
          i+=1
        end
      end   
      puts "#{i} genes updated."
    end		
  end
  
end
