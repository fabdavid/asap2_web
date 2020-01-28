desc '####################### Clean'
task update_xrefs: :environment do

  puts 'Executing...'

  dev_null = Logger.new("/dev/null")
  Rails.logger = dev_null
  ActiveRecord::Base.logger = dev_null
  
  now = Time.now

#  kegg_version = '6.3.5.5'

  h_db_to_load = {
    '1300' => {:name => 'NCBI Gene ID'},
    '1000' => {:name => 'GO'},
    '50801' => {:name => 'KEGG pathways'},
    '20062' => {:name => 'DrugBank'},
    '20088' => {:name => 'Reactome'}
  }

#  list_db_xrefs = ['1000', '50801', '20062', '20088']

  list_db_xrefs_direct = ['50801', '20062', '20088'] ## the ones that are integrated straight away
  list_db_xrefs = ["1000"] + list_db_xrefs_direct

  ## update db_sets
  list_db_xrefs_direct.each do |db_id|
    label = h_db_to_load[db_id][:name]
    db_set = DbSet.where(:label => label).first
    h_db_set = {
      :label => label, 
      :tag => h_db_to_load[db_id][:tag]
    }
    if !db_set
      db_set = DbSet.new(h_db_set)
      db_set.save
    else
      db_set.update_attributes(h_db_set)
    end
  end
  
  base_url = "ftp://ftp.ensembl.org/pub/current_mysql/"
  tmp_dir = Pathname.new("./tmp/")

  ## get organisms
  h_organisms = {}
  Organism.all.each do |o|
    h_organisms[o.id] = o
  end

  ## get db_sets
  h_db_sets = {}
  DbSet.all.each do |d|
    h_db_sets[d.label] = d
  end

  ## get GO lineages
  go_file = "#{APP_CONFIG[:data_dir]}/go.json"
  h_go = JSON.parse(File.read(go_file))

  ## get db names
  h_db_names = {}
  list_folders = `wget -O - #{base_url}`
  list_folders.split("\n").each do |l|
  #  puts l
    if m = l.match(/>(\w+)\/</)
   #   puts m[1]
      t = m[1].split("_")
      
      ensembl_db_name = (0 .. t.size-3).map{|i| t[i]}.join("_") 
      h_db_names[ensembl_db_name] = m[1]
    end
    #    puts l.chomp
  end

  #puts h_db_names.to_json
  
  ensembl_tables = ['transcript', 'translation', 'gene', 'xref', 'object_xref']

#  Organism.all.select{|o| o.id == 35}.each do |o|
  Organism.all.each do |o|
    puts "Extract #{o.name}..."  

    ## delete files if still there
    ensembl_tables.each do |table_name|
      File.delete(tmp_dir + (table_name + ".txt")) if File.exist?(tmp_dir + (table_name + ".txt"))
    end
  
    ###load genes
    puts "Load genes from DB..."
    h_genes = {}

    o.genes.each do |g|
      h_genes[g.ensembl_id] = {:id => g.id, :organism_id => g.organism_id}
    end
    
    folder_name = h_db_names[o.ensembl_db_name + "_core"] #o.ensembl_db_name + '_core_97_1'
    
    if folder_name

      puts "Download files from Ensembl..."
      ensembl_tables.each do |table_name|
        url = base_url + folder_name + "/" + table_name + ".txt.gz"        
        cmd = "wget -qO #{tmp_dir}#{table_name}.txt.gz '#{url}'"
        `#{cmd}`
#	puts cmd  
  
        `gunzip #{tmp_dir}#{table_name}.txt.gz`        
      end
      
      puts "Load data from Ensembl..."
      if File.exist? "#{tmp_dir}xref.txt" and File.exist? "#{tmp_dir}object_xref.txt" and File.exist? "#{tmp_dir}gene.txt"

        h_transcript = {}
        if File.exist? "#{tmp_dir}transcript.txt"
          File.open("#{tmp_dir}transcript.txt", "r") do |f|
            while l = f.gets
              t = l.chomp.split("\t")
              h_transcript[t[0]] = t[1]                
            end
          end
        end
        
        h_translation = {}
        if File.exist? "#{tmp_dir}translation.txt"
          File.open("#{tmp_dir}translation.txt", "r") do |f|
            while l = f.gets
              t = l.chomp.split("\t")
              h_translation[t[0]] = t[1]
            end
          end
        end
        
        h_xref = {}
        h_xref_names = {}
        File.open("#{tmp_dir}xref.txt", "r") do |f|
          while l = f.gets
            t = l.chomp.split("\t")
            if h_db_to_load.keys.include? t[1]	  
              splitted_identifier = t[2].split("+")
              xref_acc = (t[1] == '50801') ? ((o.tag || '') + splitted_identifier[0]) : t[2]
