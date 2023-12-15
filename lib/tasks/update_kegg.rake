desc '####################### Update KEGG'
task update_kegg: :environment do

  puts 'Executing...'

  dev_null = Logger.new("/dev/null")
  Rails.logger = dev_null
  ActiveRecord::Base.logger = dev_null
  
  now = Time.now

  label = "KEGG pathways"

  ## update db_sets
#  db_set = DbSet.where(:label => label).first
#  h_db_set = {
#    :label => label, 
#    :tag => h_db_to_load[db_id][:tag]
#  }
#  if !db_set
#    db_set = DbSet.new(h_db_set)
#    db_set.save
#  else
#    db_set.update_attributes(h_db_set)
#  end
  
  tmp_dir = Pathname.new("./tmp/")
  data_dir = Pathname.new(APP_CONFIG[:data_dir])
  kegg_dir = data_dir + 'kegg'
  ## get organisms
  h_organisms = {}
  Organism.all.each do |o|
    h_organisms[o.id] = o
  end

  ## get db_sets
  #h_db_sets = {}
  #DbSet.all.each do |d|
  #  h_db_sets[d.label] = d
  #end
  db_set = DbSet.where(:label => label).first
  ## get GO lineages
  go_file = data_dir + 'go' + "go.json"
  h_go = JSON.parse(File.read(go_file))

  ## get organisms by tax_id 
  #h_organisms_by_taxid = {}
  #Organism.all.map{|o| h_organisms_by_taxid[o.tax_id] = o}

  #run ASAP.jar KEGG command

#  cmd = "java -jar lib/ASAP.jar -T CreateKeggDB -o #{kegg_dir}"
#  `#{cmd}`

  #  Organism.all.select{|o| o.id == 35}.each do |o|
  Organism.all.select{|o| o.tax_id == 9823}.each do |o|
    
    filepath = kegg_dir + "kegg.#{o.tax_id}.gmt"
    if File.exists? filepath
      
      puts "Parse file for #{o.ensembl_db_name} kegg.#{o.tax_id}.gmt..."  

      #get genes
      h_genes = {}
      o.genes.each do |g|
        h_genes[g.ncbi_gene_id] = g.id #{:id => g.id, :organism_id => g.organism_id}
      end
      
      File.open(filepath, 'r') do |f|
        gene_set = GeneSet.where(:organism_id => o.id, :label => label).first
        h_gene_set = {
          :user_id => 1,
          :organism_id => o.id,
          :label => label,
          :ref_id => db_set.id, #h_db_sets[label].id,
          :asap_data_id => APP_CONFIG[:asap_data_id]
        }
	if !gene_set
          gene_set = GeneSet.new(h_gene_set)
          gene_set.save
        end
        ## delete existing gene_set_items
        # GeneSetItem.where(:gene_set_id => gene_set.id, ).delete_all
        existing_gsi = GeneSetItem.where(:gene_set_id => gene_set.id).count
        puts "Existing gsi: #{existing_gsi}"
        nber = {:minus => 0, :plus => 0, :equal => 0, :same => 0}
        while(l = f.gets) do
          a = l.chomp.split("\t")
          identifier = a.shift.gsub(/^[a-z]+/, '')
          name = a.shift
          url = a.shift
          gsi =  GeneSetItem.where(:gene_set_id => gene_set.id, :identifier => identifier).first         
          h_gsi = {
            :identifier => identifier,
            :name => name,
            :content => a.map{|e| h_genes[e.to_i]}.compact.sort.join(","),
            :gene_set_id => gene_set.id,
            :asap_data_id => APP_CONFIG[:asap_data_id]
          }
#                    puts "New: " + h_gsi.to_json
#                    puts "Old: " + gsi.to_json

       
          if gsi and a.map{|e| h_genes[e.to_i]}.compact.size < gsi.content.split(",").size
#            puts "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!less entries!"
            puts "New: " + h_gsi.to_json                                                                                                                 
            puts "Old: " + gsi.content.split(',').map{|e| e.to_i}.sort.to_json    
            nber[:minus]+=1
          elsif  gsi and a.map{|e| h_genes[e.to_i]}.compact.size == gsi.content.split(",").size
            if a.map{|e| h_genes[e.to_i]}.compact.sort == gsi.content.split(",").map{|e| e.to_i}.sort
              nber[:same]+=1
            else	
#	      puts "New: " + h_gsi.to_json
#              puts "Old: " + gsi.content.split(',').map{|e| e.to_i}.sort.to_json
            end
            nber[:equal]+=1	   
          elsif 
            nber[:plus]+=1
          end
          if !gsi
 #           gsi = GeneSetItem.new
 #           gsi.save
          else
#            gsi.update_attributes(h_gsi)
          end
        end
        puts nber.to_json
        
      end
      
    else
#      puts "File #{filepath} doesn't exist!"
    end
  end

  
end
