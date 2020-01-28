desc '####################### archive projects'
task update_drugbank_slow: :environment do
  puts 'Executing...'

  dev_null = Logger.new("/dev/null")
  Rails.logger = dev_null
  ActiveRecord::Base.logger = dev_null

  now = Time.now

  file = Pathname.new(APP_CONFIG[:data_dir]) + "drugbank" + "drugbank.xml"

  reader = Nokogiri::XML::Reader(File.open(file))
  h_drugs = {}
  h_drug_names = {}
  h_cur = {}


  h_organisms = {}

  Organism.order("created_at").all.each do |o|
    h_organisms[o.tax_id] = o
  end  

  flag = 0
  drug_level = 0
  reader.each do |node|
    
    drugbank_db_set = DbSet.where(:label =>'DrugBank').first
    #    puts drugbank_db_set.to_json
    #exit
    
    if node.name == 'drug' and  node.node_type == 1
      drug_level+=1
      #      h_drugs[h_cur[:tax_id]][h_cur[:name]] = h_cur[:gene_names]
      h_cur = {} if drug_level == 1
    elsif node.name == 'drug' and  node.node_type != 1 
      drug_level-=1
      #      if drug_level == 0
      #      puts h_drugs.to_json
      #             puts "close drug" 
      #        exit
      #      end   
    elsif node.name =='drugbank-id' and !h_cur[:drugbank_id] and node.attribute('primary') == 'true'
      #  puts node.inner_xml
      h_cur[:drugbank_id] = node.inner_xml
      #   puts h_cur[:drugbank_id]
    elsif node.name == 'name' and !h_cur[:name] and node.node_type == 1 and node.inner_xml
      h_cur[:name] = node.inner_xml
      #   puts h_cur[:name]
      h_drug_names[h_cur[:drugbank_id]] = h_cur[:name]
    elsif node.name == 'targets'
      #   puts node.node_type
    elsif node.name == 'target' and node.node_type == 1
      flag = 1
      #   puts "target open"
    elsif node.name == 'target' and node.node_type != 1
      flag = 0
      #   puts "target close"
    elsif node.name == 'polypeptide' and node.node_type == 1 and flag == 1
      h_cur[:tax_id] = nil      
    elsif node.name == 'organism' and node.node_type == 1 and flag ==1
      #     puts node.name
      tax_id = node.attribute('ncbi-taxonomy-id')
      if tax_id
        h_cur[:tax_id] = node.attribute('ncbi-taxonomy-id').to_i if node.attribute('ncbi-taxonomy-id')
        h_drugs[h_cur[:tax_id]]||={}
      else
        #       puts "bad"
      end
    elsif node.name == 'gene-name' and node.node_type == 1 and flag == 1
      h_cur[:gene_name] = node.inner_xml
    elsif node.name == 'polypeptide' and node.node_type != 1 and flag == 1
      #      puts node.node_type
      #  h_cur[:gene_names].push node.inner_xml
#            puts [h_cur[:tax_id], h_cur[:drugbank_id], h_cur[:gene_name]].to_json
      h_drugs[h_cur[:tax_id]][h_cur[:drugbank_id]]||=[]
      h_drugs[h_cur[:tax_id]][h_cur[:drugbank_id]].push h_cur[:gene_name] # h_cur[:gene_names]
    end
    
    #     h_drugs[h_cur[:tax_id]][h_cur[:name]] = h_cur[:gene_names]
  end

  puts h_drugs.keys.size.to_s + " organisms"

  base_url = 'http://www.drugbank.ca/drugs/'

  h_drugs.keys.select{|tax_id| @h_organisms[tax_id]}.each do |tax_id|
    puts "Generating file for organism #{tax_id}..."
    File.open("tmp/drugbank_#{tax_id}.gmt", "w") do |f|
      h_drugs[tax_id].each_key do |id|
        if id 
          #     puts "ID: " + id.to_json
          name = h_drug_names[id]
          url = base_url + id
          list = [id, name, url] + h_drugs[tax_id][id] 
          f.write(list.join("\t")+ "\n")
        end
      end
    end
    
    o = h_organisms[tax_id]
    
    #organism_id int references organisms,
    # --tool_id int references tools, -- external database when it is a global gene set                                                                           
   # label text, -- db name if gene set global                                                                                                      
    #original_filename text, -- can be null if imported from de                          
    #ref_id int, -- cannot be null : =diff_expr_id if from DE or =db_set_id if from geneset database   
    h_gene_set = {
      :organism_id => o.id,
      :label => 'DrugBank',
      :ref_id => drugbank_db_set.id
    }
    gene_set = GeneSet.where(h_gene_set).first
    if !gene_set
      gene_set = GeneSet.new(h_gene_set)
      gene_set.save
    end
    if gene_set
      ActiveRecord::Base.transaction do        
        puts h_drugs[tax_id].to_json
        h_drugs[tax_id].each_key do |id|
          h_gene_set_item = {
            :identifier => id,
            :name => h_drug_names[id],
            :gene_set_id => gene_set.id,
            :content => Gene.where(:organism_id => o.id, :symbol => h_drugs[tax_id][id]).all.map{|e| e.id}.join(",")
          }
          gene_set_item = GeneSetItem.where({:identifier => id, :gene_set_id => gene_set.id}).first
          if !gene_set_item
            gene_set_item = GeneSetItem.new(h_gene_set_item)
            puts "Add Geneset item #{h_gene_set_item.to_json}" 
#            gene_set_item.save
          else
             puts "Update Geneset item #{h_gene_set_item.to_json}"
#            gene_set_item.update_attributes(h_gene_set_item)
          end
        end
        
#        gene_set.update_attributes(:nber_items => h_drugs[tax_id].keys.size)
      end
    end
    
  end


  
  #  puts h_drugs.keys.size.to_s + " drugs found!"
  #  puts h_drugs.keys.first(10).map{|k| "#{k} : #{h_drugs[k]}"}.to_json
  
  #h_drugs.
  
end
