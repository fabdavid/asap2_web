desc '####################### Update PanglaoDB'
task update_panglaodb: :environment do

  puts 'Executing...'

  dev_null = Logger.new("/dev/null")
  Rails.logger = dev_null
  ActiveRecord::Base.logger = dev_null
  
  now = Time.now

  label = "PanglaoDB"
  tag = "panglaodb"
  ## update db_sets
  db_set = DbSet.where(:label => label).first
  h_db_set = {
    :label => label, 
    :tag => tag
  }
  if !db_set
    db_set = DbSet.new(h_db_set)
    db_set.save
#  else
#    db_set.update_attributes(h_db_set)
  end
  
  tmp_dir = Pathname.new("./tmp/")
  data_dir = Pathname.new(APP_CONFIG[:data_dir])

  ## get organisms
  h_organisms = {}
  Organism.all.each do |o|
    h_organisms[o.id] = o
  end

  Organism.all.each do |o|
    
    filepath = data_dir + "panglaodb.#{o.tax_id}.tsv"
    if File.exists? filepath
      
      puts "Parse file for #{o.ensembl_db_name} #{filepath}..."  

      #get genes
      h_genes = {}
      o.genes.each do |g|
        h_genes[g.name] = g.id #{:id => g.id, :organism_id => g.organism_id}
        g.alt_names.split(",").map{|alt_name| h_genes[alt_name] = g.id}
      end
      
      File.open(filepath, 'r') do |f|
        header = f.gets
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
          puts "Create gene_set #{gene_set.to_json}."
        end
        ## delete existing gene_set_items
        # GeneSetItem.where(:gene_set_id => gene_set.id, ).delete_all
        existing_gsi = GeneSetItem.where(:gene_set_id => gene_set.id).count
        puts "Existing gsi: #{existing_gsi}"
        nber = {:minus => 0, :plus => 0, :equal => 0, :same => 0}
        while(l = f.gets) do
          t = l.chomp.split("\t")
         # identifier = a.shift.gsub(/^[a-z]+/, '')
          name = t[0]
          genes = t[1].split(",")
       #   url = a.shift
          gsi =  GeneSetItem.where(:gene_set_id => gene_set.id, :identifier => name).first         
          h_gsi = {
            :identifier => name,
            :name => name,
            :content => genes.map{|e| h_genes[e]}.compact.uniq.sort.join(","),
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
          if !gsi and h_gsi[:content] and h_gsi[:content] != '' and h_gsi[:name] != 'NA'
            puts "Create new gsi: #{h_gsi.to_json}"
            gsi = GeneSetItem.new(h_gsi)
            gsi.save
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