#              puts t[1] + ":" + xref_acc
#	      if t[1] == '50801'
#               exit
#	      end                   
              h_xref[t[0]] = {:acc => xref_acc, :type => t[1], :name => t[5]}
	      h_xref_names[t[1]]||={}
              h_xref_names[t[1]][xref_acc] = t[5]
            end
          end
        end
        
        h_object_xref = {}
        h_db_to_load.each_key do |k|
          h_object_xref[k]={}
        end
#	puts h_object_xref.to_json

        File.open("#{tmp_dir}object_xref.txt", "r") do |f|
          while l = f.gets
            t = l.chomp.split("\t")
            if h_xref[t[3]]
              type = h_xref[t[3]][:type]
	      if !h_object_xref[type]
           #     puts type 
                exit
              end	      
#	      if t[1] == '458384'
#                puts [t[1], t[3], type].to_json
#              end
              gene_ref = t[1]
              if t[2] == 'Transcript'
                gene_ref = h_transcript[t[1]]
	#	puts gene_ref
              elsif t[2] == 'Translation'
             #   gene_ref = h_translation[h_transcript[t[1]]]
                gene_ref = h_transcript[h_translation[t[1]]]
#		puts gene_ref
              end
              h_object_xref[type][gene_ref]||=[]
              h_object_xref[type][gene_ref].push(t[3]) if ! h_object_xref[type][gene_ref].include? t[3]
            end
          end
        end
        
        h_gene = {}
        File.open("#{tmp_dir}gene.txt", "r") do |f|
          while l = f.gets
            t = l.chomp.split("\t")
            h_gene[t[12]]=t[0]
          end
        end

#        h_gene = {}
#        File.open("#{tmp_dir}external_synonym.txt", "r") do |f|
#          while l = f.gets
#            t = l.chomp.split("\t")
#            h_gene[t[1]]=t[0]
#          end
#        end

        
        #   puts h_gene.to_json
        #      exit
        
        ### update ncbi genes
        puts "Update NCBI genes..."
        i = 0      
        j = 0
        h_gene.each_key do |stable_id|
          if g = Gene.where(:ensembl_id => stable_id).first
            if ox = h_object_xref['1300'][h_gene[stable_id]]
              j+=1
              ox.each do |xref_id|
                if a = h_xref[xref_id] 
                  #   if h_db_to_load[a[:type]][:name] == 'NCBI Gene ID'
                  g.update_attributes({:ncbi_gene_id => a[:acc]})
                  i+=1
                end
                # end
              end
            end
          end
        end
        
#	puts  h_gene.to_json
#	puts h_object_xref['1000']['458384']
#exit
        ## create gene_set_items
        puts "Create gene sets..."
        h_gsi = {}

        #initialize
        list_db_xrefs.each do |type|
           h_gsi[type] ||={}
        end
        h_gene.each_key do |stable_id|
          g = h_genes[stable_id]
