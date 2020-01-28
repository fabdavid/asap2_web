desc '####################### Clean'
task update_genes_bkp: :environment do

  puts 'Executing...'

  dev_null = Logger.new("/dev/null")
  Rails.logger = dev_null
  ActiveRecord::Base.logger = dev_null
  
  now = Time.now
  
#  biomart = Biomart::Server.new("http://www.ensembl.org/biomart/martservice")

#  biomart.list_datasets.select{|e| e.match(/gene_ensembl/)}.each do |dataset_name|
#    puts "extract #{dataset_name}..."
#    dataset = biomart.datasets[dataset_name]
#    # puts dataset.list_attributes.to_json
#    if dataset.list_attributes.include? "entrezgene_id"
#      results = dataset.search(:attributes => ["ensembl_gene_id", "entrezgene_id"])
#      #   puts results.to_json
#      #   puts results.keys.to_json   
#      i = 0
#      results[:data].select{|e| e[1]}.each do |e|
#        #  puts e[0] + "->" + e[1] + "\n"
#        if g = Gene.where(:ensembl_id => e[0]).first
#          g.update_attributes({:ncbi_gene_id => e[1]})
#          i+=1
#        end
#      end   
#      puts "#{i} genes updated."
#    end		
#  end

  # get existing genes

  release_num = 95
  
  base_url = "ftp://ftp.ensembl.org/pub/current_mysql/"
  tmp_dir = Pathname.new("./tmp/")
  
  h_db_names = {}
  list_folders = `wget -O - #{base_url}`
  list_folders.split("\n").each do |l|
    puts l
    if m = l.match(/>(\w+)\/</)
      puts m[1]
      t = m[1].split("_")
      
      ensembl_db_name = (0 .. t.size-3).map{|i| t[i]}.join("_") 
      h_db_names[ensembl_db_name] = m[1]
    end
    #    puts l.chomp
  end

  puts h_db_names.to_json

  ensembl_tables = ['seq_region', 'gene', 'xref', 'object_xref', 'transcript', 'external_synonym', 'exon_transcript', 'exon', 'gene_archive', 'mapping_session']

  Organism.all.each do |o|
    puts "Extract #{o.name}..."
    folder_name = h_db_names[o.ensembl_db_name + "_core"] #o.ensembl_db_name + '_core_97_1'
    
    if folder_name

      ## delete files if still there
      ensembl_tables.each do |table_name|
        File.delete(tmp_dir + (table_name + ".txt")) if File.exist?(tmp_dir + (table_name + ".txt"))
      end
            
      ensembl_tables.each do |table_name|
        url = base_url + folder_name + "/" + table_name + ".txt.gz"
        
        `wget -qO #{tmp_dir}#{table_name}.txt.gz '#{url}'`
        `gunzip #{tmp_dir}#{table_name}.txt.gz`
        
      end
      
      if File.exist? "#{tmp_dir}xref.txt" and File.exist? "#{tmp_dir}object_xref.txt" and File.exist? "#{tmp_dir}gene.txt"

        h_xref = {}
        File.open("#{tmp_dir}xref.txt", "r") do |f|
          while l = f.gets
            t = l.chomp.split("\t")
            if [1100, 1300].include? t[1].to_i
              h_xref[t[0]] = {:acc => t[2], :type => t[1]}
            end
          end
        end
        
        h_object_xref = {}
        File.open("#{tmp_dir}object_xref.txt", "r") do |f|
          while l = f.gets
            t = l.chomp.split("\t")
            if h_xref[t[3]]
              h_object_xref[t[1]]||=[]
              h_object_xref[t[1]].push(t[3])
            end
          end
        end
        
        h_seq_region = {}
        File.open("#{tmp_dir}seq_region.txt", "r") do |f|
          while l = f.gets
            t = l.chomp.split("\t")
            h_seq_region[t[0]] = t[1]
          end
        end


        h_gene = {}
        File.open("#{tmp_dir}gene.txt", "r") do |f|
          while l = f.gets
            t = l.chomp.split("\t")
            h_gene[t[12]]={:id => t[0], :chr => h_seq_region[t[3]], :biotype => t[1]}
          end
        end
        
        h_transcripts = {}
        File.open("#{tmp_dir}transcript.txt", "r") do |f|
          while l = f.gets
            t = l.chomp.split("\t")
            h_transcripts[t[1]]||=[]
            h_transcripts[t[1]].push t[0]
          end
        end

        h_exons = {}
        File.open("#{tmp_dir}exon_transcript.txt", "r") do |f|
          while l = f.gets
            t = l.chomp.split("\t")
            h_exons[t[1]]||=[]
            h_exons[t[1]].push t[0]
          end
        end

        h_exon_details = {}
        File.open("#{tmp_dir}exon.txt", "r") do |f|
          while l = f.gets
            t = l.chomp.split("\t")
            h_exon_details[t[0]]||={}
            h_exon_details[t[0]] = {:start => t[2], :end => t[3]}
          end
        end

        h_gene_archives = {}
        File.open("#{tmp_dir}gene_archive.txt", "r") do |f|
          while l = f.gets
            t = l.chomp.split("\t")
            h_gene_archives[t[0]] = t[7]
          end
        end

        h_mapping_sessions = {}
        File.open("#{tmp_dir}mapping_session.txt", "r") do |f|
          while l = f.gets
            t = l.chomp.split("\t")
            h_mapping_sessions[t[0]] = t[4]
          end
        end


        
        h_external_synonym = {}
        
         File.open("#{tmp_dir}external_synonym.txt", "r") do |f|
          while l = f.gets
            t = l.chomp.split("\t")
            if h_xref[t[0]] and h_xref[t[0]][:type] == '1100'
              h_external_synonym[t[0]]||=[]
              h_external_synonym[t[0]].push t[1]
            end
          end
        end
        
        #   puts h_gene.to_json
        #      exit
        
        i = 0      
        j = 0
        h_db_genes = {}

        #        tmp_h = {
        #              :ensembl_id => stable_id,
        #              :biotype => h_gene[stable_id][:biotype],
        ##             :chr => h_gene[stable_id][:chr],
        #             :gene_length => h_gene[stable_id][:gene_length],
        #             :organism_id => o.id,
        #             :latest_ensembl_release => release_num
        #       }
        
        h_ensembl_id_by_gene_id = {}
        h_gene_id_by_ensembl_id = {}
        h_new_ensembl_ids = []
        Gene.where(:organism_id => o.id).all.each do |g| 
          h_ensembl_id_by_gene_id[g.id] = g.ensembl_id
          h_gene_id_by_ensembl_id[g.ensembl_id] = g.gene_id
          
          h_db_genes[g.ensembl_id] = {
#            :id => g.id,
            :ensembl_id => g.ensembl_id,
            :biotype => g.biotype,
            :chr => g.chr,
            :ncbi_gene_id => g.ncbi_gene_id,
            :gene_length => g.gene_length,
            :organism_id => g.organism_id,
            :latest_ensembl_release => g.latest_ensembl_release,
            :name => g.name,
            :sum_exon_length => g.sum_exon_length,
            :alt_names => g.alt_names
          }
        end
        
        h_gene.each_key do |stable_id|
          
          if ! h_db_genes[stable_id] #Gene.where(:ensembl_id => stable_id).first
            h_new_ensembl_ids.push stable_id
            h_db_genes[stable_id] = {
              :ensembl_id => stable_id,
              :biotype => h_gene[stable_id][:biotype],
              :chr => h_gene[stable_id][:chr],
              :gene_length => h_gene[stable_id][:gene_length],
              :organism_id => o.id,
              :latest_ensembl_release => h_mapping_session[h_gene_archives[stable_id]]
            }
          end
          
          h_upd = {}
          if h_transcripts[h_gene[stable_id][:id]]
            exons = []
            union_pos = []
            h_transcripts[h_gene[stable_id][:id]].each do |t_id|
              h_exons[t_id].each do |exon_id|
                if exon = h_exon_details[exon_id]
                  union_pos |= (exon[:start] .. exon[:end]).to_a
                end
              end
            end
            h_db_genes[stable_id][:sum_exon_length] = union_pos.size
          end
          if h_object_xref[h_gene[stable_id][:id]]
            j+=1
            alt_names = []
            h_object_xref[h_gene[stable_id][:id]].each do |xref_id|
              if h_xref[xref_id] 
                if h_xref[xref_id][:type] == '1300'
                  h_upd[:ncbi_gene_id] = h_xref[xref_id][:acc]
                  i+=1
                elsif h_xref[xref_id][:type] == '1100'
                  h_upd[:name] = h_xref[xref_id][:acc]
                  if h_external_synonym[xref_id]
                    h_external_synonym[xref_id].each do |syn|
                      alt_names.push syn
                    end
                  end
                end
              end
            end
            h_db_genes[stable_id][:alt_names] = alt_names.join(",")
          end
          
          #            if h_upd.keys.size > 0
          #              #    puts h_upd.to_json
          #              #              g.update_attributes(h_upd)
          #              tmp_gene = TmpGene.new h_upd
          #            end
          
          #   end
        end

        ## add existing

        print "Add existing...."
        existing_entries = 0
        h_db_genes.each_key do |stable_id|
          tmp_gene = TmpGene.new h_db_genes[stable_id]
          tmp_gene.save
          existing_entries+=1
        end
        puts "#{existing_entries} existing entries added."

        ## add new
        print "Add new entries...."
        new_entries = 0
        #        h_db_genes.each_key do |stable_id|
        #         if !h_gene_id_by_ensembl_id[stable_id]
        new_ensembl_ids.each do |stable_id|
          tmp_gene = TmpGene.new h_db_genes[stable_id]
          tmp_gene.save
          new_entries+=1
        end
        puts " #{new_entries} new entries added."
        
        puts "#{j} genes found"
        puts "#{i} genes have been updated!"
        
      else
        puts "Not found #{o.ensembl_db_name}_core"
      end
      
      ['gene', 'xref', 'object_xref'].each do |table_name|
        File.delete(tmp_dir + (table_name + ".txt")) #if File.exist?(tmp_dir + (table_name + ".txt"))
      end
      
    end

  end
end