#	  puts "-> " + stable_id.to_s
          list_db_xrefs.each do |type|
 #           puts "Type :" + type
            if ox = h_object_xref[type][h_gene[stable_id]]
  #            puts "toto"
              ox.each do |xref_id|
                if a = h_xref[xref_id]
                #  h_gsi[type][o.id] ||={}
                  h_gsi[type][a[:acc]] ||= []
                  h_gsi[type][a[:acc]].push(stable_id)
          #        puts "Add #{stable_id} to #{a[:acc]}."
                end
              end
            end
          end
        end
   
        ### stats
        #        h_gsi.each_key do |k|
        #          puts "#{k} : #{h_gsi[k].keys.size} gene set items to update"
        #        end
        
        ### load GO
        puts "Apply lineages for GO annotations..."
        go_type = '1000'
        #        h_gsi[go_type].each_key do |organism_id|

        ## add lineage nodes
        list_go_ids = h_gsi[go_type].keys
        list_go_ids.each do |go_id|
          if !h_go[go_id]
         #   puts "1: " + go_id + " : " + h_go[go_id].to_json
            #            exit
          else 
            if !h_go[go_id]["lineage"]
          #    puts "2: " + go_id + " : " + h_go[go_id].to_json
              #              exit
            else
              
              h_go[go_id]["lineage"].each do |lineage_go_id|
                h_gsi[go_type][lineage_go_id]||=[]
                h_gsi[go_type][lineage_go_id] |= h_gsi[go_type][go_id]
              end
            end
          end
        end
   
        ### stats
        puts "Stats:"
        h_gsi.each_key do |k|
          puts "#{k} : #{h_gsi[k].keys.size} gene set items to update"
        end

        ActiveRecord::Base.transaction do
          puts "Save new GO in DB..."
          
          h_gsi[go_type].each_key do |go_id|
            #   a = h_xref[xref_id]                                                                                                                                                                                                         
            if h_go[go_id]
              db_name = h_go[go_id]["db_name"]
              h_gene_set = {:organism_id => o.id, :label => db_name, :ref_id => h_db_sets[db_name].id}
              gene_set = GeneSet.where(h_gene_set).first
              if !gene_set
                gene_set = GeneSet.new(h_gene_set)
                gene_set.save
              end
            end
          end
        end
        
	 ActiveRecord::Base.transaction do
          puts "Load GO in DB..."
          
          h_gsi[go_type].each_key do |go_id|
            #   a = h_xref[xref_id]
            if h_go[go_id] 
              db_name = h_go[go_id]["db_name"]
              h_gene_set = {:organism_id => o.id, :label => db_name, :ref_id => h_db_sets[db_name].id}
              gene_set = GeneSet.where(h_gene_set).first
              if gene_set
                #          #   puts	"Not found gene set for organism  #{o.name}, #{db_name}!"
                #          gene_set = GeneSet.new(h_gene_set)
                #          gene_set.save
                #      else
                gene_set.update_attributes(h_gene_set)
              end
              if gene_set and gene_set.id
                h_gene_set_item = {
                  :gene_set_id => gene_set.id, 
                  :identifier => go_id, 
                  :name => h_xref_names[go_type][go_id]
                }
                gene_set_item = GeneSetItem.where(h_gene_set_item).first
                ensembl_ids = h_gsi[go_type][go_id]
                #  h_go[go_id]["lineage"].each do |lineage_go_id|
                #    ensembl_ids |= h_gsi[go_type][go_id]
                #  end
                h_gene_set_item[:content]= ensembl_ids.select{|ensembl_id| h_genes[ensembl_id]}.map{|ensembl_id| h_genes[ensembl_id][:id]}.uniq.join(",")
                
                if !gene_set_item
                  gene_set_item = GeneSetItem.new(h_gene_set_item)
                  #   puts "Add gene_set_item: " + gene_set_item.to_json
                  gene_set_item.save
                else
                  gene_set_item.update_attributes(h_gene_set_item)
                end
              else
                puts "Gene set for #{h_gene_set.to_json} is not found!"
              end
            end
          end
        end

        ActiveRecord::Base.transaction do
           list_db_xrefs_direct.each do |type|
	     puts "Save new #{type} in DB..."            
            db_name = h_db_to_load[type][:name]
            h_gene_set = {:user_id => 1, :organism_id => o.id, :label => db_name, :ref_id => h_db_sets[db_name].id}
            gene_set = GeneSet.where(h_gene_set).first
            if !gene_set
              #   puts  "Not found gene set for organism  #{o.name}, #{db_name}!"                                                                                                                                                           
              gene_set = GeneSet.new(h_gene_set)
              gene_set.save
            end
          end
        end
        
        ActiveRecord::Base.transaction do
          
          list_db_xrefs_direct.each do |type|
	    puts "Load #{type} in DB..."            
            db_name = h_db_to_load[type][:name]
            h_gene_set = {:user_id => 1, :organism_id => o.id, :label => db_name, :ref_id => h_db_sets[db_name].id}
            gene_set = GeneSet.where(h_gene_set).first
            if gene_set
              #   #   puts  "Not found gene set for organism  #{o.name}, #{db_name}!"                         
              #   gene_set = GeneSet.new(h_gene_set)
              #   gene_set.save
              # else
              gene_set.update_attributes(h_gene_set)
            end
            
            if gene_set and gene_set.id
              
              h_gsi[type].each_key do |gsi_id|
                identifier = gsi_id
                #                identifier_splitted = identifier.split("+")
                #     if type != '50801' or identifier_splitted[1] == kegg_version
                #                if type == '50801'
                #                  identifier = (o.tag || '') + identifier_splitted[0] #gsi_id.gsub(/(\+.+?)$/, '')
                #                end
                h_gene_set_item = {
                  :gene_set_id => gene_set.id,
                  :identifier => identifier,
                  :name => h_xref_names[type][gsi_id]
                }
                gene_set_item = GeneSetItem.where(h_gene_set_item).first
                ensembl_ids = h_gsi[type][gsi_id]
                
                h_gene_set_item[:content]= ensembl_ids.select{|ensembl_id| h_genes[ensembl_id]}.map{|ensembl_id| h_genes[ensembl_id][:id]}.uniq.join(",")
                
                if !gene_set_item
                  gene_set_item = GeneSetItem.new(h_gene_set_item)
                  #   puts "Add gene_set_item: " + gene_set_item.to_json                                       
                  gene_set_item.save
                  else
                  gene_set_item.update_attributes(h_gene_set_item)
                  # puts "Update: " + h_gene_set_item.to_json	
                end
              end
           #   end
            else
              puts "Gene set for #{h_gene_set.to_json} not found!"
            end
          end
          # end
        end
        puts "#{j} genes found"
        puts "#{i} genes have been updated!"
        
      else
        puts "Not found #{o.ensembl_db_name}_core"
      end
      
      ensembl_tables.each do |table_name|
#        File.delete(tmp_dir + (table_name + ".txt")) if File.exist?(tmp_dir + (table_name + ".txt"))
      end
      
    end

  end
end
